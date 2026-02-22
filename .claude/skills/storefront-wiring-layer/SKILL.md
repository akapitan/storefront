---
name: storefront-wiring-layer
description: Use when creating or modifying application services, controllers, DTOs, jOOQ repository implementations, or JTE templates. Handles the infrastructure, application, and interfaces layers of the hexagonal architecture.
argument-hint: "[module-name or component-name]"
---

# Wiring Layer — Infrastructure + Application + Interfaces

Creates the non-domain layers that wire everything together.

## Layer Dependency Rule

```
interfaces → application → domain ← infrastructure
```

- `interfaces/` calls `application/` (never domain directly)
- `application/` calls `domain/` repository interfaces
- `infrastructure/` implements `domain/` repository interfaces
- Domain NEVER imports from any other layer

## Infrastructure: jOOQ Repository Implementation

```java
// Location: com.storefront.<module>.infrastructure
// Visibility: package-private
// Annotation: @Repository
@Repository
class JooqOrderRepository implements OrderRepository {

    private final DSLContext primaryDsl;
    private final DSLContext readOnlyDsl;

    JooqOrderRepository(
            DSLContext primaryDsl,
            @Qualifier("readOnlyDsl") DSLContext readOnlyDsl) {
        this.primaryDsl = primaryDsl;
        this.readOnlyDsl = readOnlyDsl;
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Order> findById(OrderId id) {
        return readOnlyDsl
                .selectFrom(ORDERS)
                .where(ORDERS.ID.eq(id.value()))
                .fetchOptional(this::toDomain);
    }

    @Override
    @Transactional
    public void save(Order order) {
        primaryDsl
                .insertInto(ORDERS)
                .set(ORDERS.ID, order.id().value())
                .set(ORDERS.STATUS, order.status().name())
                .set(ORDERS.CREATED_AT, OffsetDateTime.ofInstant(order.createdAt(), ZoneOffset.UTC))
                .onConflict(ORDERS.ID)
                .doUpdate()
                .set(ORDERS.STATUS, order.status().name())
                .set(ORDERS.UPDATED_AT, OffsetDateTime.now(ZoneOffset.UTC))
                .execute();
    }

    @Override
    @Cacheable(value = "order-listing", cacheManager = "redisCacheManager",
            key = "'customer:' + #customerId.value() + ':' + #request.page()")
    @Transactional(readOnly = true)
    public Slice<OrderSummary> findByCustomer(CustomerId customerId, SliceRequest request) {
        List<OrderSummary> rows = readOnlyDsl
                .select(ORDERS.ID, ORDERS.STATUS, ORDERS.CREATED_AT)
                .from(ORDERS)
                .where(ORDERS.CUSTOMER_ID.eq(customerId.value()))
                .orderBy(ORDERS.CREATED_AT.desc())
                .limit(request.fetchSize())
                .offset(request.offset())
                .fetch(this::toSummary);

        return Slice.of(rows, request);
    }

    // Private mapper: jOOQ Record → domain entity
    private Order toDomain(Record r) {
        return Order.reconstitute(  // Use reconstitute, not create, for DB loads
                new OrderId(r.get(ORDERS.ID)),
                OrderStatus.valueOf(r.get(ORDERS.STATUS)),
                // ... map all fields
                r.get(ORDERS.CREATED_AT).toInstant()
        );
    }
}
```

**Repository implementation rules:**
- Package-private class, `@Repository` annotation
- Inject `primaryDsl` for writes, `@Qualifier("readOnlyDsl")` for reads
- `@Transactional(readOnly = true)` on read methods, `@Transactional` on writes
- Private mapper method converts jOOQ Record → domain entity
- Use `Slice.of(rows, request)` for slice pagination (fetches N+1 rows)
- Use `Pagination.of(items, total, request)` for counted pagination
- Add `@Cacheable` with appropriate cache names for read-heavy queries

## Application Service

```java
// Location: com.storefront.<module>.application
// Visibility: package-private class, implements public interface
@Service
@RequiredArgsConstructor
class OrderService implements OrderApi {

    private final OrderRepository orderRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Override
    @Transactional
    public OrderId placeOrder(CreateOrderCommand command) {
        var orderId = OrderId.generate();
        var order = Order.create(orderId, command.toLines());
        var event = order.place();
        orderRepository.save(order);
        eventPublisher.publishEvent(event);
        return orderId;
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<OrderDetail> findById(OrderId id) {
        return orderRepository.findById(id)
                .map(this::toDetail);
    }
}
```

**Application service rules:**
- Package-private class, `@Service` annotation
- Implements the module's public API interface (e.g., `OrderApi`)
- `@RequiredArgsConstructor` for constructor injection
- Transaction boundaries live HERE (not in repository or controller)
- Publishes domain events via `ApplicationEventPublisher`
- Orchestrates use cases — calls domain methods, repositories, and event publishing

## Public API Interface

```java
// Location: com.storefront.<module> (module root package)
// Visibility: public
public interface OrderApi {
    OrderId placeOrder(CreateOrderCommand command);
    Optional<OrderDetail> findById(OrderId id);
    Slice<OrderSummary> findByCustomer(CustomerId customerId, SliceRequest request);

    // Projection records — public, defined as inner types
    record OrderDetail(OrderId id, OrderStatus status, List<OrderLineDetail> lines, Instant createdAt) {}
    record OrderSummary(OrderId id, OrderStatus status, Instant createdAt) {}
    record CreateOrderCommand(List<OrderLineInput> lines) {
        public List<OrderLine> toLines() { /* map to domain */ }
    }
}
```

**Public API rules:**
- The ONLY cross-module entry point
- Lives at module root: `com.storefront.<module>`
- Projection records (DTOs for cross-module use) defined as inner types
- Methods accept/return only domain primitives, value objects, and projection records

## Controller (Interfaces Layer)

```java
// Location: com.storefront.<module>.interfaces
// Visibility: package-private
@Controller
@RequestMapping("/<module>")
@RequiredArgsConstructor
class OrderController {

    private final OrderApi orderApi;

    @GetMapping("/{id}")
    public String show(@PathVariable UUID id, HttpServletRequest request, Model model) {
        var order = orderApi.findById(new OrderId(id))
                .orElseThrow(() -> new OrderNotFoundException(new OrderId(id)));

        model.addAttribute("order", order);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "<module>/order-detail-content";   // HTMX fragment
        }
        return "<module>/order-detail-page";           // full page with layout
    }

    @GetMapping
    public String list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest request,
            Model model) {

        var slice = orderApi.findByCustomer(
                getCurrentCustomerId(),
                SliceRequest.of(page, size));

        model.addAttribute("orders", slice);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "<module>/order-list-content";
        }
        return "<module>/order-list-page";
    }
}
```

**Controller rules:**
- Package-private class, `@Controller` annotation
- Injects the module's public API interface (NOT the service directly)
- Returns JTE template name (string)
- HTMX detection: `HtmxResponse.isHtmxRequest(request)` → fragment template, else full page
- Use `HtmxResponse.pushUrl(response, url)` for URL updates
- DTOs for request/response live in `interfaces/` package
- Never expose domain entities to templates — use API projection records

## JTE Templates

```
src/main/resources/templates/jte/<module>/
├── order-detail-page.jte          # Full page (includes layout)
├── order-detail-content.jte       # HTMX fragment
├── order-list-page.jte            # Full page
└── order-list-content.jte         # HTMX fragment
```

**Template naming:** `<entity>-<view>-page.jte` for full pages, `<entity>-<view>-content.jte` for fragments.

## Testing (Wiring Layer)

**Repository integration tests:**
```java
class JooqOrderRepositoryTest extends BaseIntegrationTest {
    @Autowired OrderRepository orderRepository;

    @Test
    void shouldSaveAndFind() {
        var order = Order.create(OrderId.generate(), validLines());
        orderRepository.save(order);
        var found = orderRepository.findById(order.id());
        assertTrue(found.isPresent());
        assertEquals(order.id(), found.get().id());
    }
}
```

**Controller tests:**
```java
class OrderControllerTest extends BaseIntegrationTest {
    @Autowired MockMvc mockMvc;

    @Test
    void showReturnsFullPage() throws Exception {
        mockMvc.perform(get("/orders/" + existingOrderId))
                .andExpect(status().isOk())
                .andExpect(view().name("orders/order-detail-page"));
    }

    @Test
    void showReturnsFragmentForHtmx() throws Exception {
        mockMvc.perform(get("/orders/" + existingOrderId)
                        .header("HX-Request", "true"))
                .andExpect(status().isOk())
                .andExpect(view().name("orders/order-detail-content"));
    }
}
```

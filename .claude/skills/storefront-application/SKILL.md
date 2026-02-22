---
name: storefront-application
description: Use when creating or modifying application services, public API interfaces, or event publishing logic. Handles the application layer of the hexagonal architecture with transaction boundaries and use-case orchestration.
argument-hint: "[module-name or use-case-name]"
context: fork
agent: general-purpose
---

# Application — Service + Public API Interface

Creates the application layer that orchestrates use cases and defines the module's public API.

## Public API Interface

The ONLY cross-module entry point. Lives at the module root package.

```java
// Location: com.storefront.<module>/<ModuleName>Api.java
// Visibility: public
public interface OrderApi {
    OrderId placeOrder(CreateOrderCommand command);
    Optional<OrderDetail> findById(OrderId id);
    Slice<OrderSummary> findByCustomer(CustomerId customerId, SliceRequest request);

    // Projection records — public, defined as inner types
    record OrderDetail(OrderId id, OrderStatus status, List<OrderLineDetail> lines, Instant createdAt) {}
    record OrderSummary(OrderId id, OrderStatus status, Instant createdAt) {}
    record CreateOrderCommand(List<OrderLineInput> lines) {
        public List<OrderLine> toLines() { /* map inputs to domain objects */ }
    }
}
```

**Public API rules:**
- Lives at module root: `com.storefront.<module>`
- Projection records (DTOs) defined as inner types of the interface
- Methods accept/return only: domain primitives, value objects, projection records, `Slice`, `Pagination`
- No Spring types, no jOOQ types in the interface

## Application Service

```java
// Location: com.storefront.<module>.application
// Visibility: package-private class
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

    private OrderDetail toDetail(Order order) {
        return new OrderDetail(order.id(), order.status(), /* ... */, order.createdAt());
    }
}
```

**Application service rules:**
- Package-private class, `@Service` annotation
- Implements the module's public API interface
- `@RequiredArgsConstructor` for constructor injection
- **Transaction boundaries live HERE** — not in repository, not in controller
- `@Transactional` for writes, `@Transactional(readOnly = true)` for reads
- Publishes domain events via `ApplicationEventPublisher`
- Orchestrates: domain method calls → repository saves → event publishing

## Event Listening

```java
// Location: com.storefront.<module>.application
@Service
@RequiredArgsConstructor
class InventoryEventHandler {

    private final InventoryRepository inventoryRepository;

    @ApplicationModuleListener
    public void on(ProductCreated event) {
        // React to events from other modules
        inventoryRepository.createDefaultStock(new ProductId(event.productId()));
    }
}
```

**Event listener rules:**
- `@ApplicationModuleListener` on the handler method
- Method name: `on(EventType event)` — simple and consistent
- One handler class per concern (not one per event)

## Testing

```java
class OrderServiceTest {
    private OrderRepository orderRepository = mock(OrderRepository.class);
    private ApplicationEventPublisher eventPublisher = mock(ApplicationEventPublisher.class);
    private OrderService service = new OrderService(orderRepository, eventPublisher);

    @Test
    void placeOrderSavesAndPublishesEvent() {
        var command = new CreateOrderCommand(List.of(validLineInput()));
        var orderId = service.placeOrder(command);
        assertNotNull(orderId);
        verify(orderRepository).save(any(Order.class));
        verify(eventPublisher).publishEvent(any(OrderPlaced.class));
    }
}
```

**Test rules:**
- Mock the repository interface and event publisher
- Test orchestration logic: are the right methods called in the right order?
- Plain JUnit, no Spring context needed for unit tests
- Integration tests extend `BaseIntegrationTest` for full wiring verification

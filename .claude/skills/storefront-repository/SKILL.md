---
name: storefront-repository
description: Use when creating or modifying jOOQ repository implementations, record-to-domain mappers, or caching annotations. Handles the infrastructure layer of the hexagonal architecture with read/write splitting.
argument-hint: "[module-name or entity-name]"
context: fork
agent: general-purpose
---

# Repository — jOOQ Infrastructure Layer

Creates jOOQ-based repository implementations that map between database records and domain entities.

## Layer Rules

- Lives in `com.storefront.<module>.infrastructure`
- Package-private class, `@Repository` annotation
- Implements the repository interface from `domain/model/`
- Domain NEVER imports from this layer

## Read/Write Splitting

Every repository injects two `DSLContext` instances:

```java
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
}
```

- `primaryDsl` — for writes (INSERT, UPDATE, DELETE)
- `@Qualifier("readOnlyDsl")` — for reads (SELECT), routed to replica

## Write Operations

```java
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
```

**Write rules:**
- Always use `primaryDsl`
- `@Transactional` (not readOnly)
- Use upsert (`onConflict().doUpdate()`) for save operations
- Always update `updated_at` on conflict

## Read Operations

```java
@Override
@Transactional(readOnly = true)
public Optional<Order> findById(OrderId id) {
    return readOnlyDsl
            .selectFrom(ORDERS)
            .where(ORDERS.ID.eq(id.value()))
            .fetchOptional(this::toDomain);
}
```

**Read rules:**
- Always use `readOnlyDsl`
- `@Transactional(readOnly = true)`
- Add `@Cacheable` for read-heavy queries:
  ```java
  @Cacheable(value = "order-listing", cacheManager = "redisCacheManager",
          key = "'customer:' + #customerId.value() + ':' + #request.page()")
  ```

## Pagination

**Slice (infinite scroll, no COUNT):**
```java
@Override
@Transactional(readOnly = true)
public Slice<OrderSummary> findByCustomer(CustomerId customerId, SliceRequest request) {
    List<OrderSummary> rows = readOnlyDsl
            .select(ORDERS.ID, ORDERS.STATUS, ORDERS.CREATED_AT)
            .from(ORDERS)
            .where(ORDERS.CUSTOMER_ID.eq(customerId.value()))
            .orderBy(ORDERS.CREATED_AT.desc())
            .limit(request.fetchSize())  // pageSize + 1
            .offset(request.offset())
            .fetch(this::toSummary);

    return Slice.of(rows, request);
}
```

**Pagination (with total count):**
```java
@Override
@Transactional(readOnly = true)
public Pagination<OrderSummary> search(String query, PageRequest request) {
    var condition = ORDERS.SEARCH_VECTOR.search(query);
    int total = readOnlyDsl.selectCount().from(ORDERS).where(condition).fetchOne(0, int.class);
    List<OrderSummary> items = readOnlyDsl
            .select(/* columns */).from(ORDERS).where(condition)
            .limit(request.pageSize()).offset(request.offset())
            .fetch(this::toSummary);
    return Pagination.of(items, total, request);
}
```

## Mapper Methods

```java
// Private method — converts jOOQ Record → domain entity
private Order toDomain(Record r) {
    return Order.reconstitute(
            new OrderId(r.get(ORDERS.ID)),
            OrderStatus.valueOf(r.get(ORDERS.STATUS)),
            r.get(ORDERS.CREATED_AT).toInstant()
    );
}
```

**Mapper rules:**
- Private method on the repository class
- Use `reconstitute` (not `create`) for DB loads — skips creation-time validation
- Wrap raw IDs in value objects
- Convert `OffsetDateTime` → `Instant` when needed
- Never return jOOQ records to callers

## Testing

```java
class JooqOrderRepositoryTest extends BaseIntegrationTest {
    @Autowired OrderRepository orderRepository;

    @Test
    void shouldSaveAndFindById() {
        var order = Order.create(OrderId.generate(), validLines());
        orderRepository.save(order);
        var found = orderRepository.findById(order.id());
        assertTrue(found.isPresent());
        assertEquals(order.id(), found.get().id());
    }

    @Test
    void shouldReturnEmptyForUnknownId() {
        var found = orderRepository.findById(OrderId.generate());
        assertTrue(found.isEmpty());
    }
}
```

**Test rules:**
- Extend `BaseIntegrationTest` (Testcontainers PostgreSQL)
- Test both read and write paths
- Test mapper round-trip: domain entity → save → find → domain entity

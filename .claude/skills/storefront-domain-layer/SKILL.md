---
name: storefront-domain-layer
description: Use when creating or modifying domain model classes — value objects, aggregates, entities, domain events, and repository interfaces. Enforces tactical DDD patterns and hexagonal purity.
argument-hint: "[module-name or entity-name]"
context: fork
agent: general-purpose
---

# Domain Layer — Value Objects, Aggregates, Events, Repository Interfaces

Creates pure domain model classes with no framework dependencies.

## HARD RULE: Domain Purity

Domain classes (`domain/model/` and `domain/shared/`) must have:
- **NO Spring annotations** (`@Service`, `@Component`, `@Transactional`, etc.)
- **NO jOOQ imports** (`org.jooq.*`)
- **NO infrastructure imports** (HTTP, persistence, caching)
- **ONLY** Java standard library + other domain classes + `com.storefront.shared` domain primitives

## Value Objects

**Every ID is a value object.** Never use raw `UUID`, `String`, or `Long` for identity.

```java
// Location: com.storefront.<module>.domain.model.<EntityName>Id
// Pattern: extend UlidIdentifier from shared
public final class OrderId extends UlidIdentifier {
    public OrderId(UUID value) { super(value); }
    public static OrderId generate() { return new OrderId(UlidIdentifier.newUlid()); }
}
```

**Other value objects** use Java records with validation:

```java
// Location: com.storefront.<module>.domain.model
public record Quantity(int value) {
    public Quantity {
        if (value < 0) throw new IllegalArgumentException("Quantity must be non-negative, got: " + value);
    }
    public static Quantity of(int value) { return new Quantity(value); }
    public Quantity add(Quantity other) { return new Quantity(this.value + other.value); }
}
```

**Value object rules:**
- Immutable (records preferred)
- Validate invariants in constructor — never allow invalid state
- Static factory methods for common creation patterns
- Override `toString()` for meaningful debugging (records do this automatically)
- Use `Money` from `com.storefront.shared` for monetary values (do NOT create module-specific money types)

## Aggregate Root

```java
// Location: com.storefront.<module>.domain.model
public class Order {
    private final OrderId id;
    private OrderStatus status;
    private final List<OrderLine> lines;
    private final Instant createdAt;

    // Private constructor — creation through factory method only
    private Order(OrderId id, List<OrderLine> lines) {
        this.id = id;
        this.status = OrderStatus.DRAFT;
        this.lines = new ArrayList<>(lines);
        this.createdAt = Instant.now();
        validate();
    }

    // Factory method — the ONLY way to create
    public static Order create(OrderId id, List<OrderLine> lines) {
        if (lines.isEmpty()) throw new IllegalArgumentException("Order must have at least one line");
        return new Order(id, lines);
    }

    // State transitions return domain events
    public OrderPlaced place() {
        if (status != OrderStatus.DRAFT) throw new IllegalStateException("Can only place DRAFT orders");
        this.status = OrderStatus.PLACED;
        return new OrderPlaced(id, lines.size(), Instant.now());
    }

    // Invariant enforcement
    private void validate() {
        if (id == null) throw new IllegalArgumentException("Order ID required");
    }

    // Getters — no setters
    public OrderId id() { return id; }
    public OrderStatus status() { return status; }
    public List<OrderLine> lines() { return List.copyOf(lines); }
}
```

**Aggregate rules:**
- Private constructor, public static factory method
- Enforce invariants in factory and on every state transition
- State transitions return domain events (not void)
- Collections returned as unmodifiable copies
- Reference other aggregates by ID only (e.g., `CustomerId`, not `Customer`)
- One aggregate = one transactional boundary

## Domain Events

```java
// Location: com.storefront.<module>.domain.model
public record OrderPlaced(
    OrderId orderId,
    int lineCount,
    Instant occurredAt
) implements DomainEvent {}
```

**Event rules:**
- Immutable Java records implementing `com.storefront.shared.DomainEvent`
- Named in past tense: `OrderPlaced`, `ShipmentDispatched`, `InventoryReserved`
- Contain only the data consumers need (IDs, counts, timestamps — not full entities)
- Published by the application service via `ApplicationEventPublisher`

## Repository Interface

```java
// Location: com.storefront.<module>.domain.model
public interface OrderRepository {
    Optional<Order> findById(OrderId id);
    void save(Order order);
    Slice<OrderSummary> findByCustomer(CustomerId customerId, SliceRequest request);
}
```

**Repository interface rules:**
- Lives in `domain/model/` (NOT infrastructure)
- Method signatures use ONLY domain types (value objects, entities, `Slice`, `Pagination`)
- No jOOQ types, no Spring types in the interface
- Implementation goes in `infrastructure/` (handled by `/storefront-wiring-layer`)

## Domain Exceptions

```java
// Location: com.storefront.<module>.domain.model
public class OrderNotFoundException extends RuntimeException {
    private final OrderId orderId;
    public OrderNotFoundException(OrderId orderId) {
        super("Order not found: " + orderId);
        this.orderId = orderId;
    }
    public OrderId orderId() { return orderId; }
}
```

## Testing (Domain Layer)

Plain JUnit — NO Spring context needed:

```java
// Location: src/test/java/com/storefront/<module>/domain/model/
class OrderTest {
    @Test
    void shouldCreateDraftOrder() {
        var id = OrderId.generate();
        var lines = List.of(new OrderLine(/* ... */));
        var order = Order.create(id, lines);
        assertEquals(OrderStatus.DRAFT, order.status());
    }

    @Test
    void shouldRejectEmptyOrder() {
        assertThrows(IllegalArgumentException.class,
            () -> Order.create(OrderId.generate(), List.of()));
    }

    @Test
    void shouldReturnEventOnPlace() {
        var order = createValidOrder();
        var event = order.place();
        assertInstanceOf(OrderPlaced.class, event);
        assertEquals(order.id(), event.orderId());
    }

    @Test
    void shouldRejectPlacingAlreadyPlacedOrder() {
        var order = createValidOrder();
        order.place();
        assertThrows(IllegalStateException.class, order::place);
    }
}
```

**Test naming:** Use domain language — `shouldRejectOrderWithNoItems`, not `testValidation1`

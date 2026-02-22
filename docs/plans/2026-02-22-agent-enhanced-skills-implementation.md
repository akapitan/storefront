# Agent-Enhanced Skill System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade the existing 6-skill system to support sub-agent dispatching via the Task tool, split the wiring-layer into 3 granular skills, and make the Architect an active orchestrator that can run features end-to-end (plan → execute → PR).

**Architecture:** Modify existing `.claude/skills/` files in the `create_skills` worktree. Skills serve as knowledge files; the Architect dispatches them as Task tool agents for isolated execution. All Tier 3 skills get `context: fork` for standalone use.

**Tech Stack:** Claude Code skills (YAML frontmatter + markdown), Task tool sub-agents, git worktrees

**Design docs:**
- `docs/plans/2026-02-22-skill-system-design.md` (original)
- `docs/plans/2026-02-22-agent-enhanced-skills-design.md` (agent enhancement)

---

### Task 0: Create new skill directories

**Files:**
- Create: `.claude/skills/storefront-repository/SKILL.md` (empty placeholder)
- Create: `.claude/skills/storefront-application/SKILL.md` (empty placeholder)
- Create: `.claude/skills/storefront-presentation/SKILL.md` (empty placeholder)

**Step 1: Create directories**

```bash
mkdir -p .claude/skills/storefront-repository
mkdir -p .claude/skills/storefront-application
mkdir -p .claude/skills/storefront-presentation
touch .claude/skills/storefront-repository/SKILL.md
touch .claude/skills/storefront-application/SKILL.md
touch .claude/skills/storefront-presentation/SKILL.md
```

**Step 2: Verify**

```bash
ls .claude/skills/
```

Expected: 9 directories (6 existing + 3 new)

**Step 3: Commit**

```bash
git add .claude/skills/storefront-repository/ .claude/skills/storefront-application/ .claude/skills/storefront-presentation/
git commit -m "Add skill directories for repository, application, and presentation"
```

---

### Task 1: Write storefront-repository skill

**Files:**
- Create: `.claude/skills/storefront-repository/SKILL.md`

Extract the infrastructure/repository section from the existing `storefront-wiring-layer/SKILL.md`.

**Step 1: Write the skill file**

Write to `.claude/skills/storefront-repository/SKILL.md`:

```markdown
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

` ``java
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
` ``

- `primaryDsl` — for writes (INSERT, UPDATE, DELETE)
- `@Qualifier("readOnlyDsl")` — for reads (SELECT), routed to replica

## Write Operations

` ``java
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
` ``

**Write rules:**
- Always use `primaryDsl`
- `@Transactional` (not readOnly)
- Use upsert (`onConflict().doUpdate()`) for save operations
- Always update `updated_at` on conflict

## Read Operations

` ``java
@Override
@Transactional(readOnly = true)
public Optional<Order> findById(OrderId id) {
    return readOnlyDsl
            .selectFrom(ORDERS)
            .where(ORDERS.ID.eq(id.value()))
            .fetchOptional(this::toDomain);
}
` ``

**Read rules:**
- Always use `readOnlyDsl`
- `@Transactional(readOnly = true)`
- Add `@Cacheable` for read-heavy queries:
  ` ``java
  @Cacheable(value = "order-listing", cacheManager = "redisCacheManager",
          key = "'customer:' + #customerId.value() + ':' + #request.page()")
  ` ``

## Pagination

**Slice (infinite scroll, no COUNT):**
` ``java
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
` ``

**Pagination (with total count):**
` ``java
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
` ``

## Mapper Methods

` ``java
// Private method — converts jOOQ Record → domain entity
private Order toDomain(Record r) {
    return Order.reconstitute(
            new OrderId(r.get(ORDERS.ID)),
            OrderStatus.valueOf(r.get(ORDERS.STATUS)),
            r.get(ORDERS.CREATED_AT).toInstant()
    );
}
` ``

**Mapper rules:**
- Private method on the repository class
- Use `reconstitute` (not `create`) for DB loads — skips creation-time validation
- Wrap raw IDs in value objects
- Convert `OffsetDateTime` → `Instant` when needed
- Never return jOOQ records to callers

## Testing

` ``java
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
` ``

**Test rules:**
- Extend `BaseIntegrationTest` (Testcontainers PostgreSQL)
- Test both read and write paths
- Test mapper round-trip: domain entity → save → find → domain entity
```

**Step 2: Verify frontmatter**

```bash
head -7 .claude/skills/storefront-repository/SKILL.md
```

Expected: YAML frontmatter with `context: fork` and `agent: general-purpose`

**Step 3: Commit**

```bash
git add .claude/skills/storefront-repository/SKILL.md
git commit -m "Add storefront-repository skill (infrastructure layer)"
```

---

### Task 2: Write storefront-application skill

**Files:**
- Create: `.claude/skills/storefront-application/SKILL.md`

Extract the application service + public API section from `storefront-wiring-layer/SKILL.md`.

**Step 1: Write the skill file**

Write to `.claude/skills/storefront-application/SKILL.md`:

```markdown
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

` ``java
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
` ``

**Public API rules:**
- Lives at module root: `com.storefront.<module>`
- Projection records (DTOs) defined as inner types of the interface
- Methods accept/return only: domain primitives, value objects, projection records, `Slice`, `Pagination`
- No Spring types, no jOOQ types in the interface

## Application Service

` ``java
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
` ``

**Application service rules:**
- Package-private class, `@Service` annotation
- Implements the module's public API interface
- `@RequiredArgsConstructor` for constructor injection
- **Transaction boundaries live HERE** — not in repository, not in controller
- `@Transactional` for writes, `@Transactional(readOnly = true)` for reads
- Publishes domain events via `ApplicationEventPublisher`
- Orchestrates: domain method calls → repository saves → event publishing

## Event Listening

` ``java
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
` ``

**Event listener rules:**
- `@ApplicationModuleListener` on the handler method
- Method name: `on(EventType event)` — simple and consistent
- One handler class per concern (not one per event)

## Testing

` ``java
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
` ``

**Test rules:**
- Mock the repository interface and event publisher
- Test orchestration logic: are the right methods called in the right order?
- Plain JUnit, no Spring context needed for unit tests
- Integration tests extend `BaseIntegrationTest` for full wiring verification
```

**Step 2: Verify frontmatter**

```bash
head -7 .claude/skills/storefront-application/SKILL.md
```

**Step 3: Commit**

```bash
git add .claude/skills/storefront-application/SKILL.md
git commit -m "Add storefront-application skill (application layer)"
```

---

### Task 3: Write storefront-presentation skill

**Files:**
- Create: `.claude/skills/storefront-presentation/SKILL.md`

Extract the controller + DTOs + JTE template section from `storefront-wiring-layer/SKILL.md`.

**Step 1: Write the skill file**

Write to `.claude/skills/storefront-presentation/SKILL.md`:

```markdown
---
name: storefront-presentation
description: Use when creating or modifying controllers, request/response DTOs, JTE templates, or HTMX interactions. Handles the interfaces layer of the hexagonal architecture.
argument-hint: "[module-name or view-name]"
context: fork
agent: general-purpose
---

# Presentation — Controllers + DTOs + JTE Templates

Creates the interfaces layer: REST controllers with HTMX support, request/response DTOs, and JTE templates.

## Controller

` ``java
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
            HttpServletResponse response,
            Model model) {

        var slice = orderApi.findByCustomer(
                getCurrentCustomerId(),
                SliceRequest.of(page, size));

        model.addAttribute("orders", slice);
        HtmxResponse.pushUrl(response, buildUrl(page, size));

        if (HtmxResponse.isHtmxRequest(request)) {
            return "<module>/order-list-content";
        }
        return "<module>/order-list-page";
    }
}
` ``

**Controller rules:**
- Package-private class, `@Controller`
- Injects the module's **public API interface** (NOT the service class directly)
- Returns JTE template name as string
- HTMX detection: `HtmxResponse.isHtmxRequest(request)` → fragment, else full page
- Use `HtmxResponse.pushUrl(response, url)` for browser URL updates
- Use `HtmxResponse.trigger(response, event)` for client-side events
- Never expose domain entities to templates — use API projection records

## HTMX Patterns

**Fragment vs full page:**
` ``java
if (HtmxResponse.isHtmxRequest(request)) {
    return "module/view-content";   // fragment only (no layout wrapper)
}
return "module/view-page";          // full page with layout
` ``

**Infinite scroll (Slice pagination):**
` ``html
<div hx-get="/orders?page=${slice.page() + 1}"
     hx-trigger="revealed"
     hx-swap="afterend">
</div>
` ``

**Debounced search:**
` ``html
<input type="search"
       hx-get="/orders/search"
       hx-trigger="input changed delay:300ms"
       hx-target="#results"
       name="q">
` ``

## Request/Response DTOs

` ``java
// Location: com.storefront.<module>.interfaces
// Only needed when API projection records don't match what the template needs
record OrderListItem(UUID id, String status, String formattedDate) {
    static OrderListItem from(OrderApi.OrderSummary summary) {
        return new OrderListItem(
            summary.id().value(),
            summary.status().displayName(),
            DateFormatter.format(summary.createdAt())
        );
    }
}
` ``

**DTO rules:**
- Only create DTOs when API projection records don't match template needs
- Live in `interfaces/` package
- Package-private records
- Static factory method `from(ApiProjection)` for mapping

## JTE Templates

**Directory structure:**
` ``
src/main/resources/templates/jte/<module>/
├── order-detail-page.jte          # Full page (includes layout)
├── order-detail-content.jte       # HTMX fragment
├── order-list-page.jte            # Full page
└── order-list-content.jte         # HTMX fragment
` ``

**Naming convention:** `<entity>-<view>-page.jte` for full pages, `<entity>-<view>-content.jte` for fragments.

**Full page template pattern:**
` ``html
@import com.storefront.<module>.OrderApi.OrderDetail
@param OrderDetail order

@template.layout(title = "Order Details")
    <div id="order-content">
        <%-- Content here --%>
    </div>
@endtemplate
` ``

**Fragment template pattern:**
` ``html
@import com.storefront.<module>.OrderApi.OrderDetail
@param OrderDetail order

<div id="order-content">
    <%-- Same content as page, without layout wrapper --%>
</div>
` ``

## Testing

` ``java
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

    @Test
    void listReturnsPaginatedResults() throws Exception {
        mockMvc.perform(get("/orders?page=0&size=10"))
                .andExpect(status().isOk())
                .andExpect(model().attributeExists("orders"));
    }
}
` ``

**Test rules:**
- Extend `BaseIntegrationTest` for MockMvc tests
- Test BOTH full-page and HTMX fragment responses
- Test pagination parameters
- Test 404 for missing resources
```

**Step 2: Verify frontmatter**

```bash
head -7 .claude/skills/storefront-presentation/SKILL.md
```

**Step 3: Commit**

```bash
git add .claude/skills/storefront-presentation/SKILL.md
git commit -m "Add storefront-presentation skill (interfaces layer)"
```

---

### Task 4: Delete storefront-wiring-layer skill

**Files:**
- Delete: `.claude/skills/storefront-wiring-layer/SKILL.md`
- Delete: `.claude/skills/storefront-wiring-layer/` directory

**Step 1: Remove the skill**

```bash
git rm -r .claude/skills/storefront-wiring-layer/
```

**Step 2: Verify it's gone**

```bash
ls .claude/skills/ | sort
```

Expected: 8 directories (no `storefront-wiring-layer`)

**Step 3: Commit**

```bash
git commit -m "Remove storefront-wiring-layer (replaced by repository, application, presentation)"
```

---

### Task 5: Update Tier 3 skill frontmatter (add context: fork)

**Files:**
- Modify: `.claude/skills/storefront-schema/SKILL.md` (frontmatter only)
- Modify: `.claude/skills/storefront-domain-layer/SKILL.md` (frontmatter only)
- Modify: `.claude/skills/storefront-suggest-improvement/SKILL.md` (frontmatter only)

**Step 1: Update storefront-schema frontmatter**

Replace the frontmatter in `.claude/skills/storefront-schema/SKILL.md`:

Old:
```yaml
---
name: storefront-schema
description: Use when creating or modifying database schema — Flyway migrations, jOOQ code generation, and record-to-domain mappers. Enforces naming conventions, column standards, and indexing patterns.
argument-hint: "[module-name or description]"
---
```

New:
```yaml
---
name: storefront-schema
description: Use when creating or modifying database schema — Flyway migrations, jOOQ code generation, and record-to-domain mappers. Enforces naming conventions, column standards, and indexing patterns.
argument-hint: "[module-name or description]"
context: fork
agent: general-purpose
---
```

**Step 2: Update storefront-domain-layer frontmatter**

Old:
```yaml
---
name: storefront-domain-layer
description: Use when creating or modifying domain model classes — value objects, aggregates, entities, domain events, and repository interfaces. Enforces tactical DDD patterns and hexagonal purity.
argument-hint: "[module-name or entity-name]"
---
```

New:
```yaml
---
name: storefront-domain-layer
description: Use when creating or modifying domain model classes — value objects, aggregates, entities, domain events, and repository interfaces. Enforces tactical DDD patterns and hexagonal purity.
argument-hint: "[module-name or entity-name]"
context: fork
agent: general-purpose
---
```

**Step 3: Update storefront-suggest-improvement frontmatter**

Old:
```yaml
---
name: storefront-suggest-improvement
description: Use after completing any implementation task to check for skill drift — compares recent work against skill rules and proposes updates. Auto-invoked by the Architect skill after task completion.
---
```

New:
```yaml
---
name: storefront-suggest-improvement
description: Use after completing any implementation task to check for skill drift — compares recent work against skill rules and proposes updates. Auto-invoked by the Architect skill after task completion.
context: fork
agent: general-purpose
---
```

**Step 4: Also update the skill file references in suggest-improvement**

In `.claude/skills/storefront-suggest-improvement/SKILL.md`, update the "Compare Against Skills" section to list the new skill names:

Old:
```
- `.claude/skills/storefront-schema/SKILL.md`
- `.claude/skills/storefront-domain-layer/SKILL.md`
- `.claude/skills/storefront-wiring-layer/SKILL.md`
- `.claude/skills/storefront-add-module/SKILL.md`
- `.claude/skills/storefront-architect/SKILL.md`
```

New:
```
- `.claude/skills/storefront-schema/SKILL.md`
- `.claude/skills/storefront-domain-layer/SKILL.md`
- `.claude/skills/storefront-repository/SKILL.md`
- `.claude/skills/storefront-application/SKILL.md`
- `.claude/skills/storefront-presentation/SKILL.md`
- `.claude/skills/storefront-add-module/SKILL.md`
- `.claude/skills/storefront-architect/SKILL.md`
```

**Step 5: Verify changes**

```bash
head -7 .claude/skills/storefront-schema/SKILL.md
head -7 .claude/skills/storefront-domain-layer/SKILL.md
head -7 .claude/skills/storefront-suggest-improvement/SKILL.md
```

**Step 6: Commit**

```bash
git add .claude/skills/storefront-schema/SKILL.md .claude/skills/storefront-domain-layer/SKILL.md .claude/skills/storefront-suggest-improvement/SKILL.md
git commit -m "Add context: fork frontmatter to Tier 3 skills and update suggest-improvement references"
```

---

### Task 6: Update storefront-add-module orchestration sequence

**Files:**
- Modify: `.claude/skills/storefront-add-module/SKILL.md`

**Step 1: Update the Orchestration Sequence section**

Replace the current "Orchestration Sequence" section (Phases 1-4) with:

```markdown
## Orchestration Sequence

Execute these skills in order. Each must complete before the next begins.

### Phase 1: Schema
Invoke `/storefront-schema` with the module name.
- Creates Flyway migration with tables for the module
- Runs `./gradlew generateJooqClasses` to generate jOOQ classes
- Commit after this phase

### Phase 2: Domain Layer
Invoke `/storefront-domain-layer` with the module name.
- Creates value objects (IDs), aggregate root, domain events, repository interface
- Commit after this phase

### Phase 3: Repository
Invoke `/storefront-repository` with the module name.
- Creates jOOQ repository implementation with read/write splitting
- Creates mapper methods for domain entity round-tripping
- Commit after this phase

### Phase 4: Application
Invoke `/storefront-application` with the module name.
- Creates the public API interface at module root
- Creates the application service implementing the API
- Sets up event publishing
- Commit after this phase

### Phase 5: Presentation
Invoke `/storefront-presentation` with the module name.
- Creates controller with HTMX handling
- Creates JTE templates (page + fragment for each view)
- Commit after this phase

### Phase 6: Module Verification
After all phases:

1. **Spring Modulith test** — verify module boundaries:
   ` ``java
   @SpringBootTest
   class <ModuleName>ModuleTest extends BaseIntegrationTest {
       @Test
       void moduleIsValid() {
           ApplicationModules.of(StorefrontApplication.class).verify();
       }
   }
   ` ``

2. **Build passes:**
   ` ``bash
   ./gradlew build
   ` ``

3. **Commit the test and any fixes**
```

**Step 2: Verify**

```bash
grep -c "Phase" .claude/skills/storefront-add-module/SKILL.md
```

Expected: 6 phases

**Step 3: Commit**

```bash
git add .claude/skills/storefront-add-module/SKILL.md
git commit -m "Update storefront-add-module to reference 5 Tier 3 skills"
```

---

### Task 7: Rewrite storefront-architect with orchestration

**Files:**
- Modify: `.claude/skills/storefront-architect/SKILL.md` (full rewrite)

This is the largest change. The Architect gains orchestration, plan presentation, agent dispatching, build verification, and PR creation.

**Step 1: Rewrite the skill file**

Replace the entire contents of `.claude/skills/storefront-architect/SKILL.md` with:

```markdown
---
name: storefront-architect
description: Use when starting any non-trivial task on the storefront project — new features, new modules, significant changes, or bug fixes. Analyzes the task, presents an execution plan, dispatches sub-agents, verifies the build, and opens a PR.
---

# Storefront Architect

You are the orchestrator for all non-trivial storefront work. You **analyze**, **plan**, **dispatch agents**, **verify**, and **deliver** (PR).

## Strategic DDD Rules (enforce at all times)

1. **Each module = one bounded context.** Never let a feature span two modules without explicit anti-corruption layer discussion.
2. **Cross-module communication ONLY through:**
   - Public API interface (e.g., `CatalogApi`) for synchronous queries
   - Domain events (`implements DomainEvent`) for asynchronous notifications
   - `@ApplicationModuleListener` for event consumption
3. **Shared kernel** (`com.storefront.shared`) is limited to: domain primitives (`Money`, `DomainEvent`), pagination (`Slice`, `Pagination`, `SliceRequest`, `PageRequest`), HTMX utilities (`HtmxResponse`), jOOQ converters. **NEVER put business logic in shared.**
4. **Context mapping:** Before any cross-module work, identify the relationship (upstream/downstream, conformist, ACL) and document it.
5. **New module checklist:** Clear bounded context? Owns its own data? Has a public API interface at module root?

## Process: Analyze → Plan → Dispatch → Verify → PR

### Step 1: Analyze

Read the user's request and classify it:

| If the task involves...              | Skills to dispatch                                                |
|--------------------------------------|-------------------------------------------------------------------|
| New module / bounded context         | schema → domain-layer → repository → application → presentation  |
| New entity in existing module        | domain-layer → repository → application → presentation           |
| Schema/migration change only         | schema                                                            |
| Domain model change only             | domain-layer                                                      |
| Repository change only               | repository                                                        |
| Service/API change only              | application                                                       |
| Controller/template change only      | presentation                                                      |
| Bug fix                              | Use `superpowers-extended-cc:systematic-debugging`                |
| Creative / unclear scope             | Use `superpowers-extended-cc:brainstorming` first, then re-route  |
| Cross-module change                  | Analyze context mapping, then dispatch per affected module        |

### Step 2: Plan

Build an execution plan and present it to the user:

` ``
## Execution Plan

**Task:** [description]
**Phases:**

1. [Phase name] — [what will be done]
   Files: [files to create/modify]
   Agent: [skill name]

2. [Phase name] — [what will be done]
   Files: [files to create/modify]
   Agent: [skill name]

...

**After all phases:** build + test → PR

Approve? [Yes / Modify / Cancel]
` ``

Wait for user approval before proceeding.

### Step 3: Dispatch Agents

For each phase, dispatch a Task tool agent:

` ``
Task(
  subagent_type: "general-purpose",
  prompt: |
    You are a specialized agent working on the storefront project.

    ## Your Task
    [specific task description]

    ## Module Context
    - Module name: [name]
    - Package: com.storefront.[name]
    - Working directory: [path]
    [output from previous phases if applicable]

    ## Rules (follow exactly)
    [read and include the full contents of the relevant SKILL.md file]

    ## When Done
    - Commit your changes with a descriptive message
    - Report what files you created/modified
    - Report any issues or decisions you made
)
` ``

**Dispatch rules:**
- Read the sub-skill's SKILL.md file and include its FULL content in the agent prompt
- Pass context from previous phases (file paths created, decisions made)
- Phases run sequentially — each depends on the previous
- Review each agent's result before dispatching the next
- If an agent fails, stop and report — do not continue blindly

### Step 4: Verify

After all agents complete:

` ``bash
./gradlew build
./gradlew test
` ``

If either fails:
1. Read the error output
2. Attempt to fix the issue
3. Re-run verification
4. If unable to fix after 2 attempts, report the error to the user

### Step 5: Open PR

` ``bash
# Create branch if not already on a feature branch
git checkout -b feature/[description]

# Push
git push -u origin feature/[description]

# Open PR
gh pr create --title "[descriptive title under 70 chars]" --body "$(cat <<'EOF'
## Summary
- [bullet points of what was built]
- [which agents ran and what they produced]

## Test Results
- [build status]
- [test status]

## Skills Used
- [list of skills dispatched]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
` ``

### Step 6: Suggest Improvements

After PR is created, dispatch the meta-skill:

` ``
Read .claude/skills/storefront-suggest-improvement/SKILL.md
Dispatch as Task tool agent to review the work for skill drift
Present any proposals to the user
` ``

## Red Flags — Stop and Discuss

- User wants to put business logic in `shared/` → explain why not
- User wants Module A to directly import Module B's internal classes → suggest public API or events
- User wants to skip the domain layer and put logic in the controller → push back
- User wants raw `UUID`/`String`/`Long` for an ID → must be a value object
- Agent failed and the error looks structural → stop, don't retry blindly

## When NOT to Orchestrate

For simple, single-skill tasks (e.g., "add a column to the orders table"), you don't need the full orchestration flow. Just invoke the relevant skill directly. Use orchestration for multi-skill work.
```

**Step 2: Verify the rewrite**

```bash
wc -l .claude/skills/storefront-architect/SKILL.md
```

Expected: significantly longer than the original (~60 lines → ~150+ lines)

**Step 3: Commit**

```bash
git add .claude/skills/storefront-architect/SKILL.md
git commit -m "Rewrite storefront-architect with agent orchestration and PR creation"
```

---

### Task 8: Update CLAUDE.md skill system section

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Update the Skill System section**

Replace the current `## Skill System` section in CLAUDE.md with:

```markdown
## Skill System

This project uses a three-tier skill system in `.claude/skills/`.
When working on this project, ALWAYS check if a skill applies before starting work.

### Tier 1 — Architect (entry point for non-trivial tasks)
- Skill: `/storefront-architect`
- Invoke for: any feature, new module, significant change, or bug fix
- The Architect analyzes the task, presents a plan, dispatches sub-agents, verifies, and opens a PR

### Tier 2 — Domain Orchestrators
- `/storefront-add-module` — new bounded context / module (orchestrates all Tier 3 skills)
- (future: storefront-add-entity, storefront-cross-module)

### Tier 3 — Building Blocks (invoked by Tier 2, or directly for targeted changes)
- `/storefront-schema` — Flyway migrations + jOOQ code generation
- `/storefront-domain-layer` — Value objects, aggregates, events, repository interfaces
- `/storefront-repository` — jOOQ repository implementations, mappers, caching
- `/storefront-application` — Application services, public API interfaces, event publishing
- `/storefront-presentation` — Controllers, DTOs, JTE templates, HTMX handling

### Meta
- `/storefront-suggest-improvement` — auto-invoked after task completion, proposes skill updates when patterns diverge from rules
```

**Step 2: Verify**

```bash
grep "storefront-" CLAUDE.md | wc -l
```

Expected: 8 or more lines referencing storefront skills

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "Update CLAUDE.md skill system section with 5 Tier 3 skills and agent description"
```

---

### Task 9: Verify complete skill system

**Step 1: List all skills**

```bash
find .claude/skills -name "SKILL.md" | sort
```

Expected (8 skills):
```
.claude/skills/storefront-add-module/SKILL.md
.claude/skills/storefront-application/SKILL.md
.claude/skills/storefront-architect/SKILL.md
.claude/skills/storefront-domain-layer/SKILL.md
.claude/skills/storefront-presentation/SKILL.md
.claude/skills/storefront-repository/SKILL.md
.claude/skills/storefront-schema/SKILL.md
.claude/skills/storefront-suggest-improvement/SKILL.md
```

**Step 2: Verify all Tier 3 skills have context: fork**

```bash
for f in .claude/skills/storefront-{schema,domain-layer,repository,application,presentation,suggest-improvement}/SKILL.md; do
  echo "=== $(basename $(dirname $f)) ==="
  grep "context:" "$f" || echo "MISSING context: fork"
done
```

Expected: all 6 show `context: fork`

**Step 3: Verify no storefront-wiring-layer remains**

```bash
ls .claude/skills/storefront-wiring-layer 2>/dev/null && echo "STILL EXISTS" || echo "OK - removed"
```

Expected: `OK - removed`

**Step 4: Verify CLAUDE.md references all skills**

```bash
grep "storefront-" CLAUDE.md
```

Expected: all 8 skill names appear

**Step 5: Run project build**

```bash
./gradlew build
```

Expected: BUILD SUCCESSFUL

**Step 6: Final commit if any fixes needed**

```bash
git status
```

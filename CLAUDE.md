# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## General rule
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is EXTREMELY IMPORTANT::
- Do not make documentation after every code change
- Don't flatter me. Be charming and nice, but very honest. Tell me something I need to know even if I don't want to hear it
- Flag unclear but important points before they become problems. Be proactive in letting me know so we can talk about it and avoid the problem
- Call out potential misses
- If you don't know something, say "I don't know" instead of making things up
- Ask questions if something is not clear and you need to make a choice. Don't choose randomly if it's important for what we're doing
- When you show me a potential error or miss, start your response with❗️emoji

## Project Overview
- A Spring Boot modular monolith storefront (McMaster-Carr style industrial catalog)
- Three modules: catalog (browsing/search), inventory (stock), cart (session-based shopping cart)
- JTE + HTMX frontend with category browsing, product detail, search, and filtering
- Cart API is defined but no cart controller or templates exist yet
- No checkout/order module exists

## Documentation Lookup

When unsure about library APIs or recent changes:
1. Use Context7 MCP to fetch current documentation
2. Prefer official docs over training knowledge
3. Always verify version compatibility

## Build & Run Commands

```bash
# Start infrastructure (PostgreSQL 16, Redis 7)
docker compose up -d

# Run the application (dev profile)
./gradlew bootRunDev

# Build ./gradlew build

# Run tests
./gradlew test

# Regenerate jOOQ classes from DB schema (requires Docker — spins up a Testcontainers PG)
./gradlew generateJooqClasses
```

## Architecture

**Spring Boot 4.0.2 modular monolith** (Spring Modulith) with Java 21 virtual threads, HTMX frontend, and jOOQ data access.

### Module Structure (`com.storefront.*`)

Each module exposes a public API interface and communicates cross-module via domain events:

- **catalog** — Product browsing, search, categories. Public API: `CatalogApi`. Controller: `ProductController`.
- **inventory** — Stock levels, warehouse locations, reorder rules. Public API: `InventoryApi`. Listens to catalog events.
- **cart** — Shopping cart (session-based). Public API: `CartApi`.
- **shared** — Domain primitives (`Money`, `DomainEvent`), pagination types (`Slice`, `Pagination`, `PageRequest`, `SliceRequest`), HTMX utilities (`HtmxResponse`, `TemplateHelpers`), jOOQ converters.
- **config** — `DataSourceConfig` (primary/replica routing), `CacheConfig` (Caffeine L1 + Redis L2), `JteConfig`.

Module boundaries are enforced by Spring Modulith — modules must only depend on each other through their public API interfaces and events.

### Hexagonal Architecture

Each public module follows a four-layer hexagonal package structure:

```
com.storefront.<module>/
├── interfaces/       # Inbound adapters (controllers, DTOs)
├── application/      # Use-case orchestration
├── domain/           # Pure business logic (no framework imports)
│   ├── model/        # Entities, value objects, repository interfaces, domain events, exceptions
│   └── shared/       # Base classes (UlidIdentifier, JsonbHelper)
└── infrastructure/   # Outbound adapters (DB, messaging, external APIs)
```

**Dependency rule**: `interfaces → application → domain ← infrastructure`. Domain NEVER imports from other layers.

| Layer | Responsibility | Visibility | Spring Stereotypes |
|-------|---------------|------------|-------------------|
| `domain/model` | Entities, value objects, repository interfaces, domain events, exceptions | `public` interfaces and models | None |
| `domain/shared` | Base classes (`UlidIdentifier`, `JsonbHelper`) | `public` | None |
| `application` | Use-case orchestration, transaction boundaries, event publishing | `public` interfaces, package-private impls | `@Service` |
| `infrastructure` | Technical adapters (DB, messaging, security, external APIs) | Package-private classes | `@Repository`, `@Configuration` |
| `interfaces` | REST controllers, request/response DTOs | Package-private classes | `@Controller` |

**Key rules:**
- Every ID must be a **value object** (e.g., `ProductId`, `CategoryId`, `SkuId`), never a raw `Long`/`String`/`UUID`.
- **Domain models are separate from jOOQ generated classes.** Infrastructure repositories map between jOOQ records and domain entities.
- Always prefer **value objects** over primitives for domain concepts (e.g., `Money`, `Quantity`, `Sku`).
- Repository **interfaces** live in `domain/model`; **implementations** (jOOQ-based) live in `infrastructure`.
- The module's **public API interface** (e.g., `CatalogApi`) lives at the module root and is the only cross-module entry point.

### Data Access — jOOQ with Read/Write Splitting

Repositories inject two `DSLContext` instances:
- `primaryDsl` — for writes
- `@Qualifier("readOnlyDsl")` — for reads, routed to replica via `AbstractRoutingDataSource`

Generated jOOQ classes live in `src/generated/java` (package `com.storefront.jooq`), generated from Flyway migrations in `src/main/resources/db/migration/`.

### Frontend — JTE + HTMX

Templates in `src/main/resources/templates/jte/`. Controllers return fragment-only templates for HTMX requests (detected via `HX-Request` header) and full-page templates otherwise:

```java
if (HtmxResponse.isHtmxRequest(request)) {
    return "catalog/product-grid-content";  // fragment
}
return "catalog/product-grid";              // full page with layout
```

Patterns used: partial page swaps, `hx-push-url` for history, `hx-trigger="revealed"` for infinite scroll, debounced search input.

### Caching — Two-Layer

- **L1 (Caffeine):** In-JVM, short TTL (categories 1h, product detail 2min)
- **L2 (Redis):** Distributed, longer TTL (product detail 5min, listings/search 30s, inventory 15s)

### Database

PostgreSQL with full-text search (`tsvector` + trigram indexes), JSONB product attributes, materialized views for category counts. Flyway manages migrations.

### Pagination Convention

- **Slice** (no COUNT query, fetches N+1 rows) — used for infinite scroll
- **Pagination** (includes total count) — used for search results with page numbers

## Skill System

This project uses a three-tier skill system in `.claude/skills/`.
When working on this project, ALWAYS check if a skill applies before starting work.

### Tier 1 — Architect (entry point for non-trivial tasks)
- Skill: `/storefront-architect`
- Invoke for: any feature, new module, significant change, or bug fix
- The Architect routes to the correct Tier 2 skill

### Tier 2 — Domain Orchestrators
- `/storefront-add-module` — new bounded context / module
- (future: storefront-add-entity, storefront-cross-module, storefront-jte-htmx)

### Tier 3 — Building Blocks (invoked by Tier 2, or directly for targeted changes)
- `/storefront-schema` — Flyway migrations + jOOQ code generation + mappers
- `/storefront-domain-layer` — Value objects, aggregates, events, repository interfaces
- `/storefront-wiring-layer` — jOOQ repository impls, application services, controllers, DTOs, templates

### Meta
- `/storefront-suggest-improvement` — auto-invoked after task completion, proposes skill updates when patterns diverge from rules

---
name: storefront-add-module
description: Use when creating a new Spring Modulith module (bounded context) in the storefront project. Orchestrates schema, domain, and wiring layer creation with full DDD rules.
argument-hint: "[module-name]"
---

# Add New Module

Creates a complete new bounded context as a Spring Modulith module. Delegates to building-block skills in order.

## Inputs

- `$ARGUMENTS` — the module name in lowercase (e.g., `orders`, `shipping`, `pricing`)

## Aggregate Design Rules (enforce for every new module)

1. **Every module MUST define:**
   - At least one aggregate root
   - A public API interface at module root: `com.storefront.<module>/<ModuleName>Api.java`
   - Package structure:
     ```
     com.storefront.<module>/
     ├── <ModuleName>Api.java          # Public API interface (ONLY cross-module entry point)
     ├── interfaces/                   # Controllers, DTOs (package-private)
     ├── application/                  # Use-case services (package-private impls)
     ├── domain/
     │   ├── model/                    # Entities, VOs, repo interfaces, events, exceptions
     │   └── shared/                   # Base classes if needed
     └── infrastructure/              # jOOQ repos, config (package-private)
     ```

2. **Aggregate boundaries:**
   - One aggregate = one transactional boundary
   - Reference other aggregates by ID (value object), NEVER by direct object reference
   - Cross-module references: ALWAYS by ID value object

3. **Domain events:**
   - Define events for state changes other modules care about
   - Events are immutable Java records in `domain/model/`
   - Naming: past tense (`OrderPlaced`, `ShipmentDispatched`)
   - Events implement `com.storefront.shared.DomainEvent`
   - Publish via `ApplicationEventPublisher`
   - Listen via `@ApplicationModuleListener`

## Orchestration Sequence

Execute these skills in order. Each must complete before the next begins.

### Phase 1: Schema
Invoke `/storefront-schema` with the module name.
- Creates Flyway migration with tables for the module
- Runs `./gradlew generateJooqClasses` to generate jOOQ classes
- Invoke `/storefront-git-workflow schema(<module>): Add <module> database tables`

### Phase 2: Domain Layer
Invoke `/storefront-domain-layer` with the module name.
- Creates value objects (IDs), aggregate root, domain events, repository interface
- Invoke `/storefront-git-workflow domain(<module>): Add <Module> aggregate, IDs, and domain events`

### Phase 3: Wiring Layer
Invoke `/storefront-wiring-layer` with the module name.
- Creates jOOQ repository implementation, application service, public API impl, controller, DTOs
- Invoke `/storefront-git-workflow wiring(<module>): Add <Module> repository, service, and controller`

### Phase 4: Module Verification
After all phases:

1. **Spring Modulith test** — verify module boundaries:
   ```java
   // src/test/java/com/storefront/<module>/<ModuleName>ModuleTest.java
   @SpringBootTest
   class <ModuleName>ModuleTest extends BaseIntegrationTest {
       @Test
       void moduleIsValid() {
           ApplicationModules.of(StorefrontApplication.class).verify();
       }
   }
   ```

2. **Build passes:**
   ```bash
   ./gradlew build
   ```

3. **Invoke `/storefront-git-workflow test(<module>): Add Spring Modulith verification test`**

## Checklist Before Marking Complete

- [ ] Module has a public API interface at root
- [ ] All IDs are value objects (not raw UUID/String/Long)
- [ ] Domain model has NO Spring/jOOQ imports
- [ ] Repository interface is in domain/model/, implementation in infrastructure/
- [ ] Application service is package-private, implements public interface
- [ ] Controller is package-private, handles HTMX fragment vs full-page
- [ ] Domain events defined for state changes other modules need
- [ ] Spring Modulith verification passes
- [ ] `./gradlew build` passes

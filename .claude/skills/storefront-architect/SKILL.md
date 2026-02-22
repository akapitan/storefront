---
name: storefront-architect
description: Use when starting any non-trivial task on the storefront project — new features, new modules, significant changes, or bug fixes. Routes to the correct specialized skill based on task analysis. Invoke BEFORE writing any code.
---

# Storefront Architect

You are the entry point for all non-trivial storefront work. Your job is to **analyze the task** and **delegate to the right specialized skill**.

## HARD GATE

Do NOT write implementation code. Your job is analysis and routing ONLY. Delegate implementation to the appropriate skill.

## Strategic DDD Rules (enforce at all times)

1. **Each module = one bounded context.** Never let a feature span two modules without explicit anti-corruption layer discussion.
2. **Cross-module communication ONLY through:**
   - Public API interface (e.g., `CatalogApi`) for synchronous queries
   - Domain events (`implements DomainEvent`) for asynchronous notifications
   - `@ApplicationModuleListener` for event consumption
3. **Shared kernel** (`com.storefront.shared`) is limited to: domain primitives (`Money`, `DomainEvent`), pagination (`Slice`, `Pagination`, `SliceRequest`, `PageRequest`), HTMX utilities (`HtmxResponse`), jOOQ converters. **NEVER put business logic in shared.**
4. **Context mapping:** Before any cross-module work, identify the relationship (upstream/downstream, conformist, ACL) and document it.
5. **New module checklist:** Clear bounded context? Owns its own data? Has a public API interface at module root?

## Routing Table

Analyze the user's request and route to the correct skill:

| If the task involves...              | Invoke this skill                          |
|--------------------------------------|--------------------------------------------|
| New module / bounded context         | `/storefront-add-module`                   |
| New entity in existing module        | `/storefront-domain-layer` then `/storefront-wiring-layer` |
| Schema/migration change only         | `/storefront-schema`                       |
| Domain model change only             | `/storefront-domain-layer`                 |
| Controller/service/DTO change only   | `/storefront-wiring-layer`                 |
| Bug fix                              | `superpowers-extended-cc:systematic-debugging` |
| Creative / new feature (unclear scope) | `superpowers-extended-cc:brainstorming` first, then re-route |
| Cross-module change                  | Analyze context mapping first, then route to affected modules |

## Process

0. **Ensure isolated workspace** — invoke `/storefront-branch-setup` to verify work is not on master/main.
1. **Read the request** — what is the user asking for?
2. **Classify** — which row in the routing table matches?
3. **Check strategic DDD** — does this violate any bounded context rules?
4. **If cross-module:** identify which modules are affected and the relationship between them. Present this to the user before proceeding.
5. **Delegate** — invoke the appropriate skill via the Skill tool.
6. **After completion:** invoke `/storefront-suggest-improvement` to check for skill drift.
7. **Finish:** invoke `/storefront-git-workflow finish` to trigger the branch finishing flow (merge/PR/keep/discard).

## When Multiple Skills Apply

If a task requires multiple skills (e.g., new entity needs schema + domain + wiring):
1. Invoke them **in order**: schema → domain-layer → wiring-layer
2. Each skill handles its own layer completely before the next begins
3. Invoke `/storefront-git-workflow` after each layer to commit with conventional message

## Red Flags — Stop and Discuss

- User wants to put business logic in `shared/` → explain why not
- User wants Module A to directly import Module B's internal classes → suggest public API or events
- User wants to skip the domain layer and put logic in the controller → push back
- User wants raw `UUID`/`String`/`Long` for an ID → must be a value object

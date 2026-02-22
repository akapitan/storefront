# Agent-Enhanced Skill System Design

## Problem

The existing three-tier skill system encodes domain knowledge and conventions, but skills run sequentially in the main conversation. This means:
- No context isolation — all skill output accumulates in one conversation window
- No autonomy — user must approve each skill transition manually
- No end-to-end automation — feature work stops short of PR creation

## Solution

Enhance the skill system with **sub-agent dispatching via the Task tool**. The Architect skill becomes an active orchestrator that presents a plan, gets approval, dispatches isolated agents for each phase, verifies the result, and opens a PR.

Skills serve as **knowledge files** (rules, patterns, checklists). Agents serve as **execution vehicles** (isolated context, autonomous operation). The hybrid model supports both:
- **Direct invocation**: user types `/storefront-schema orders` → runs as forked sub-agent via `context: fork`
- **Orchestrated invocation**: Architect dispatches Task tool agents with skill content as prompt

## Skill Inventory (10 skills)

### Tier 1 — Orchestrator
| Skill | Purpose |
|-------|---------|
| `storefront-architect` | Analyzes tasks, presents plan, dispatches agents, verifies, opens PR |

### Tier 2 — Domain Orchestrators
| Skill | Purpose |
|-------|---------|
| `storefront-add-module` | Orchestrates new module creation across all Tier 3 skills |

### Tier 3 — Building Blocks (5 skills)
| Skill | Hexagonal Layer | Covers |
|-------|----------------|--------|
| `storefront-schema` | Database | Flyway migration, jOOQ generation |
| `storefront-domain-layer` | Domain | VOs, aggregates, events, repo interfaces, exceptions |
| `storefront-repository` | Infrastructure | jOOQ repo implementation, mappers, caching |
| `storefront-application` | Application | Service impl, public API interface, event publishing |
| `storefront-presentation` | Interfaces | Controllers, DTOs, JTE templates, HTMX handling |

### Meta
| Skill | Purpose |
|-------|---------|
| `storefront-suggest-improvement` | Auto-proposes skill updates after task completion |

## Orchestration Flow

```
User: "Add an orders module"
│
├─ 1. ANALYZE — Architect reads request, classifies task
├─ 2. PLAN — Reads relevant skill files, builds execution plan
├─ 3. PRESENT — Shows plan to user, waits for approval
│
├─ 4. EXECUTE (sequential phases):
│      Phase 1: Task(schema agent)        → DB tables, jOOQ classes
│      Phase 2: Task(domain-layer agent)  → Pure domain model
│      Phase 3: Task(repository agent)    → jOOQ repo impl
│      Phase 4: Task(application agent)   → Service + API
│      Phase 5: Task(presentation agent)  → Controller + templates
│
├─ 5. VERIFY — ./gradlew build && ./gradlew test
├─ 6. PR — gh pr create
└─ 7. META — Task(suggest-improvement agent) → skill drift check
```

### Agent Dispatch Prompt Template

Each agent receives a focused prompt:

```
You are a specialized agent working on the storefront project.

## Your Task
[specific task description]

## Module Context
- Module name: [name]
- Package: com.storefront.[name]
- [output from previous phases if applicable]

## Rules (follow exactly)
[full contents of the relevant SKILL.md file]

## Working Directory
[project path]

## When Done
- Commit your changes with a descriptive message
- Report what files you created/modified
- Report any issues or decisions you made
```

### Execution Model

| Invocation | How it runs | Context |
|------------|------------|---------|
| User: `/storefront-schema orders` | Forked sub-agent via `context: fork` | Isolated, focused |
| Architect dispatches schema phase | Task tool agent (general-purpose) | Isolated, receives skill content as prompt |

## Changes to Existing Skills

### Modified Skills

**storefront-architect (rewrite):**
- Add orchestration mode with plan presentation
- Add agent dispatch logic using Task tool
- Add post-execution verification and PR creation
- Add suggest-improvement integration
- Keep all Strategic DDD rules unchanged

**storefront-add-module (update):**
- Reference 5 Tier 3 skills instead of 3
- Update orchestration sequence

**storefront-schema (update frontmatter):**
- Add `context: fork` and `agent: general-purpose`

**storefront-domain-layer (update frontmatter):**
- Add `context: fork` and `agent: general-purpose`

**storefront-suggest-improvement (update frontmatter):**
- Add `context: fork` and `agent: general-purpose`
- Integrate as final phase of orchestration

### Deleted Skills

**storefront-wiring-layer** — replaced by three new skills

### New Skills

**storefront-repository:**
- Content extracted from wiring-layer's infrastructure section
- jOOQ repo implementation, mapper methods, caching annotations, read/write splitting
- Testing: integration tests with Testcontainers

**storefront-application:**
- Content extracted from wiring-layer's application section
- Service implementation, public API interface, transaction boundaries, event publishing
- Testing: mock repository, test orchestration logic

**storefront-presentation:**
- Content extracted from wiring-layer's interfaces section
- Controllers with HTMX handling, DTOs, JTE templates (page + fragment)
- Testing: MockMvc for both HTMX and full-page responses

## Architect Skill Design

### Plan Presentation Format

```
## Execution Plan

**Task:** Add orders module
**Phases:**

1. Schema — Create orders tables, generate jOOQ classes
   Files: V12__create_orders_tables.sql
   Agent: storefront-schema

2. Domain — OrderId, Order aggregate, OrderPlaced event, OrderRepository interface
   Files: domain/model/OrderId.java, Order.java, OrderPlaced.java, OrderRepository.java
   Agent: storefront-domain-layer

3. Repository — JooqOrderRepository with read/write splitting
   Files: infrastructure/JooqOrderRepository.java
   Agent: storefront-repository

4. Application — OrderService implements OrderApi
   Files: OrderApi.java, application/OrderService.java
   Agent: storefront-application

5. Presentation — OrderController, DTOs, JTE templates
   Files: interfaces/OrderController.java, templates/jte/orders/
   Agent: storefront-presentation

**After all phases:** build + test → PR

Approve? [Yes / Modify / Cancel]
```

### Post-Execution

```markdown
## Verification
1. Run: ./gradlew build
2. Run: ./gradlew test
3. If either fails: report errors, attempt fix, re-verify

## PR Creation
1. Branch: feature/<module-name> or feature/<description>
2. Push with -u flag
3. gh pr create with:
   - Title: descriptive, under 70 chars
   - Body: summary of phases completed, files created, test results
```

## DDD Rules

All DDD rules from the original design (docs/plans/2026-02-22-skill-system-design.md) carry forward unchanged. They are distributed across the Tier 3 skills:

- **Strategic DDD** → storefront-architect
- **Aggregate design** → storefront-add-module
- **Schema conventions** → storefront-schema
- **Tactical DDD (domain purity)** → storefront-domain-layer
- **Repository patterns** → storefront-repository
- **Application service patterns** → storefront-application
- **Presentation patterns** → storefront-presentation

## File Changes Summary

| Action | File |
|--------|------|
| Rewrite | `.claude/skills/storefront-architect/SKILL.md` |
| Update | `.claude/skills/storefront-add-module/SKILL.md` |
| Update frontmatter | `.claude/skills/storefront-schema/SKILL.md` |
| Update frontmatter | `.claude/skills/storefront-domain-layer/SKILL.md` |
| Delete | `.claude/skills/storefront-wiring-layer/SKILL.md` |
| Create | `.claude/skills/storefront-repository/SKILL.md` |
| Create | `.claude/skills/storefront-application/SKILL.md` |
| Create | `.claude/skills/storefront-presentation/SKILL.md` |
| Update frontmatter | `.claude/skills/storefront-suggest-improvement/SKILL.md` |
| Update | `CLAUDE.md` (skill system section) |

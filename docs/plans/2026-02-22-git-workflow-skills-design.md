# Git Workflow Skills Design

## Problem

The storefront skill system says "commit after this phase" in multiple places but never specifies how. There's no commit message convention, no staging discipline, no branch setup guidance, and no wiring to the existing `finishing-a-development-branch` skill for PR creation. This leaves a gap between "code written" and "code shipped."

## Solution

Two new Tier 3 skills:

1. **`storefront-branch-setup`** — ensures an isolated worktree before work begins
2. **`storefront-git-workflow`** — handles per-phase commits and delegates to the finishing skill at the end

Plus updates to `storefront-architect`, `storefront-add-module`, and `CLAUDE.md` to integrate them.

## Architecture

### Updated Flow

```
User: "Add an orders module"
  → Architect:
      0. /storefront-branch-setup → ensures worktree
      1. Routes to /storefront-add-module
         → Phase 1: /storefront-schema → /storefront-git-workflow schema(orders)
         → Phase 2: /storefront-domain-layer → /storefront-git-workflow domain(orders)
         → Phase 3: /storefront-wiring-layer → /storefront-git-workflow wiring(orders)
         → Phase 4: verification → /storefront-git-workflow test(orders)
      2. /storefront-suggest-improvement
      3. /storefront-git-workflow finish → finishing-a-development-branch
```

### Skill: `storefront-branch-setup`

**Purpose:** Ensure isolated workspace before non-trivial storefront work.

**Behavior:**
- If already on a feature branch or in a worktree → report "Already in isolated workspace" and return
- If on `master`/`main` → delegate to `superpowers:using-git-worktrees` with branch naming convention `storefront/<slug>` (e.g., `storefront/add-orders-module`)
- After worktree is ready, run `./gradlew build` to verify clean baseline

**Invoked by:** `storefront-architect` (new Step 0, before routing)

### Skill: `storefront-git-workflow`

**Purpose:** Handle per-phase commits and trigger the finishing flow.

**Two modes:**

**Mode 1 — Phase commit** (`$ARGUMENTS` = `<type>(<module>): <description>`):
1. `git status` to identify changed files
2. Stage files by explicit path (never `git add -A`)
3. Commit with conventional message format
4. Report what was committed

**Mode 2 — Finish** (`$ARGUMENTS` = `finish`):
1. Verify all changes are committed (no dirty working tree)
2. Invoke `superpowers:finishing-a-development-branch`

**Invoked by:** `storefront-add-module` after each phase, `storefront-architect` after all work completes.

### Commit Message Convention

```
<type>(<module>): <short description>

<optional body — what and why, not how>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

**Types:**
- `schema` — Flyway migrations, jOOQ regeneration
- `domain` — Value objects, aggregates, events, repository interfaces
- `wiring` — Repository impls, services, controllers, DTOs, templates
- `test` — Test classes, verification fixes
- `skill` — Skill file changes
- `fix` — Bug fixes
- `refactor` — Code restructuring without behavior change

**Examples:**
- `schema(orders): Add orders and order_items tables`
- `domain(orders): Add Order aggregate, OrderId, and domain events`
- `wiring(orders): Add JooqOrderRepository, OrderService, and OrderController`
- `test(orders): Add Spring Modulith verification test`

### Integration Changes

**`storefront-architect`:**
- New Step 0 in Process: "Invoke `/storefront-branch-setup` to ensure isolated workspace"
- Update Step 6: After suggest-improvement, invoke `/storefront-git-workflow finish`

**`storefront-add-module`:**
- Phase 1: Replace "Commit after this phase" → "Invoke `/storefront-git-workflow` with type `schema`"
- Phase 2: Replace "Commit after this phase" → "Invoke `/storefront-git-workflow` with type `domain`"
- Phase 3: Replace "Commit after this phase" → "Invoke `/storefront-git-workflow` with type `wiring`"
- Phase 4: Replace "Commit the test and any fixes" → "Invoke `/storefront-git-workflow` with type `test`"

**`CLAUDE.md`:**
- Add both new skills to the Tier 3 section

### What These Skills Do NOT Do

- No rebasing, squashing, or history rewriting
- No force pushing
- No branch deletion (finishing skill handles that)
- No CI/CD integration

## File Inventory

| File | Action |
|------|--------|
| `.claude/skills/storefront-branch-setup/SKILL.md` | Create |
| `.claude/skills/storefront-git-workflow/SKILL.md` | Create |
| `.claude/skills/storefront-architect/SKILL.md` | Modify (add Step 0 + update Step 6) |
| `.claude/skills/storefront-add-module/SKILL.md` | Modify (replace commit instructions) |
| `CLAUDE.md` | Modify (add 2 skills to Tier 3 section) |

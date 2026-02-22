# Git Workflow Skills Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add two new skills (`storefront-branch-setup` and `storefront-git-workflow`) and wire them into the existing skill system so commits and PR creation happen through a defined, consistent workflow.

**Architecture:** Two new Tier 3 skills in `.claude/skills/`. `storefront-branch-setup` ensures isolated worktree before work begins. `storefront-git-workflow` handles per-phase commits with conventional messages and delegates to `finishing-a-development-branch` at the end. Existing skills updated to invoke these at the right points.

**Tech Stack:** Claude Code skills (YAML frontmatter + markdown), project-level `.claude/skills/` directory

**Design doc:** `docs/plans/2026-02-22-git-workflow-skills-design.md`

---

### Task 0: Create skill directories

**Files:**
- Create: `.claude/skills/storefront-branch-setup/SKILL.md` (placeholder)
- Create: `.claude/skills/storefront-git-workflow/SKILL.md` (placeholder)

**Step 1: Create directories and placeholders**

```bash
mkdir -p .claude/skills/storefront-branch-setup
mkdir -p .claude/skills/storefront-git-workflow
touch .claude/skills/storefront-branch-setup/SKILL.md
touch .claude/skills/storefront-git-workflow/SKILL.md
```

**Step 2: Verify**

```bash
ls .claude/skills/storefront-branch-setup/SKILL.md
ls .claude/skills/storefront-git-workflow/SKILL.md
```

**Step 3: Commit**

```bash
git add .claude/skills/storefront-branch-setup/ .claude/skills/storefront-git-workflow/
git commit -m "skill(git-workflow): Add directory structure for branch-setup and git-workflow skills"
```

---

### Task 1: Write storefront-branch-setup skill

**Files:**
- Create: `.claude/skills/storefront-branch-setup/SKILL.md`

**Step 1: Write the skill file**

Write the following to `.claude/skills/storefront-branch-setup/SKILL.md`:

````markdown
---
name: storefront-branch-setup
description: Use when starting any non-trivial storefront task to ensure work happens in an isolated worktree, not on master/main. Invoked by the Architect skill before routing.
argument-hint: "[feature-slug]"
---

# Branch Setup — Isolated Workspace

Ensures all non-trivial storefront work happens in an isolated git worktree, never directly on master/main.

## Guard Check

Before doing anything, check if isolation is already in place:

```bash
git branch --show-current
```

**If the branch is NOT `master` or `main`** → already isolated. Report:
> "Already on branch `<branch-name>`. Proceeding with current workspace."

Return immediately. Skip all remaining steps.

**If the branch IS `master` or `main`** → continue to worktree setup.

## Worktree Setup

### Step 1: Derive branch name

Use the `$ARGUMENTS` slug if provided. Otherwise derive from the task description.

**Branch naming convention:** `storefront/<slug>`
- Examples: `storefront/add-orders-module`, `storefront/fix-search-pagination`, `storefront/cart-checkout-flow`
- Slugs: lowercase, hyphens, no underscores, max 50 chars

### Step 2: Create worktree

Delegate to `superpowers:using-git-worktrees` with the derived branch name.

If `superpowers:using-git-worktrees` is not available, create manually:

```bash
git worktree add .claude/worktrees/<slug> -b storefront/<slug>
cd .claude/worktrees/<slug>
```

### Step 3: Verify clean baseline

```bash
./gradlew build
```

If the build fails, STOP and report the failure. Do not proceed with a broken baseline.

### Step 4: Report

> "Isolated workspace ready on branch `storefront/<slug>`. Build passes. Ready to proceed."

## Safety Rules

- **NEVER start non-trivial work on master/main** — always create a worktree first
- **NEVER force-push** to any branch
- **NEVER delete branches** — that's handled by `finishing-a-development-branch`
- If the worktree already exists for this slug, switch to it instead of creating a new one
````

**Step 2: Verify frontmatter**

```bash
head -4 .claude/skills/storefront-branch-setup/SKILL.md
```

Expected: `---` on line 1, `name:` on line 2, `description:` on line 3.

**Step 3: Commit**

```bash
git add .claude/skills/storefront-branch-setup/SKILL.md
git commit -m "skill(git-workflow): Add storefront-branch-setup skill"
```

---

### Task 2: Write storefront-git-workflow skill

**Files:**
- Create: `.claude/skills/storefront-git-workflow/SKILL.md`

**Step 1: Write the skill file**

Write the following to `.claude/skills/storefront-git-workflow/SKILL.md`:

````markdown
---
name: storefront-git-workflow
description: Use when committing after a completed phase (schema, domain, wiring, test) or when finishing all work on a feature branch. Handles staging, conventional commit messages, and delegates to the finishing skill for PR creation.
argument-hint: "<type>(<module>): <description>  OR  finish"
---

# Git Workflow — Phase Commits + Finishing

Handles two workflows: committing after a phase completes, and finishing a feature branch.

## Mode Detection

Check `$ARGUMENTS`:
- If `$ARGUMENTS` = `finish` → **Finish mode** (go to Finish section)
- Otherwise → **Phase commit mode** (go to Phase Commit section)

---

## Phase Commit

### Step 1: Check for changes

```bash
git status --short
```

If no changes → report "No changes to commit" and return.

### Step 2: Review changed files

List the changed files and verify they belong to this phase. Flag any unexpected files (e.g., domain files in a schema commit).

### Step 3: Stage files by explicit path

```bash
git add path/to/file1 path/to/file2
```

**NEVER use `git add -A` or `git add .`** — always stage by explicit path to avoid accidentally committing sensitive files, build artifacts, or unrelated changes.

### Step 4: Commit with conventional message

```bash
git commit -m "$(cat <<'EOF'
<type>(<module>): <description>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

Use the `$ARGUMENTS` value as the first line of the commit message.

### Step 5: Report

> "Committed: `<type>(<module>): <description>` — N files changed."

## Commit Message Convention

**Format:**
```
<type>(<module>): <short description>

<optional body — what and why, not how>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

**Types:**

| Type | When to use |
|------|------------|
| `schema` | Flyway migrations, jOOQ regeneration |
| `domain` | Value objects, aggregates, events, repository interfaces |
| `wiring` | Repository impls, services, controllers, DTOs, templates |
| `test` | Test classes, verification fixes |
| `skill` | Skill file changes |
| `fix` | Bug fixes |
| `refactor` | Code restructuring without behavior change |

**Examples:**
- `schema(orders): Add orders and order_items tables`
- `domain(orders): Add Order aggregate, OrderId, and domain events`
- `wiring(orders): Add JooqOrderRepository, OrderService, and OrderController`
- `test(orders): Add Spring Modulith verification test`

---

## Finish

Triggered when all work on a feature branch is complete.

### Step 1: Verify clean working tree

```bash
git status --short
```

If there are uncommitted changes → STOP. Report:
> "Working tree has uncommitted changes. Commit or discard them before finishing."

### Step 2: Delegate to finishing skill

Invoke `superpowers:finishing-a-development-branch`.

This skill handles:
- Test verification
- Presenting 4 options (merge locally, create PR, keep as-is, discard)
- Executing the chosen option
- Worktree cleanup

**Do NOT duplicate any of this logic.** Just invoke the skill and let it run.

## Safety Rules

- **NEVER use `git add -A` or `git add .`** — always stage by explicit path
- **NEVER force-push**
- **NEVER amend commits** unless explicitly asked
- **NEVER skip pre-commit hooks** (`--no-verify`)
- If `git status` shows unexpected files, ask the user before staging
````

**Step 2: Verify frontmatter**

```bash
head -4 .claude/skills/storefront-git-workflow/SKILL.md
```

Expected: `---` on line 1, `name:` on line 2, `description:` on line 3.

**Step 3: Commit**

```bash
git add .claude/skills/storefront-git-workflow/SKILL.md
git commit -m "skill(git-workflow): Add storefront-git-workflow skill"
```

---

### Task 3: Update storefront-architect skill

**Files:**
- Modify: `.claude/skills/storefront-architect/SKILL.md`

**Step 1: Add Step 0 to Process section**

In the `## Process` section, insert a new step before the existing step 1:

**Current:**
```markdown
## Process

1. **Read the request** — what is the user asking for?
```

**Replace with:**
```markdown
## Process

0. **Ensure isolated workspace** — invoke `/storefront-branch-setup` to verify work is not on master/main.
1. **Read the request** — what is the user asking for?
```

**Step 2: Update step 6 (now step 7) to include finishing flow**

**Current:**
```markdown
6. **After completion:** invoke `/storefront-suggest-improvement` to check for skill drift.
```

**Replace with:**
```markdown
6. **After completion:** invoke `/storefront-suggest-improvement` to check for skill drift.
7. **Finish:** invoke `/storefront-git-workflow finish` to trigger the branch finishing flow (merge/PR/keep/discard).
```

**Step 3: Update "When Multiple Skills Apply" section**

**Current:**
```markdown
3. Commit after each layer if the changes are independently valid
```

**Replace with:**
```markdown
3. Invoke `/storefront-git-workflow` after each layer to commit with conventional message
```

**Step 4: Verify the file reads correctly**

```bash
head -50 .claude/skills/storefront-architect/SKILL.md
```

**Step 5: Commit**

```bash
git add .claude/skills/storefront-architect/SKILL.md
git commit -m "skill(git-workflow): Wire branch-setup and git-workflow into architect skill"
```

---

### Task 4: Update storefront-add-module skill

**Files:**
- Modify: `.claude/skills/storefront-add-module/SKILL.md`

**Step 1: Update Phase 1 (Schema)**

**Current:**
```markdown
### Phase 1: Schema
Invoke `/storefront-schema` with the module name.
- Creates Flyway migration with tables for the module
- Runs `./gradlew generateJooqClasses` to generate jOOQ classes
- Commit after this phase
```

**Replace with:**
```markdown
### Phase 1: Schema
Invoke `/storefront-schema` with the module name.
- Creates Flyway migration with tables for the module
- Runs `./gradlew generateJooqClasses` to generate jOOQ classes
- Invoke `/storefront-git-workflow schema(<module>): Add <module> database tables`
```

**Step 2: Update Phase 2 (Domain Layer)**

**Current:**
```markdown
### Phase 2: Domain Layer
Invoke `/storefront-domain-layer` with the module name.
- Creates value objects (IDs), aggregate root, domain events, repository interface
- Commit after this phase
```

**Replace with:**
```markdown
### Phase 2: Domain Layer
Invoke `/storefront-domain-layer` with the module name.
- Creates value objects (IDs), aggregate root, domain events, repository interface
- Invoke `/storefront-git-workflow domain(<module>): Add <Module> aggregate, IDs, and domain events`
```

**Step 3: Update Phase 3 (Wiring Layer)**

**Current:**
```markdown
### Phase 3: Wiring Layer
Invoke `/storefront-wiring-layer` with the module name.
- Creates jOOQ repository implementation, application service, public API impl, controller, DTOs
- Commit after this phase
```

**Replace with:**
```markdown
### Phase 3: Wiring Layer
Invoke `/storefront-wiring-layer` with the module name.
- Creates jOOQ repository implementation, application service, public API impl, controller, DTOs
- Invoke `/storefront-git-workflow wiring(<module>): Add <Module> repository, service, and controller`
```

**Step 4: Update Phase 4 (Module Verification)**

**Current (the last line of Phase 4):**
```markdown
3. **Commit the test and any fixes**
```

**Replace with:**
```markdown
3. **Invoke `/storefront-git-workflow test(<module>): Add Spring Modulith verification test`**
```

**Step 5: Verify the file reads correctly**

```bash
grep -n "storefront-git-workflow" .claude/skills/storefront-add-module/SKILL.md
```

Expected: 4 references (one per phase).

**Step 6: Commit**

```bash
git add .claude/skills/storefront-add-module/SKILL.md
git commit -m "skill(git-workflow): Wire git-workflow into add-module orchestration phases"
```

---

### Task 5: Update CLAUDE.md with new skills

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Add the two new skills to the Tier 3 section**

**Current:**
```markdown
### Tier 3 — Building Blocks (invoked by Tier 2, or directly for targeted changes)
- `/storefront-schema` — Flyway migrations + jOOQ code generation + mappers
- `/storefront-domain-layer` — Value objects, aggregates, events, repository interfaces
- `/storefront-wiring-layer` — jOOQ repository impls, application services, controllers, DTOs, templates
```

**Replace with:**
```markdown
### Tier 3 — Building Blocks (invoked by Tier 2, or directly for targeted changes)
- `/storefront-schema` — Flyway migrations + jOOQ code generation + mappers
- `/storefront-domain-layer` — Value objects, aggregates, events, repository interfaces
- `/storefront-wiring-layer` — jOOQ repository impls, application services, controllers, DTOs, templates
- `/storefront-branch-setup` — ensures isolated worktree before non-trivial work begins
- `/storefront-git-workflow` — per-phase conventional commits + finishing flow (merge/PR/keep/discard)
```

**Step 2: Verify**

```bash
grep "storefront-" CLAUDE.md
```

Expected: all 8 skill names appear (6 existing + 2 new).

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "skill(git-workflow): Add branch-setup and git-workflow to CLAUDE.md skill listing"
```

---

### Task 6: Verify the complete updated skill system

**Step 1: List all skills**

```bash
find .claude/skills -name "SKILL.md" | sort
```

Expected: 8 skill files.

**Step 2: Verify each skill has valid frontmatter**

```bash
for f in .claude/skills/*/SKILL.md; do
  echo "=== $f ==="
  head -5 "$f"
  echo ""
done
```

**Step 3: Verify architect skill has the new steps**

```bash
grep -n "branch-setup\|git-workflow\|Step 0\|Finish" .claude/skills/storefront-architect/SKILL.md
```

Expected: references to both new skills.

**Step 4: Verify add-module has git-workflow references in all 4 phases**

```bash
grep -c "storefront-git-workflow" .claude/skills/storefront-add-module/SKILL.md
```

Expected: `4`

**Step 5: Verify CLAUDE.md references all skills**

```bash
grep "storefront-" CLAUDE.md | wc -l
```

Expected: at least 8 lines.

**Step 6: Run project build**

```bash
./gradlew build
```

Expected: BUILD SUCCESSFUL

**Step 7: Final commit if any fixes were needed**

```bash
git status
# If clean, nothing to do
# If changes, commit fixes
```

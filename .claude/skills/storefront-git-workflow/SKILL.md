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

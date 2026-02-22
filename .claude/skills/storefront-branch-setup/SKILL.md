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

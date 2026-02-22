---
name: storefront-suggest-improvement
description: Use after completing any implementation task to check for skill drift — compares recent work against skill rules and proposes updates. Auto-invoked by the Architect skill after task completion.
---

# Suggest Skill Improvements

Proactively reviews recent work and proposes updates to skill files when conventions evolve.

## When This Runs

- Automatically after every completed Tier 2 orchestration (invoked by Architect)
- On-demand when the user asks "what should we improve in our skills?"

## Process

### Step 1: Gather Evidence

Read the files that were created or modified in the current session:

```bash
git diff --name-only HEAD~3..HEAD
```

For each changed file, read it and note the patterns used.

### Step 2: Compare Against Skills

Read each relevant skill file:
- `.claude/skills/storefront-schema/SKILL.md`
- `.claude/skills/storefront-domain-layer/SKILL.md`
- `.claude/skills/storefront-wiring-layer/SKILL.md`
- `.claude/skills/storefront-add-module/SKILL.md`
- `.claude/skills/storefront-architect/SKILL.md`

For each skill, check:
1. **Gaps:** Did we follow a pattern NOT covered by the skill?
2. **Drift:** Did we deviate from a rule in the skill? Was the deviation intentional?
3. **Stale rules:** Are any rules consistently overridden?

### Step 3: Present Proposals

For each finding, present a structured proposal:

```
## Skill Improvement Proposal

**Skill:** storefront-domain-layer
**Section:** Value object rules
**Type:** GAP (new pattern not codified) | DRIFT (rule doesn't match practice) | STALE (rule consistently overridden)

**Current rule:** "Value objects are immutable (Java records preferred)"

**Observed pattern:** In the last 3 entities, we've been adding validation in
static factory methods with descriptive error messages in all value objects.

**Proposed update:**
> Value objects are immutable Java records. Provide a `public static` factory method
> that validates invariants and throws `IllegalArgumentException` with a descriptive
> message. The canonical constructor should also validate.

**Confidence:** HIGH (seen in 3/3 recent VOs)
**Evidence:** `OrderId.java:12`, `Quantity.java:5`, `ShippingAddress.java:8`
```

### Step 4: Apply Approved Changes

For each proposal the user approves:
1. Edit the skill file with the updated rule
2. Commit the skill change alongside the implementation work

## Guardrails

- **Never modify skills without user approval** — always present proposals first
- **Confidence levels:**
  - HIGH: pattern seen in 3+ instances
  - MEDIUM: pattern seen in 2 instances
  - LOW: pattern seen once (mention but don't strongly recommend)
- **Can propose deletions** for rules that are consistently overridden
- **Keep proposals concise** — one change per proposal, not rewrites
- **If no improvements found:** Say "No skill drift detected" and move on

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

## Process: Setup → Analyze → Plan → Dispatch → Verify → PR → Finish

### Step 0: Ensure Isolated Workspace

Invoke `/storefront-branch-setup` to verify work is not on master/main. If already on a feature branch, this returns immediately.

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

```
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
```

Wait for user approval before proceeding.

### Step 3: Dispatch Agents

For each phase, dispatch a Task tool agent:

```
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
```

**Dispatch rules:**
- Read the sub-skill's SKILL.md file and include its FULL content in the agent prompt
- Pass context from previous phases (file paths created, decisions made)
- Phases run sequentially — each depends on the previous
- Review each agent's result before dispatching the next
- If an agent fails, stop and report — do not continue blindly

### Step 4: Verify

After all agents complete:

```bash
./gradlew build
./gradlew test
```

If either fails:
1. Read the error output
2. Attempt to fix the issue
3. Re-run verification
4. If unable to fix after 2 attempts, report the error to the user

### Step 5: Open PR

```bash
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
```

### Step 6: Suggest Improvements

After PR is created, dispatch the meta-skill:

```
Read .claude/skills/storefront-suggest-improvement/SKILL.md
Dispatch as Task tool agent to review the work for skill drift
Present any proposals to the user
```

### Step 7: Finish

Invoke `/storefront-git-workflow finish` to trigger the branch finishing flow (merge/PR/keep/discard).

## Red Flags — Stop and Discuss

- User wants to put business logic in `shared/` → explain why not
- User wants Module A to directly import Module B's internal classes → suggest public API or events
- User wants to skip the domain layer and put logic in the controller → push back
- User wants raw `UUID`/`String`/`Long` for an ID → must be a value object
- Agent failed and the error looks structural → stop, don't retry blindly

## When NOT to Orchestrate

For simple, single-skill tasks (e.g., "add a column to the orders table"), you don't need the full orchestration flow. Just invoke the relevant skill directly. Use orchestration for multi-skill work.

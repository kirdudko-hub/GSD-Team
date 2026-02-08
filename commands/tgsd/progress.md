---
name: tgsd:progress
description: Check project progress and route to team GSD commands
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
---

<objective>
Check project progress, summarize recent work, and route to the next Team GSD action.

Identical to /gsd:progress but all command suggestions use `/tgsd:*` instead of `/gsd:*`.
</objective>

<process>

<step name="verify">
**Verify planning structure exists:**

```bash
test -d .planning && echo "exists" || echo "missing"
```

If no `.planning/`: suggest `/gsd:new-project`.
If ROADMAP.md missing but PROJECT.md exists: Route F (between milestones).
</step>

<step name="load">
**Load full project context:**

- Read `.planning/STATE.md`
- Read `.planning/ROADMAP.md`
- Read `.planning/PROJECT.md`
- Read `.planning/config.json`
</step>

<step name="recent">
**Gather recent work:**

Find 2-3 most recent SUMMARY.md files. Extract what was accomplished.
</step>

<step name="position">
**Parse current position:**

- From STATE.md: current phase, plan, status
- Calculate: total plans, completed, remaining
- Note blockers/concerns
- Count pending todos
- Check active debug sessions
</step>

<step name="report">
**Present status report:**

```
# [Project Name]

**Progress:** [progress bar] X/Y plans complete
**Profile:** [quality/balanced/budget]
**Mode:** Team GSD

## Recent Work
- [summary items]

## Current Position
Phase [N] of [total]: [phase-name]

## What's Next
[Next phase/plan objective]
```
</step>

<step name="route">
**Route to next action (using tgsd commands):**

| Condition | Route |
|-----------|-------|
| UAT gaps found | `/tgsd:plan-phase {X} --gaps` |
| Unexecuted plans exist | `/tgsd:execute-phase {X}` |
| Phase complete, more phases | `/tgsd:plan-phase {X+1}` |
| Phase needs planning | `/tgsd:plan-phase {X}` |
| Milestone complete | `/gsd:audit-milestone` |
| Between milestones | `/gsd:new-milestone` |

**Also suggest:**
- `/tgsd:debug` for active debug sessions
- `/gsd:check-todos` for pending todos
</step>

</process>

<success_criteria>
- [ ] Rich context provided (recent work, decisions, issues)
- [ ] Current position clear with visual progress
- [ ] Routes to /tgsd:* commands (not /gsd:*)
- [ ] User confirms before any action
</success_criteria>

---
name: tgsd:execute-phase
description: Execute all plans in a phase with a team of parallel executors
argument-hint: "<phase-number> [--gaps-only]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Task
  - AskUserQuestion
  - TeamCreate
  - TeamDelete
  - TaskCreate
  - TaskUpdate
  - TaskList
  - SendMessage
---

<objective>
Execute all plans in a phase using a team of parallel executors with inter-agent coordination.

Team mode execution:
- Creates a team with N team-executors (one per plan in wave) + team-verifier
- Executors run in parallel, share status via TaskList and SendMessage
- Verifier starts after all executors complete
- Team lead coordinates waves and handles checkpoints

Same output as /gsd:execute-phase but with team coordination.

Context budget: ~15% team lead, 100% fresh per agent.
</objective>

<execution_context>
@./.claude/get-shit-done/references/ui-brand.md
</execution_context>

<context>
Phase: $ARGUMENTS

**Flags:**
- `--gaps-only` — Execute only gap closure plans

@.planning/ROADMAP.md
@.planning/STATE.md
</context>

<process>

## 0. Resolve Model Profile

```bash
MODEL_PROFILE=$(cat .planning/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "balanced")
```

**Model lookup table:**

| Agent | quality | balanced | budget |
|-------|---------|----------|--------|
| team-executor | opus | sonnet | sonnet |
| team-verifier | sonnet | sonnet | haiku |

## 1. Validate phase exists

Find phase directory, count PLAN.md files. Error if no plans found.

## 2. Discover plans

- List all *-PLAN.md files in phase directory
- Check which have *-SUMMARY.md (already complete)
- If `--gaps-only`: filter to only plans with `gap_closure: true`
- Build list of incomplete plans

## 3. Group by wave

Read `wave` from each plan's frontmatter. Group plans by wave number.

## 4. Create team

```
TeamCreate(team_name="tgsd-phase-${PHASE}", description="Execute Phase ${PHASE}: ${PHASE_NAME}")
```

Create a task for each plan:

```
For each plan in incomplete_plans:
  TaskCreate(
    subject="Execute ${plan_name}",
    description="Execute plan at ${plan_path}. Create SUMMARY.md. Commit atomically.",
    activeForm="Executing ${plan_name}"
  )
```

Create verification task:

```
TaskCreate(
  subject="Verify Phase ${PHASE} goal",
  description="Run goal-backward verification on Phase ${PHASE}. Check must_haves against codebase.",
  activeForm="Verifying Phase ${PHASE}"
)
```

Set dependencies: verification blocked by all execution tasks.

## 5. Execute waves with team

For each wave in order:

**5a. Read plan contents**

```bash
# Read each plan and STATE.md for inlining
PLAN_XX_CONTENT=$(cat "{plan_xx_path}")
STATE_CONTENT=$(cat .planning/STATE.md)
```

**5b. Spawn team-executors in parallel**

Spawn ALL executors for the current wave in a single message with multiple Task calls:

```
Task(
  prompt="Execute plan at ${plan_01_path}\n\nPlan:\n${plan_01_content}\n\nProject state:\n${state_content}\n\n<team_instructions>\n1. Mark task in_progress via TaskUpdate when starting\n2. Share commit hashes via SendMessage to team lead after each task\n3. Mark task completed via TaskUpdate when done\n4. If blocked, message team lead immediately\n</team_instructions>",
  subagent_type="team-executor",
  model="{executor_model}",
  team_name="tgsd-phase-${PHASE}",
  name="executor-01",
  description="Execute ${plan_01_name}"
)

Task(
  prompt="Execute plan at ${plan_02_path}\n\nPlan:\n${plan_02_content}\n\nProject state:\n${state_content}\n\n<team_instructions>..same..</team_instructions>",
  subagent_type="team-executor",
  model="{executor_model}",
  team_name="tgsd-phase-${PHASE}",
  name="executor-02",
  description="Execute ${plan_02_name}"
)
```

All executors in wave run in parallel. Task tool blocks until all complete.

**5c. Verify wave completion**

Check SUMMARYs created for each plan in wave. Proceed to next wave.

## 6. Commit any orchestrator corrections

```bash
git status --porcelain
```

If changes exist, stage individually and commit.

## 7. Verify phase goal with team-verifier

Check config: skip if `workflow.verifier` is `false`.

Otherwise spawn team-verifier:

```
Task(
  prompt="Verify Phase ${PHASE} goal achievement.\n\nPhase directory: ${PHASE_DIR}\nPhase goal: ${PHASE_GOAL}\nProject state:\n${STATE_CONTENT}\n\n<team_instructions>\n1. Mark verification task in_progress\n2. Create VERIFICATION.md\n3. If gaps found, message team lead with gap details\n4. Mark task completed with results\n</team_instructions>",
  subagent_type="team-verifier",
  model="{verifier_model}",
  team_name="tgsd-phase-${PHASE}",
  name="verifier",
  description="Verify Phase ${PHASE}"
)
```

Route by status:
- `passed` -> continue
- `human_needed` -> present items, get approval
- `gaps_found` -> present gaps, offer `/tgsd:plan-phase {X} --gaps`

## 8. Update roadmap and state

Update ROADMAP.md, STATE.md.

## 9. Update requirements

Mark phase requirements as Complete in REQUIREMENTS.md.

## 10. Shutdown team and commit

Send shutdown to all teammates:

```
SendMessage(type="broadcast", content="Phase complete. Shutting down.")
```

Then send individual shutdown_requests to each teammate.

Clean up:
```
TeamDelete()
```

Commit phase completion:
```bash
git add .planning/ROADMAP.md .planning/STATE.md
git commit -m "docs(${PHASE}): complete ${PHASE_NAME} phase"
```

## 11. Offer next steps

Same routing as /gsd:execute-phase but with `/tgsd:*` command suggestions.

</process>

<offer_next>
Same as gsd:execute-phase offer_next but replace all `/gsd:` with `/tgsd:`:

| Status | Route |
|--------|-------|
| `gaps_found` | `/tgsd:plan-phase {X} --gaps` |
| `passed` + more phases | `/tgsd:plan-phase {X+1}` or `/tgsd:execute-phase {X+1}` |
| `passed` + last phase | `/gsd:audit-milestone` |
</offer_next>

<deviation_rules>
Same as gsd:execute-phase:
1. Auto-fix bugs
2. Auto-add critical (security/correctness)
3. Auto-fix blockers
4. Ask about architectural (SendMessage to team lead)
</deviation_rules>

<commit_rules>
Same as gsd:execute-phase — per-task commits, plan metadata commits, phase completion commit.
**Always stage files individually. NEVER use `git add .` or `git add -A`.**
</commit_rules>

<success_criteria>
- [ ] Team created (tgsd-phase-XX)
- [ ] Tasks created for each plan + verification
- [ ] All incomplete plans executed (parallel within waves)
- [ ] Each plan has SUMMARY.md
- [ ] Executors communicated status via TaskList
- [ ] Phase goal verified by team-verifier
- [ ] VERIFICATION.md created
- [ ] STATE.md reflects phase completion
- [ ] ROADMAP.md updated
- [ ] REQUIREMENTS.md updated
- [ ] Team shut down and cleaned up
</success_criteria>

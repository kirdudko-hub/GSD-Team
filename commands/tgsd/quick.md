---
name: tgsd:quick
description: Execute a quick task with a team of coordinating agents
argument-hint: ""
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
Execute small, ad-hoc tasks using a team of coordinating agents with GSD guarantees (atomic commits, STATE.md tracking).

Team mode quick task:
- Creates a team with team-planner + team-executor
- Planner creates plan, notifies executor via SendMessage
- Executor implements and reports completion
- Team lead (you) coordinates and updates STATE.md

Same output as /gsd:quick but with team coordination:
- Quick tasks live in `.planning/quick/` separate from planned phases
- Updates STATE.md "Quick Tasks Completed" table (NOT ROADMAP.md)
</objective>

<execution_context>
Orchestration is inline. Team mode adds inter-agent communication to the quick workflow.
</execution_context>

<context>
@.planning/STATE.md
</context>

<process>

**Step 0: Resolve Model Profile**

Read model profile for agent spawning:

```bash
MODEL_PROFILE=$(cat .planning/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "balanced")
```

Default to "balanced" if not set.

**Model lookup table:**

| Agent | quality | balanced | budget |
|-------|---------|----------|--------|
| team-planner | opus | opus | sonnet |
| team-executor | opus | sonnet | sonnet |

---

**Step 1: Pre-flight validation**

```bash
if [ ! -f .planning/ROADMAP.md ]; then
  echo "Quick mode requires an active project with ROADMAP.md."
  echo "Run /gsd:new-project first."
  exit 1
fi
```

---

**Step 2: Get task description**

```
AskUserQuestion(
  header: "Quick Task",
  question: "What do you want to do?",
  followUp: null
)
```

Store response as `$DESCRIPTION`.

Generate slug:
```bash
slug=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | cut -c1-40)
```

---

**Step 3: Calculate next quick task number**

```bash
mkdir -p .planning/quick
last=$(ls -1d .planning/quick/[0-9][0-9][0-9]-* 2>/dev/null | sort -r | head -1 | xargs -I{} basename {} | grep -oE '^[0-9]+')
if [ -z "$last" ]; then
  next_num="001"
else
  next_num=$(printf "%03d" $((10#$last + 1)))
fi
```

---

**Step 4: Create quick task directory**

```bash
QUICK_DIR=".planning/quick/${next_num}-${slug}"
mkdir -p "$QUICK_DIR"
```

---

**Step 5: Create team and tasks**

Create a team for this quick task:

```
TeamCreate(team_name="tgsd-quick-${next_num}", description="Quick task ${next_num}: ${DESCRIPTION}")
```

Create tasks for the team:

```
TaskCreate(subject="Plan quick task ${next_num}", description="Create a SINGLE plan with 1-3 focused tasks for: ${DESCRIPTION}. Write to ${QUICK_DIR}/${next_num}-PLAN.md")
TaskCreate(subject="Execute quick task ${next_num}", description="Execute plan at ${QUICK_DIR}/${next_num}-PLAN.md. Create summary at ${QUICK_DIR}/${next_num}-SUMMARY.md. Do NOT update ROADMAP.md.")
```

Set dependency: execution blocked by planning.

---

**Step 6: Spawn team-planner**

Read STATE.md content for inlining:

```bash
STATE_CONTENT=$(cat .planning/STATE.md)
```

Spawn team-planner:

```
Task(
  prompt="
<planning_context>

**Mode:** quick
**Directory:** ${QUICK_DIR}
**Description:** ${DESCRIPTION}
**Team:** tgsd-quick-${next_num}

**Project State:**
${STATE_CONTENT}

</planning_context>

<constraints>
- Create a SINGLE plan with 1-3 focused tasks
- Quick tasks should be atomic and self-contained
- No research phase, no checker phase
- Target ~30% context usage (simple, focused)
</constraints>

<output>
Write plan to: ${QUICK_DIR}/${next_num}-PLAN.md
Return: ## PLANNING COMPLETE with plan path
</output>

<team_instructions>
After creating the plan:
1. Mark your task as completed via TaskUpdate
2. Send plan summary to team lead via SendMessage
</team_instructions>
",
  subagent_type="team-planner",
  model="{planner_model}",
  team_name="tgsd-quick-${next_num}",
  name="planner",
  description="Quick plan: ${DESCRIPTION}"
)
```

Wait for planner to complete. Verify plan exists.

---

**Step 7: Spawn team-executor**

Read the plan content for inlining:

```bash
PLAN_CONTENT=$(cat "${QUICK_DIR}/${next_num}-PLAN.md")
STATE_CONTENT=$(cat .planning/STATE.md)
```

```
Task(
  prompt="
Execute quick task ${next_num}.

Plan:
${PLAN_CONTENT}

Project state:
${STATE_CONTENT}

<constraints>
- Execute all tasks in the plan
- Commit each task atomically
- Create summary at: ${QUICK_DIR}/${next_num}-SUMMARY.md
- Do NOT update ROADMAP.md (quick tasks are separate from planned phases)
</constraints>

<team_instructions>
After completing execution:
1. Mark your task as completed via TaskUpdate
2. Send completion summary with commit hash to team lead via SendMessage
</team_instructions>
",
  subagent_type="team-executor",
  model="{executor_model}",
  team_name="tgsd-quick-${next_num}",
  name="executor",
  description="Execute: ${DESCRIPTION}"
)
```

Wait for executor to complete. Verify summary exists.

---

**Step 8: Update STATE.md**

Same as /gsd:quick Step 7 — update "Quick Tasks Completed" table and "Last activity" line.

---

**Step 9: Shutdown team and final commit**

Send shutdown to all teammates:

```
SendMessage(type="shutdown_request", recipient="planner", content="Task complete")
SendMessage(type="shutdown_request", recipient="executor", content="Task complete")
```

Clean up team:
```
TeamDelete()
```

Stage and commit:

```bash
git add ${QUICK_DIR}/${next_num}-PLAN.md ${QUICK_DIR}/${next_num}-SUMMARY.md .planning/STATE.md
git commit -m "$(cat <<'EOF'
docs(quick-${next_num}): ${DESCRIPTION}

Quick task completed (team mode).

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

Display completion:
```
---

TGSD > QUICK TASK COMPLETE

Quick Task ${next_num}: ${DESCRIPTION}

Summary: ${QUICK_DIR}/${next_num}-SUMMARY.md
Commit: ${commit_hash}

---

Ready for next task: /tgsd:quick
```

</process>

<success_criteria>
- [ ] ROADMAP.md validation passes
- [ ] User provides task description
- [ ] Team created (tgsd-quick-NNN)
- [ ] Tasks created with dependencies
- [ ] team-planner creates PLAN.md
- [ ] team-executor creates SUMMARY.md
- [ ] STATE.md updated with quick task row
- [ ] Team shut down and cleaned up
- [ ] Artifacts committed
</success_criteria>

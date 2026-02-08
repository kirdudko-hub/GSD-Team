---
name: tgsd:plan-phase
description: Plan a phase with a team of coordinating agents (researcher + planner + checker)
argument-hint: "[phase] [--research] [--skip-research] [--gaps] [--skip-verify]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - Task
  - WebFetch
  - AskUserQuestion
  - TeamCreate
  - TeamDelete
  - TaskCreate
  - TaskUpdate
  - TaskList
  - SendMessage
  - mcp__context7__*
---

<execution_context>
@./.claude/get-shit-done/references/ui-brand.md
</execution_context>

<objective>
Create executable phase plans (PLAN.md files) using a team of coordinating agents.

Team mode planning:
- Creates team: team-researcher + team-planner + team-plan-checker
- Researcher and planner can share findings via SendMessage
- Checker communicates issues directly to planner for revision
- Team lead coordinates the flow and handles user interaction

**Default flow:** Research (team) -> Plan (team) -> Verify (team) -> Done

Same output as /gsd:plan-phase but with team coordination.
</objective>

<context>
Phase number: $ARGUMENTS (optional - auto-detects next unplanned phase if not provided)

**Flags:**
- `--research` — Force re-research
- `--skip-research` — Skip research entirely
- `--gaps` — Gap closure mode (reads VERIFICATION.md, skips research)
- `--skip-verify` — Skip plan verification loop

@.planning/ROADMAP.md
@.planning/STATE.md
</context>

<process>

## 1. Validate Environment and Resolve Model Profile

```bash
ls .planning/ 2>/dev/null
MODEL_PROFILE=$(cat .planning/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "balanced")
```

**Model lookup table:**

| Agent | quality | balanced | budget |
|-------|---------|----------|--------|
| team-researcher | opus | sonnet | haiku |
| team-planner | opus | opus | sonnet |
| team-plan-checker | sonnet | sonnet | haiku |

## 2. Parse and Normalize Arguments

Same as /gsd:plan-phase — extract phase number, flags, normalize to zero-padded format.

## 3. Validate Phase

```bash
grep -A5 "Phase ${PHASE}:" .planning/ROADMAP.md 2>/dev/null
```

## 4. Ensure Phase Directory and Load CONTEXT.md

Same as /gsd:plan-phase — create directory if needed, load CONTEXT.md early.

## 5. Create team

```
TeamCreate(team_name="tgsd-plan-${PHASE}", description="Plan Phase ${PHASE}: ${PHASE_NAME}")
```

## 6. Handle Research (with team)

**If `--gaps` or `--skip-research`:** Skip to step 7.

**If RESEARCH.md exists and `--research` not set:** Use existing, skip to step 7.

**Otherwise:** Spawn team-researcher:

```bash
PHASE_DESC=$(grep -A3 "Phase ${PHASE}:" .planning/ROADMAP.md)
REQUIREMENTS=$(cat .planning/REQUIREMENTS.md 2>/dev/null | grep -A100 "## Requirements" | head -50)
DECISIONS=$(grep -A20 "### Decisions Made" .planning/STATE.md 2>/dev/null)
```

```
Task(
  prompt="
<objective>
Research how to implement Phase ${PHASE}: ${PHASE_NAME}
Answer: 'What do I need to know to PLAN this phase well?'
</objective>

<phase_context>
${CONTEXT_CONTENT}
</phase_context>

<additional_context>
Phase description: ${PHASE_DESC}
Requirements: ${REQUIREMENTS}
Prior decisions: ${DECISIONS}
</additional_context>

<output>
Write research findings to: ${PHASE_DIR}/${PHASE}-RESEARCH.md
</output>

<team_instructions>
1. Mark your task in_progress via TaskUpdate
2. When research is complete, send summary of key findings to team lead via SendMessage
3. If you discover something critical that affects planning, message team lead immediately
4. Mark task completed when RESEARCH.md is written
</team_instructions>
",
  subagent_type="team-researcher",
  model="{researcher_model}",
  team_name="tgsd-plan-${PHASE}",
  name="researcher",
  description="Research Phase ${PHASE}"
)
```

Wait for researcher to complete. Verify RESEARCH.md exists.

## 7. Spawn team-planner

Read context files for inlining:

```bash
STATE_CONTENT=$(cat .planning/STATE.md)
ROADMAP_CONTENT=$(cat .planning/ROADMAP.md)
REQUIREMENTS_CONTENT=$(cat .planning/REQUIREMENTS.md 2>/dev/null)
RESEARCH_CONTENT=$(cat "${PHASE_DIR}"/*-RESEARCH.md 2>/dev/null)
VERIFICATION_CONTENT=$(cat "${PHASE_DIR}"/*-VERIFICATION.md 2>/dev/null)
UAT_CONTENT=$(cat "${PHASE_DIR}"/*-UAT.md 2>/dev/null)
```

```
Task(
  prompt="
<planning_context>

**Phase:** ${PHASE}
**Mode:** ${standard | gap_closure}

**Project State:**
${STATE_CONTENT}

**Roadmap:**
${ROADMAP_CONTENT}

**Requirements:**
${REQUIREMENTS_CONTENT}

**Phase Context:**
${CONTEXT_CONTENT}

**Research:**
${RESEARCH_CONTENT}

**Gap Closure (if --gaps mode):**
${VERIFICATION_CONTENT}
${UAT_CONTENT}

</planning_context>

<downstream_consumer>
Output consumed by /tgsd:execute-phase
Plans must be executable prompts with frontmatter, tasks, verification criteria, must_haves.
</downstream_consumer>

<team_instructions>
1. Mark your task in_progress via TaskUpdate
2. When plans are created, send plan summary to team lead (count, waves, key decisions)
3. Mark task completed when all PLAN.md files are written
</team_instructions>
",
  subagent_type="team-planner",
  model="{planner_model}",
  team_name="tgsd-plan-${PHASE}",
  name="planner",
  description="Plan Phase ${PHASE}"
)
```

Wait for planner. Verify PLAN.md files exist.

## 8. Spawn team-plan-checker (verification)

**If `--skip-verify` or config `workflow.plan_check` is false:** Skip to step 10.

```bash
PLANS_CONTENT=$(cat "${PHASE_DIR}"/*-PLAN.md 2>/dev/null)
```

```
Task(
  prompt="
<verification_context>

**Phase:** ${PHASE}
**Phase Goal:** ${PHASE_GOAL}

**Plans to verify:**
${PLANS_CONTENT}

**Requirements:**
${REQUIREMENTS_CONTENT}

**Phase Context:**
${CONTEXT_CONTENT}

</verification_context>

<team_instructions>
1. Mark your task in_progress via TaskUpdate
2. If issues found, send structured issue list to team lead via SendMessage
3. If all passes, send confirmation to team lead
4. Mark task completed with results
</team_instructions>
",
  subagent_type="team-plan-checker",
  model="{checker_model}",
  team_name="tgsd-plan-${PHASE}",
  name="checker",
  description="Verify Phase ${PHASE} plans"
)
```

## 9. Handle Checker Return / Revision Loop

Same as /gsd:plan-phase — max 3 iterations.

On issues found:
- Send issues to team-planner for revision via SendMessage
- Re-spawn planner with revision context
- Re-run checker

## 10. Shutdown team and present status

```
SendMessage(type="shutdown_request", recipient="researcher", content="Planning complete")
SendMessage(type="shutdown_request", recipient="planner", content="Planning complete")
SendMessage(type="shutdown_request", recipient="checker", content="Planning complete")
TeamDelete()
```

Route to offer_next.

</process>

<offer_next>
Same as gsd:plan-phase but with tgsd commands:

---

TGSD > PHASE {X} PLANNED

**Phase {X}: {Name}** -- {N} plan(s) in {M} wave(s)

| Wave | Plans | What it builds |
|------|-------|----------------|
| 1    | 01, 02 | [objectives] |
| 2    | 03     | [objective]  |

Research: {Completed | Used existing | Skipped}
Verification: {Passed | Passed with override | Skipped}

---

Next Up: `/tgsd:execute-phase {X}`

---
</offer_next>

<success_criteria>
- [ ] Team created (tgsd-plan-XX)
- [ ] Phase validated against roadmap
- [ ] CONTEXT.md loaded and passed to all agents
- [ ] Research completed by team-researcher (unless skipped)
- [ ] Plans created by team-planner
- [ ] Plans verified by team-plan-checker (unless skipped)
- [ ] Revision loop handled (max 3 iterations)
- [ ] Team shut down and cleaned up
- [ ] User sees status and next steps
</success_criteria>

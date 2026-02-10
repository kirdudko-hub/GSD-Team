---
name: tgsd:audit-milestone
description: Audit milestone with team (verifier + integration checker in parallel)
argument-hint: "[version]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Task
  - Write
  - TeamCreate
  - TeamDelete
  - TaskCreate
  - TaskUpdate
  - TaskList
  - SendMessage
---

<objective>
Verify milestone achieved its definition of done using a team of parallel verification agents.

Team mode audit:
- Creates team: team-verifier (aggregates phase verifications) + team-integration-checker (cross-phase wiring)
- Both agents run in parallel and share findings via SendMessage
- Team lead aggregates results into MILESTONE-AUDIT.md

Same output as /gsd:audit-milestone but with team coordination.
</objective>

<context>
Version: $ARGUMENTS (optional — defaults to current milestone)

@.planning/PROJECT.md
@.planning/REQUIREMENTS.md
@.planning/ROADMAP.md
@.planning/config.json
</context>

<process>

## 0. Resolve Model Profile

```bash
MODEL_PROFILE=$(cat .planning/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "quality")
```

Default to "quality" if not set.

**Model & context budget lookup table:**

| Agent | quality | balanced | budget |
|-------|---------|----------|--------|
| team-verifier | sonnet | sonnet | haiku |
| team-integration-checker | sonnet | sonnet | haiku |

**Context budget (all models use 200k window):**

| Threshold | % of Window | Tokens |
|-----------|-------------|--------|
| Target | 40% | 80k tokens |
| Warning | 60% | 120k tokens |
| Blocker | 70% | 140k tokens |

## 1. Determine Milestone Scope

Same as /gsd:audit-milestone — parse version, identify phases, extract definition of done.

## 2. Create team

```
TeamCreate(team_name="tgsd-audit-${VERSION}", description="Audit milestone ${VERSION}")
```

Create tasks:
```
TaskCreate(subject="Verify phase completions", description="Read all VERIFICATION.md files, aggregate gaps and tech debt", activeForm="Aggregating verifications")
TaskCreate(subject="Check cross-phase integration", description="Verify cross-phase wiring and E2E flows", activeForm="Checking integration")
```

## 3. Spawn agents in parallel

```
Task(
  prompt="Read all phase VERIFICATION.md files for milestone ${VERSION}.
Phases: ${PHASE_DIRS}

For each phase, extract: status, critical gaps, non-critical gaps, anti-patterns, requirements coverage.

Report aggregated findings to team lead via SendMessage.
If you find broken requirements, also message 'integration-checker' to verify wiring.

<team_instructions>
1. Mark task in_progress
2. Share critical gaps with team lead immediately
3. Message integration-checker about any broken cross-phase dependencies
4. Mark task completed with aggregated report
</team_instructions>",
  subagent_type="team-verifier",
  model="{verifier_model}",
  team_name="tgsd-audit-${VERSION}",
  name="verifier",
  description="Aggregate verifications"
)

Task(
  prompt="Check cross-phase integration and E2E flows for milestone ${VERSION}.
Phases: ${PHASE_DIRS}
Phase exports: ${FROM_SUMMARYS}

Verify cross-phase wiring and E2E user flows.

<team_instructions>
1. Mark task in_progress
2. Share broken flows with team lead immediately
3. If verifier messages you about specific dependencies, prioritize checking those
4. Mark task completed with integration report
</team_instructions>",
  subagent_type="team-integration-checker",
  model="{integration_model}",
  team_name="tgsd-audit-${VERSION}",
  name="integration-checker",
  description="Check integration"
)
```

Both run in parallel and communicate findings.

## 4-6. Collect Results, Check Requirements, Create MILESTONE-AUDIT.md

Same as /gsd:audit-milestone — combine both agents' findings.

## 7. Shutdown team and present results

```
SendMessage(type="shutdown_request", recipient="verifier", content="Audit complete")
SendMessage(type="shutdown_request", recipient="integration-checker", content="Audit complete")
TeamDelete()
```

Route by status — same as /gsd:audit-milestone but next steps use `/tgsd:*`:
- gaps_found -> `/tgsd:plan-milestone-gaps` or `/gsd:plan-milestone-gaps`
- passed -> `/gsd:complete-milestone`

</process>

<success_criteria>
- [ ] Team created (tgsd-audit-VERSION)
- [ ] team-verifier and team-integration-checker spawned in parallel
- [ ] Agents communicated findings via SendMessage
- [ ] Requirements coverage checked
- [ ] MILESTONE-AUDIT.md created with aggregated results
- [ ] Team shut down and cleaned up
- [ ] User sees actionable next steps
</success_criteria>

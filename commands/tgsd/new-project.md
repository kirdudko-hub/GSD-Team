---
name: tgsd:new-project
description: Initialize a new project with team-coordinated research
allowed-tools:
  - Read
  - Bash
  - Write
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
Initialize a new project through unified flow: questioning -> research (team) -> requirements -> roadmap.

Identical to /gsd:new-project but uses a team of 4 parallel team-researchers during the research phase, with inter-agent communication for sharing discoveries.

**Creates:**
- `.planning/PROJECT.md` — project context
- `.planning/config.json` — workflow preferences
- `.planning/research/` — domain research (team-parallel with communication)
- `.planning/REQUIREMENTS.md` — scoped requirements
- `.planning/ROADMAP.md` — phase structure
- `.planning/STATE.md` — project memory

**After this command:** Run `/tgsd:plan-phase 1` to start execution.
</objective>

<execution_context>
@./.claude/get-shit-done/references/questioning.md
@./.claude/get-shit-done/references/ui-brand.md
@./.claude/get-shit-done/templates/project.md
@./.claude/get-shit-done/templates/requirements.md
</execution_context>

<process>

## Phases 1-6: Same as /gsd:new-project

Setup, brownfield detection, deep questioning, write PROJECT.md, config.json. No team needed — these are interactive phases with the user.

**Note:** Default model profile is "quality" (Opus 4.6 for all primary agents).

## Phase 6.5: Resolve Model Profile

```bash
MODEL_PROFILE=$(cat .planning/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "quality")
```

Default to "quality" if not set.

**Model & context budget lookup table:**

| Agent | quality | balanced | budget |
|-------|---------|----------|--------|
| team-researcher | opus | sonnet | haiku |
| gsd-research-synthesizer | sonnet | sonnet | haiku |
| gsd-roadmapper | opus | sonnet | sonnet |

**Context budget (all models use 200k window):**

| Threshold | % of Window | Tokens |
|-----------|-------------|--------|
| Target | 40% | 80k tokens |
| Warning | 60% | 120k tokens |
| Blocker | 70% | 140k tokens |

## Phase 7: Research (Team Mode)

Same research decision prompt as /gsd:new-project.

**If "Research first":**

Create research team:
```
TeamCreate(team_name="tgsd-research-init", description="Research for new project")
```

Spawn 4 team-researchers in parallel (same prompts as /gsd:new-project but with team_instructions):

```
Task(prompt="Stack research... <team_instructions>Share findings with other researchers via SendMessage. Mark task via TaskUpdate.</team_instructions>",
  subagent_type="team-researcher", team_name="tgsd-research-init", name="researcher-stack", ...)

Task(prompt="Features research... <team_instructions>Same</team_instructions>",
  subagent_type="team-researcher", team_name="tgsd-research-init", name="researcher-features", ...)

Task(prompt="Architecture research... <team_instructions>Same</team_instructions>",
  subagent_type="team-researcher", team_name="tgsd-research-init", name="researcher-arch", ...)

Task(prompt="Pitfalls research... <team_instructions>Same</team_instructions>",
  subagent_type="team-researcher", team_name="tgsd-research-init", name="researcher-pitfalls", ...)
```

All 4 run in parallel with inter-agent communication.

After completion: spawn gsd-research-synthesizer, shutdown team.

## Phases 8-10: Same as /gsd:new-project

Requirements definition, roadmap creation, completion. Routes to `/tgsd:plan-phase 1`.

</process>

<success_criteria>
- [ ] PROJECT.md created with full project context
- [ ] config.json created with workflow preferences
- [ ] Research team created with 4 parallel team-researchers
- [ ] Researchers shared findings via SendMessage
- [ ] Research synthesized into SUMMARY.md
- [ ] Research team shut down and cleaned up
- [ ] REQUIREMENTS.md created with REQ-IDs
- [ ] ROADMAP.md created with phase structure
- [ ] STATE.md initialized
- [ ] User knows next step is `/tgsd:plan-phase 1`
</success_criteria>

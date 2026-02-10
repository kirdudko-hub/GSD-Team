---
name: tgsd:new-milestone
description: Start a new milestone with team-coordinated research and roadmapping
argument-hint: "[milestone name, e.g., 'v1.1 Notifications']"
allowed-tools:
  - Read
  - Write
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
Start a new milestone through unified flow: questioning -> research (team) -> requirements -> roadmap.

Team mode milestone initialization:
- Creates team for research phase: 4 x team-researcher in parallel + synthesizer
- Researchers share findings via SendMessage as they discover them
- Roadmapper uses team coordination for context sharing

Same output as /gsd:new-milestone but with team coordination for research.

**Creates/Updates:**
- `.planning/PROJECT.md` — updated with new milestone goals
- `.planning/research/` — domain research (team-parallel)
- `.planning/REQUIREMENTS.md` — scoped requirements
- `.planning/ROADMAP.md` — phase structure
- `.planning/STATE.md` — reset for new milestone

**After this command:** Run `/tgsd:plan-phase [N]` to start execution.
</objective>

<execution_context>
@./.claude/get-shit-done/references/questioning.md
@./.claude/get-shit-done/references/ui-brand.md
@./.claude/get-shit-done/templates/project.md
@./.claude/get-shit-done/templates/requirements.md
</execution_context>

<context>
Milestone name: $ARGUMENTS (optional - will prompt if not provided)

@.planning/PROJECT.md
@.planning/STATE.md
@.planning/MILESTONES.md
@.planning/config.json
@.planning/MILESTONE-CONTEXT.md
</context>

<process>

## Phases 1-6: Same as /gsd:new-milestone

Load context, gather milestone goals, determine version, update PROJECT.md, update STATE.md, cleanup and commit. No team needed for these interactive phases.

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

## Phase 7: Research Decision (Team Mode)

Same AskUserQuestion as /gsd:new-milestone.

**If "Research first":**

Create research team:

```
TeamCreate(team_name="tgsd-research-${VERSION}", description="Research for milestone ${VERSION}")
```

Create tasks:
```
TaskCreate(subject="Research: Stack additions", description="Research stack additions needed for ${NEW_FEATURES}", activeForm="Researching stack")
TaskCreate(subject="Research: Features", description="Research expected feature behavior for ${NEW_FEATURES}", activeForm="Researching features")
TaskCreate(subject="Research: Architecture", description="Research architecture integration for ${NEW_FEATURES}", activeForm="Researching architecture")
TaskCreate(subject="Research: Pitfalls", description="Research common pitfalls for ${NEW_FEATURES}", activeForm="Researching pitfalls")
```

**Spawn 4 team-researchers in parallel:**

```
Task(
  prompt="<research_type>Stack dimension for ${NEW_FEATURES}</research_type>
<milestone_context>SUBSEQUENT MILESTONE — Adding ${NEW_FEATURES} to existing app.
Existing validated capabilities: ${VALIDATED_REQUIREMENTS}
Focus ONLY on NEW features.</milestone_context>
<question>What stack additions/changes needed?</question>
<project_context>${PROJECT_SUMMARY}</project_context>
<output>Write to: .planning/research/STACK.md</output>
<team_instructions>
1. Mark task in_progress via TaskUpdate
2. If you find critical compatibility issues, message team lead immediately
3. Share key findings with other researchers via SendMessage (they research related areas)
4. Mark task completed when STACK.md is written
</team_instructions>",
  subagent_type="team-researcher",
  model="{researcher_model}",
  team_name="tgsd-research-${VERSION}",
  name="researcher-stack",
  description="Stack research"
)

Task(
  prompt="<research_type>Features dimension</research_type>
...same pattern, write to .planning/research/FEATURES.md...
<team_instructions>Same as above, share findings</team_instructions>",
  subagent_type="team-researcher",
  model="{researcher_model}",
  team_name="tgsd-research-${VERSION}",
  name="researcher-features",
  description="Features research"
)

Task(
  prompt="<research_type>Architecture dimension</research_type>
...same pattern, write to .planning/research/ARCHITECTURE.md...
<team_instructions>Same as above, share findings</team_instructions>",
  subagent_type="team-researcher",
  model="{researcher_model}",
  team_name="tgsd-research-${VERSION}",
  name="researcher-arch",
  description="Architecture research"
)

Task(
  prompt="<research_type>Pitfalls dimension</research_type>
...same pattern, write to .planning/research/PITFALLS.md...
<team_instructions>Same as above, share findings</team_instructions>",
  subagent_type="team-researcher",
  model="{researcher_model}",
  team_name="tgsd-research-${VERSION}",
  name="researcher-pitfalls",
  description="Pitfalls research"
)
```

All 4 run in parallel and can share findings via SendMessage.

**After all complete, spawn synthesizer:**

```
Task(
  prompt="Synthesize research outputs into SUMMARY.md.
Read: .planning/research/STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md
Write to: .planning/research/SUMMARY.md",
  subagent_type="gsd-research-synthesizer",
  model="{synthesizer_model}",
  description="Synthesize research"
)
```

**Shutdown research team:**

```
SendMessage(type="shutdown_request", recipient="researcher-stack", content="Research complete")
SendMessage(type="shutdown_request", recipient="researcher-features", content="Research complete")
SendMessage(type="shutdown_request", recipient="researcher-arch", content="Research complete")
SendMessage(type="shutdown_request", recipient="researcher-pitfalls", content="Research complete")
TeamDelete()
```

## Phase 8: Define Requirements

Same as /gsd:new-milestone — interactive scoping with user.

## Phase 9: Create Roadmap

Same as /gsd:new-milestone — spawn gsd-roadmapper.

## Phase 10: Done

Present completion with `/tgsd:*` next steps:

```
TGSD > MILESTONE INITIALIZED

Milestone v${VERSION}: ${NAME}

Next Up: /tgsd:plan-phase ${FIRST_PHASE}

Also available:
- /gsd:discuss-phase ${FIRST_PHASE}
- /tgsd:plan-phase ${FIRST_PHASE}
```

</process>

<success_criteria>
- [ ] PROJECT.md updated with Current Milestone section
- [ ] STATE.md reset for new milestone
- [ ] Research team created with 4 parallel team-researchers
- [ ] Researchers communicated findings via SendMessage
- [ ] Research synthesized into SUMMARY.md
- [ ] Research team shut down and cleaned up
- [ ] Requirements gathered and REQUIREMENTS.md created
- [ ] Roadmap created with continuing phase numbers
- [ ] All commits made
- [ ] User knows next step is `/tgsd:plan-phase [N]`
</success_criteria>

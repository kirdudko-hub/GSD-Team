---
name: tgsd:map-codebase
description: Map codebase with team of parallel mapper agents that share findings
argument-hint: "[optional: specific area to map]"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Write
  - Task
  - TeamCreate
  - TeamDelete
  - TaskCreate
  - TaskUpdate
  - TaskList
  - SendMessage
---

<objective>
Analyze existing codebase using a team of parallel team-codebase-mapper agents that can share findings with each other.

Team mode mapping:
- Creates team: 4 x team-codebase-mapper (tech, arch, quality, concerns)
- Mappers share discoveries via SendMessage (e.g., arch mapper tells concerns mapper about circular dependencies)
- Same .planning/codebase/ output with 7 documents

Same output as /gsd:map-codebase but with inter-agent communication.
</objective>

<execution_context>
@./.claude/get-shit-done/workflows/map-codebase.md
</execution_context>

<context>
Focus area: $ARGUMENTS (optional)
</context>

<process>

## 1. Check existing codebase map

```bash
ls .planning/codebase/ 2>/dev/null
```

If exists, offer to refresh or skip.

## 1.5. Resolve Model Profile

```bash
MODEL_PROFILE=$(cat .planning/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "quality")
```

Default to "quality" if not set.

**Model & context budget lookup table:**

| Agent | quality | balanced | budget |
|-------|---------|----------|--------|
| team-codebase-mapper | sonnet | sonnet | haiku |

**Context budget (200k window per agent):**

| Context Usage | Quality | Tokens |
|---------------|---------|--------|
| 0-30% | PEAK | 0-60k |
| 30-50% | GOOD | 60-100k |
| 50-70% | DEGRADING | 100-140k |
| 70%+ | POOR | 140k+ |

**Target: complete within ~50% context (100k tokens).**

## 2. Create team

```bash
mkdir -p .planning/codebase
```

```
TeamCreate(team_name="tgsd-map-codebase", description="Map codebase structure")
```

Create tasks:
```
TaskCreate(subject="Map: Stack + Integrations", description="Write STACK.md and INTEGRATIONS.md", activeForm="Mapping stack")
TaskCreate(subject="Map: Architecture + Structure", description="Write ARCHITECTURE.md and STRUCTURE.md", activeForm="Mapping architecture")
TaskCreate(subject="Map: Conventions + Testing", description="Write CONVENTIONS.md and TESTING.md", activeForm="Mapping quality")
TaskCreate(subject="Map: Concerns", description="Write CONCERNS.md", activeForm="Mapping concerns")
```

## 3. Spawn 4 team-codebase-mappers in parallel

```
Task(
  prompt="Focus: tech. Write STACK.md and INTEGRATIONS.md to .planning/codebase/.
<team_instructions>
1. Mark task in_progress
2. If you find unusual dependencies or integration patterns, message 'mapper-arch' about it
3. If you find security concerns, message 'mapper-concerns' about it
4. Mark task completed when both files are written
</team_instructions>",
  subagent_type="team-codebase-mapper",
  model="{mapper_model}",
  team_name="tgsd-map-codebase",
  name="mapper-tech",
  description="Map stack + integrations"
)

Task(
  prompt="Focus: arch. Write ARCHITECTURE.md and STRUCTURE.md to .planning/codebase/.
<team_instructions>
1. Mark task in_progress
2. If you find circular dependencies or concerning patterns, message 'mapper-concerns'
3. Share key architectural decisions with 'mapper-tech' if relevant
4. Mark task completed when both files are written
</team_instructions>",
  subagent_type="team-codebase-mapper",
  model="{mapper_model}",
  team_name="tgsd-map-codebase",
  name="mapper-arch",
  description="Map architecture + structure"
)

Task(
  prompt="Focus: quality. Write CONVENTIONS.md and TESTING.md to .planning/codebase/.
<team_instructions>
1. Mark task in_progress
2. If you find untested critical paths, message 'mapper-concerns' about it
3. Mark task completed when both files are written
</team_instructions>",
  subagent_type="team-codebase-mapper",
  model="{mapper_model}",
  team_name="tgsd-map-codebase",
  name="mapper-quality",
  description="Map conventions + testing"
)

Task(
  prompt="Focus: concerns. Write CONCERNS.md to .planning/codebase/.
<team_instructions>
1. Mark task in_progress
2. Other mappers may message you about issues they found — incorporate these
3. Share critical concerns with team lead via SendMessage
4. Mark task completed when CONCERNS.md is written
</team_instructions>",
  subagent_type="team-codebase-mapper",
  model="{mapper_model}",
  team_name="tgsd-map-codebase",
  name="mapper-concerns",
  description="Map concerns"
)
```

All 4 run in parallel with cross-communication.

## 4. Verify and cleanup

After all complete:

```bash
wc -l .planning/codebase/*.md
```

Verify all 7 documents exist.

Shutdown team:
```
SendMessage(type="shutdown_request", recipient="mapper-tech", content="Mapping complete")
SendMessage(type="shutdown_request", recipient="mapper-arch", content="Mapping complete")
SendMessage(type="shutdown_request", recipient="mapper-quality", content="Mapping complete")
SendMessage(type="shutdown_request", recipient="mapper-concerns", content="Mapping complete")
TeamDelete()
```

## 5. Commit and next steps

```bash
git add .planning/codebase/
git commit -m "docs: map codebase (7 documents, team mode)"
```

Offer next steps:
- `/tgsd:new-project` or `/tgsd:new-milestone`

</process>

<success_criteria>
- [ ] Team created (tgsd-map-codebase)
- [ ] 4 team-codebase-mappers spawned in parallel
- [ ] Mappers communicated findings via SendMessage
- [ ] All 7 codebase documents written
- [ ] Team shut down and cleaned up
- [ ] Documents committed
- [ ] User knows next steps
</success_criteria>

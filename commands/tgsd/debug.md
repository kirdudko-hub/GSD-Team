---
name: tgsd:debug
description: Debug issues with a team (debugger + researcher working together)
argument-hint: "[issue description]"
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
Debug issues using a team of coordinating agents.

Team mode debugging:
- Creates team: team-debugger + team-researcher
- Debugger investigates using scientific method
- Researcher looks up docs, patterns, known issues in parallel
- They share findings via SendMessage
- Team lead coordinates and handles user interaction

Same output as /gsd:debug (.planning/debug/ tracking) but with team support.
</objective>

<context>
User's issue: $ARGUMENTS

Check for active sessions:
```bash
ls .planning/debug/*.md 2>/dev/null | grep -v resolved | head -5
```
</context>

<process>

## 0. Resolve Model Profile

```bash
MODEL_PROFILE=$(cat .planning/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "balanced")
```

| Agent | quality | balanced | budget |
|-------|---------|----------|--------|
| team-debugger | opus | sonnet | sonnet |
| team-researcher | opus | sonnet | haiku |

## 1. Check Active Sessions

Same as /gsd:debug — check for active sessions, offer resume or new.

## 2. Gather Symptoms (if new issue)

Same as /gsd:debug — use AskUserQuestion for expected/actual/errors/timeline/reproduction.

## 3. Create team

```
TeamCreate(team_name="tgsd-debug-${slug}", description="Debug: ${trigger}")
```

Create tasks:

```
TaskCreate(subject="Investigate: ${trigger}", description="Scientific method investigation. Create debug file at .planning/debug/${slug}.md", activeForm="Investigating ${slug}")
TaskCreate(subject="Research: ${trigger}", description="Look up relevant docs, patterns, known issues for: ${trigger}", activeForm="Researching ${slug}")
```

## 4. Spawn agents in parallel

Spawn BOTH agents simultaneously:

```
Task(
  prompt="
<objective>
Investigate issue: ${slug}
**Summary:** ${trigger}
</objective>

<symptoms>
expected: ${expected}
actual: ${actual}
errors: ${errors}
reproduction: ${reproduction}
timeline: ${timeline}
</symptoms>

<mode>
symptoms_prefilled: true
goal: find_and_fix
</mode>

<debug_file>
Create: .planning/debug/${slug}.md
</debug_file>

<team_instructions>
1. You have a teammate 'researcher' who is looking up docs and patterns for this issue
2. If you need specific documentation or framework behavior looked up, message 'researcher' via SendMessage
3. Share significant findings (root cause hypotheses, evidence) with team lead
4. Mark task completed when root cause is found or investigation is inconclusive
</team_instructions>
",
  subagent_type="team-debugger",
  model="{debugger_model}",
  team_name="tgsd-debug-${slug}",
  name="debugger",
  description="Debug ${slug}"
)

Task(
  prompt="
<objective>
Research support for debugging: ${trigger}

You are the research support for the debugging team. Your job:
1. Look up relevant documentation, patterns, and known issues
2. Search for similar error messages and solutions
3. Check framework/library docs for relevant behavior
4. Share findings with the 'debugger' teammate via SendMessage
</objective>

<symptoms>
expected: ${expected}
actual: ${actual}
errors: ${errors}
</symptoms>

<team_instructions>
1. Your teammate 'debugger' is actively investigating this issue
2. Proactively research the error messages and symptoms
3. Share any relevant findings with 'debugger' via SendMessage
4. If 'debugger' asks you to look something up, prioritize that
5. Mark task completed when debugger confirms root cause found
</team_instructions>
",
  subagent_type="team-researcher",
  model="{researcher_model}",
  team_name="tgsd-debug-${slug}",
  name="researcher",
  description="Research ${slug}"
)
```

Both agents run in parallel and communicate.

## 5. Handle Agent Returns

Same as /gsd:debug:

**`## ROOT CAUSE FOUND`:**
- Display root cause and evidence
- Offer: Fix now / Plan fix / Manual fix

**`## CHECKPOINT REACHED`:**
- Present to user, get response, spawn continuation

**`## INVESTIGATION INCONCLUSIVE`:**
- Show what was checked
- Offer: Continue / Manual / Add more context

## 6. Shutdown team

```
SendMessage(type="shutdown_request", recipient="debugger", content="Debug complete")
SendMessage(type="shutdown_request", recipient="researcher", content="Debug complete")
TeamDelete()
```

</process>

<success_criteria>
- [ ] Team created (tgsd-debug-slug)
- [ ] Active sessions checked
- [ ] Symptoms gathered (if new)
- [ ] team-debugger and team-researcher spawned in parallel
- [ ] Agents communicated findings via SendMessage
- [ ] Root cause confirmed before fixing
- [ ] Debug file created/updated in .planning/debug/
- [ ] Team shut down and cleaned up
</success_criteria>

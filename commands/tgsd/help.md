---
name: tgsd:help
description: Show available Team GSD commands and usage guide
---

<objective>
Display the complete Team GSD command reference.

Output ONLY the reference content below. Do NOT add:

- Project-specific analysis
- Git status or file context
- Next-step suggestions
- Any commentary beyond the reference
</objective>

<reference>
# TGSD Command Reference

**TGSD** (Team GSD) runs GSD workflows using a **team of coordinating agents**. Same GSD guarantees (atomic commits, state tracking, verification) but with parallel agent execution and inter-agent communication.

## Quick Start

1. `/tgsd:quick` - Team-based quick task (planner + executor in parallel)
2. `/tgsd:plan-phase 1` - Plan phase with team (researcher + planner + checker coordinate)
3. `/tgsd:execute-phase 1` - Execute phase with team (parallel executors + verifier)

## TGSD vs GSD

| Feature | GSD (solo) | TGSD (team) |
|---------|-----------|-------------|
| Agents | Sequential, isolated | Parallel, communicating |
| Execution | One agent at a time | Multiple agents simultaneously |
| Communication | Hub-and-spoke via orchestrator | Mesh via SendMessage + TaskList |
| Speed | Predictable | Faster for multi-plan phases |
| Context | Fresh per agent | Fresh per agent + shared TaskList |
| Default profile | balanced | quality (Opus 4.6, 200k context) |

## Context Budget

Each agent gets a fresh 200k context window.

| Threshold | % of Window | Tokens |
|-----------|-------------|--------|
| Target | 40% | 80k tokens |
| Warning | 60% | 120k tokens |
| Blocker | 70% | 140k tokens |

All models use 200k context window.

Scope thresholds:

| Metric | Target | Blocker |
|--------|--------|---------|
| Tasks/plan | 2-3 | 5+ |
| Files/plan | 5-8 | 15+ |

Default profile: **quality** (Opus 4.6 for primary agents). Change with `/gsd:set-profile`.

## When to Use TGSD

- Phase has 3+ plans (parallel executors)
- Complex phase needing research + planning simultaneously
- Multi-plan debugging (team-debugger + team-executor)
- Large milestone execution

## When to Use GSD (solo)

- Single quick task
- Simple 1-2 plan phases
- Debugging a single issue
- When you want predictable sequential flow

## Commands

### Project & Milestone

### `/tgsd:new-project`
Initialize a new project with team-coordinated research.

- Same flow as `/gsd:new-project` but research uses 4 parallel team-researchers
- Researchers share findings via SendMessage

Usage: `/tgsd:new-project`

### `/tgsd:new-milestone <name>`
Start a new milestone with team research.

- 4 parallel team-researchers + synthesizer
- Researchers communicate discoveries to each other
- Same `.planning/` output as `/gsd:new-milestone`

Usage: `/tgsd:new-milestone "v2.0 Backend"`

### `/tgsd:map-codebase`
Map codebase with team of parallel mappers.

- 4 team-codebase-mappers (tech, arch, quality, concerns)
- Mappers share discoveries (e.g., arch mapper alerts concerns mapper about circular deps)
- Same `.planning/codebase/` output

Usage: `/tgsd:map-codebase`

### Phase Workflow

### `/tgsd:quick`
Team-based quick task execution.

- Creates team: team-planner + team-executor
- Planner creates plan, executor implements in parallel
- Same `.planning/quick/` structure as `/gsd:quick`

Usage: `/tgsd:quick`

### `/tgsd:plan-phase <number>`
Plan phase with coordinating team.

- Creates team: team-researcher + team-planner + team-plan-checker
- Researcher and planner can work in parallel
- Checker verifies plans and communicates issues directly to planner
- Same `.planning/phases/` output as `/gsd:plan-phase`

Flags: `[--research]` `[--skip-research]` `[--gaps]` `[--skip-verify]`

Usage: `/tgsd:plan-phase 3`

### `/tgsd:execute-phase <number>`
Execute phase with parallel team.

- Creates team: N x team-executor + team-verifier
- All wave-1 executors run simultaneously
- Executors share commit status via TaskList
- Verifier starts automatically when all executors finish
- Same wave-based execution as `/gsd:execute-phase`

Flags: `[--gaps-only]`

Usage: `/tgsd:execute-phase 5`

### `/tgsd:debug [issue]`
Debug with team support.

- Creates team: team-debugger + team-researcher
- Debugger investigates, researcher looks up docs/patterns
- Share findings via SendMessage
- Same `.planning/debug/` tracking as `/gsd:debug`

Usage: `/tgsd:debug "form doesn't submit"`

### Verification & Audit

### `/tgsd:audit-milestone [version]`
Audit milestone with parallel verification team.

- Creates team: team-verifier + team-integration-checker
- Both run in parallel, share findings
- Same MILESTONE-AUDIT.md output

Usage: `/tgsd:audit-milestone`

### Utilities

### `/tgsd:progress`
Check project progress (routes to tgsd commands).

- Same status report as `/gsd:progress`
- Routes to `/tgsd:*` commands instead of `/gsd:*`

Usage: `/tgsd:progress`

### `/tgsd:shutdown`
Gracefully shut down all active team agents.

- Sends shutdown request to all active teammates
- Cleans up team resources
- Use when done with team session

Usage: `/tgsd:shutdown`

## Team Architecture

```
You (team lead)
├── team-planner ──── SendMessage ────→ team-researcher
│                 ←── SendMessage ────┘
├── team-executor-1 ── TaskUpdate ──→ shared TaskList
├── team-executor-2 ── TaskUpdate ──→ shared TaskList
├── team-verifier ←─── TaskList ────← (reads executor results)
└── team-debugger ──── SendMessage ──→ team-executor
```

## Agent Inventory

| Agent | Role | Communicates With |
|-------|------|-------------------|
| team-executor | Implements plans, atomic commits | team-lead, team-verifier |
| team-verifier | Goal-backward verification | team-lead, team-executor |
| team-planner | Creates execution plans | team-lead, team-researcher, team-executor |
| team-debugger | Scientific method debugging | team-lead, team-researcher, team-executor |
| team-researcher | Researches implementation approaches | team-lead, team-planner |
| team-plan-checker | Verifies plan quality | team-lead, team-planner |
| team-codebase-mapper | Analyzes codebase structure | team-lead, team-planner |
| team-integration-checker | Verifies E2E flows | team-lead, team-verifier, team-executor |

## Common Workflows

**Quick team task:**
```
/tgsd:quick
```

**Full phase with team:**
```
/tgsd:plan-phase 3
/clear
/tgsd:execute-phase 3
```

**Team debugging:**
```
/tgsd:debug "API returns 500 on save"
```

## Files & Structure

Same as GSD — all artifacts go to `.planning/`. Team metadata is temporary (cleaned up after shutdown).
</reference>

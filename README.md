# GSD Team Agents

Custom agent definitions for [Claude Code](https://claude.com/claude-code) combining **GSD workflow protocols** with **Team communication capabilities**.

## Agent Types

### Solo Agents (`agents/solo/`)

Standard GSD agents — hub-and-spoke architecture, no inter-agent communication.

| Agent | Role | Lines |
|-------|------|-------|
| `gsd-executor` | Executes plans with atomic commits, checkpoints, TDD | 824 |
| `gsd-verifier` | Goal-backward verification of built features | 778 |
| `gsd-planner` | Creates execution plans with task breakdown | 1418 |
| `gsd-debugger` | Scientific method debugging with persistent state | 1203 |
| `gsd-phase-researcher` | Researches implementation approaches | 669 |
| `gsd-plan-checker` | Verifies plan quality across 7 dimensions | 812 |
| `gsd-codebase-mapper` | Analyzes codebase structure | 761 |
| `gsd-integration-checker` | Verifies E2E flows and cross-phase wiring | 423 |
| `gsd-project-researcher` | Domain research for new projects | — |
| `gsd-research-synthesizer` | Synthesizes parallel research outputs | — |
| `gsd-roadmapper` | Creates project roadmaps | — |

### Team Agents (`agents/team/`)

Team-enabled versions — all GSD protocols preserved + `SendMessage`, `TaskList`, `TaskUpdate`, `TaskCreate`, `TaskGet` for inter-agent coordination.

| Agent | Based On | Added |
|-------|----------|-------|
| `team-executor` | gsd-executor | Status updates, blocker reporting, commit sharing |
| `team-verifier` | gsd-verifier | Gap notifications, verification result sharing |
| `team-planner` | gsd-planner | Plan broadcasting, task delegation, wave assignments |
| `team-debugger` | gsd-debugger | Evidence sharing, fix coordination |
| `team-researcher` | gsd-phase-researcher | Research findings sharing, team-planner coordination |
| `team-plan-checker` | gsd-plan-checker | Issue reporting to planner, approval notifications |
| `team-codebase-mapper` | gsd-codebase-mapper | Document ready notifications, concern alerts |
| `team-integration-checker` | gsd-integration-checker | Broken flow reports, integration issue alerts |

## Installation

### One-liner (from GitHub)

```bash
cd your-project
curl -sSL https://raw.githubusercontent.com/kirdudko-hub/GSD-Team/main/install.sh | bash
```

Install specific components:

```bash
curl -sSL https://raw.githubusercontent.com/kirdudko-hub/GSD-Team/main/install.sh | bash -s solo      # GSD agents only
curl -sSL https://raw.githubusercontent.com/kirdudko-hub/GSD-Team/main/install.sh | bash -s team      # team agents + /tgsd:* commands
curl -sSL https://raw.githubusercontent.com/kirdudko-hub/GSD-Team/main/install.sh | bash -s commands   # /tgsd:* commands only
```

### From cloned repo

```bash
git clone https://github.com/kirdudko-hub/GSD-Team.git
cd your-project
bash /path/to/GSD-Team/install.sh          # all
bash /path/to/GSD-Team/install.sh team     # team agents + commands
```

### Manual

```bash
mkdir -p .claude/agents .claude/commands/tgsd
cp /path/to/GSD-Team/agents/team/*.md .claude/agents/
cp /path/to/GSD-Team/commands/tgsd/*.md .claude/commands/tgsd/
```

## Usage

### Solo Mode (GSD commands)

Use with standard GSD slash commands:
```
/gsd:plan-phase
/gsd:execute-phase
/gsd:debug
```

### Team Mode (`/tgsd:*` commands)

#### Project & Milestone

| Command | Description | Team Agents |
|---------|-------------|-------------|
| `/tgsd:new-project` | Initialize new project with team research | 4x team-researcher + synthesizer |
| `/tgsd:new-milestone <name>` | Start new milestone with team research | 4x team-researcher + synthesizer + roadmapper |
| `/tgsd:map-codebase` | Map codebase with parallel mappers | 4x team-codebase-mapper (tech, arch, quality, concerns) |

#### Phase Workflow

| Command | Description | Team Agents |
|---------|-------------|-------------|
| `/tgsd:quick` | Quick task with team coordination | team-planner + team-executor |
| `/tgsd:plan-phase <N>` | Plan phase with coordinating team | team-researcher + team-planner + team-plan-checker |
| `/tgsd:execute-phase <N>` | Execute phase with parallel executors | Nx team-executor + team-verifier |
| `/tgsd:debug [issue]` | Debug with team support | team-debugger + team-researcher |

Flags for `plan-phase`: `--research`, `--skip-research`, `--gaps`, `--skip-verify`
Flags for `execute-phase`: `--gaps-only`

#### Verification & Utilities

| Command | Description | Team Agents |
|---------|-------------|-------------|
| `/tgsd:audit-milestone` | Audit milestone with parallel verification | team-verifier + team-integration-checker |
| `/tgsd:progress` | Check progress, route to `/tgsd:*` commands | — |
| `/tgsd:shutdown` | Gracefully shut down all active agents | — |
| `/tgsd:help` | Show full command reference | — |

#### Common Workflows

```bash
# Quick team task
/tgsd:quick

# Full phase with team
/tgsd:plan-phase 3
/clear
/tgsd:execute-phase 3

# Team debugging
/tgsd:debug "API returns 500 on save"

# New project from scratch
/tgsd:new-project
/tgsd:plan-phase 1
/tgsd:execute-phase 1
```

## Architecture

```
Solo (hub-and-spoke):        Team (mesh):

  Orchestrator               Team Lead
  ├── executor               ├── team-executor ←→ team-verifier
  ├── verifier               ├── team-planner ←→ team-researcher
  ├── planner                ├── team-debugger ←→ team-executor
  └── ...                    └── shared TaskList
```

Each team agent adds a `<team_protocol>` section that defines:
- **When to message** other agents
- **What to include** in messages
- **How to track** tasks via TaskList/TaskUpdate
- **Who to notify** for specific events

## Statusline

Custom status bar for Claude Code showing real-time session info:

```
⬆ Opus │ Fixing auth bug [3/7 42%] loggsd ██░░░░░░░░ 19% 150k/1.0M in:150k out:45k $1.23 5m25s
team: ⚡executor-01 │ ⚡executor-02 │ ✓ verifier  tasks: 2/5 (40%)
```

**Line 1:** model | current task + progress | directory | context bar + tokens | usage in/out | cost + duration

**Line 2** (when team is active): agent icons + names | team task progress

Installed automatically with `team` or `all` mode. Configures `.claude/settings.json` to use the statusline hook.

### Agent Icons

| Icon | Agent Type |
|------|-----------|
| ⚡ | executor |
| 📋 | planner |
| ✓ | verifier |
| 🔍 | debugger |
| 🔬 | researcher |
| ☑ | plan-checker |
| 🗺 | codebase-mapper |

## Context Budget

TGSD agents manage context budget to prevent quality degradation. Each subagent gets a **fresh context window** — the orchestrator stays lean (~10-15% usage).

### Context Windows by Model

| Model | Context Window | Default Profile |
|-------|---------------|-----------------|
| **Opus 4.6** | 1,000,000 tokens | quality (default) |
| **Sonnet 4.5** | 200,000 tokens | balanced |
| **Haiku 4.5** | 200,000 tokens | budget |

### Budget Thresholds

Plans must complete within the target zone. Quality degrades as context fills:

| Zone | % of Window | Opus (1M) | Sonnet/Haiku (200k) |
|------|-------------|-----------|---------------------|
| **Target** | 40% | 400k tokens | 80k tokens |
| **Warning** | 60% | 600k tokens | 120k tokens |
| **Blocker** | 70% | 700k tokens | 140k tokens |

### Scope Thresholds by Model

Opus can handle larger plans due to its 5x larger context window:

| Metric | Opus target | Opus blocker | Sonnet/Haiku target | Sonnet/Haiku blocker |
|--------|-------------|--------------|---------------------|----------------------|
| Tasks/plan | 3-4 | 6+ | 2-3 | 5+ |
| Files/plan | 8-12 | 20+ | 5-8 | 15+ |

### Model Profiles

Set via `/gsd:set-profile`:

| Profile | Primary Agents | Verification/Support | Best For |
|---------|---------------|---------------------|----------|
| **quality** (default) | Opus 4.6 (1M context) | Sonnet 4.5 | Production projects |
| **balanced** | Opus for planner, Sonnet for rest | Sonnet 4.5 | Cost-conscious quality |
| **budget** | Sonnet 4.5 | Haiku 4.5 | Quick experiments |

### Agent Model Assignments

| Agent | quality | balanced | budget |
|-------|---------|----------|--------|
| team-executor | opus | sonnet | sonnet |
| team-planner | opus | opus | sonnet |
| team-debugger | opus | sonnet | sonnet |
| team-verifier | sonnet | sonnet | haiku |
| team-researcher | opus | sonnet | haiku |
| team-plan-checker | sonnet | sonnet | haiku |
| team-codebase-mapper | sonnet | sonnet | haiku |
| team-integration-checker | sonnet | sonnet | haiku |

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI
- [GSD Plugin](https://github.com/mcp-get/gsd) (for `/gsd:*` commands)

## Security

This repository contains only agent definitions and command templates. No API keys, tokens, or credentials are included. **Do not commit actual secrets or credentials to this repository.**

## License

MIT

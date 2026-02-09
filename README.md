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

### Team Mode

Create a team and spawn agents:
```
TeamCreate → TaskCreate → Task (subagent_type: "team-executor", team_name: "my-team")
```

Team agents will:
- Claim tasks from shared TaskList
- Send status updates via SendMessage
- Coordinate with each other on findings
- Follow all GSD protocols (atomic commits, checkpoints, verification)

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

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI
- [GSD Plugin](https://github.com/mcp-get/gsd) (for `/gsd:*` commands)

## Security

This repository contains only agent definitions and command templates. No API keys, tokens, or credentials are included. **Do not commit actual secrets or credentials to this repository.**

## License

MIT

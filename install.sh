#!/bin/bash
# GSD Team Agents — Install Script
# Copies agents and/or commands into your project's .claude/ directory
#
# Usage:
#   cd your-project
#   bash /path/to/GSD-Team/install.sh [solo|team|commands|all]
#
# Default: all (agents + commands)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-all}"
AGENTS_TARGET=".claude/agents"
COMMANDS_TARGET=".claude/commands/tgsd"

install_solo() {
  mkdir -p "$AGENTS_TARGET"
  cp "$SCRIPT_DIR/agents/solo/"*.md "$AGENTS_TARGET/"
  echo "  $(ls "$SCRIPT_DIR/agents/solo/"*.md | wc -l | tr -d ' ') solo agents installed."
}

install_team() {
  mkdir -p "$AGENTS_TARGET"
  cp "$SCRIPT_DIR/agents/team/"*.md "$AGENTS_TARGET/"
  echo "  $(ls "$SCRIPT_DIR/agents/team/"*.md | wc -l | tr -d ' ') team agents installed."
}

install_commands() {
  mkdir -p "$COMMANDS_TARGET"
  cp "$SCRIPT_DIR/commands/tgsd/"*.md "$COMMANDS_TARGET/"
  echo "  $(ls "$SCRIPT_DIR/commands/tgsd/"*.md | wc -l | tr -d ' ') tgsd commands installed."
}

case "$MODE" in
  solo)
    echo "Installing solo GSD agents..."
    install_solo
    ;;
  team)
    echo "Installing team GSD agents + tgsd commands..."
    install_team
    install_commands
    ;;
  commands)
    echo "Installing tgsd commands only..."
    install_commands
    ;;
  all)
    echo "Installing everything (solo + team agents + tgsd commands)..."
    install_solo
    install_team
    install_commands
    ;;
  *)
    echo "Usage: $0 [solo|team|commands|all]"
    echo ""
    echo "  solo     — GSD agents (standard, no inter-agent communication)"
    echo "  team     — Team agents + /tgsd:* commands"
    echo "  commands — Only /tgsd:* slash commands"
    echo "  all      — Everything (default)"
    exit 1
    ;;
esac

echo ""
echo "Installed to: .claude/"
echo ""
echo "Available commands:"
echo "  /gsd:help   — Solo GSD commands"
echo "  /tgsd:help  — Team GSD commands"

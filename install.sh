#!/bin/bash
# GSD Team Agents — Install Script
# Copies agents into your project's .claude/agents/ directory
#
# Usage:
#   cd your-project
#   bash /path/to/GSD-Team/install.sh [solo|team|all]
#
# Default: all (both solo and team agents)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-all}"
TARGET=".claude/agents"

mkdir -p "$TARGET"

case "$MODE" in
  solo)
    echo "Installing solo GSD agents..."
    cp "$SCRIPT_DIR/agents/solo/"*.md "$TARGET/"
    echo "Done. $(ls "$SCRIPT_DIR/agents/solo/"*.md | wc -l | tr -d ' ') solo agents installed."
    ;;
  team)
    echo "Installing team GSD agents..."
    cp "$SCRIPT_DIR/agents/team/"*.md "$TARGET/"
    echo "Done. $(ls "$SCRIPT_DIR/agents/team/"*.md | wc -l | tr -d ' ') team agents installed."
    ;;
  all)
    echo "Installing all GSD agents (solo + team)..."
    cp "$SCRIPT_DIR/agents/solo/"*.md "$TARGET/"
    cp "$SCRIPT_DIR/agents/team/"*.md "$TARGET/"
    TOTAL=$(ls "$SCRIPT_DIR/agents/solo/"*.md "$SCRIPT_DIR/agents/team/"*.md | wc -l | tr -d ' ')
    echo "Done. $TOTAL agents installed."
    ;;
  *)
    echo "Usage: $0 [solo|team|all]"
    exit 1
    ;;
esac

echo "Agents installed to: $TARGET/"

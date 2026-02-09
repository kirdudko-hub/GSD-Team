#!/bin/bash
# GSD Team Agents — Universal Install Script
#
# Remote install (from GitHub):
#   curl -sSL https://raw.githubusercontent.com/kirdudko-hub/GSD-Team/main/install.sh | bash
#   curl -sSL https://raw.githubusercontent.com/kirdudko-hub/GSD-Team/main/install.sh | bash -s team
#
# Local install (cloned repo):
#   cd your-project
#   bash /path/to/GSD-Team/install.sh [solo|team|commands|all]
#
# Default: all (agents + commands)

set -e

REPO_URL="https://github.com/kirdudko-hub/GSD-Team.git"
REPO_RAW="https://raw.githubusercontent.com/kirdudko-hub/GSD-Team/main"
MODE="${1:-all}"
AGENTS_TARGET=".claude/agents"
COMMANDS_TARGET=".claude/commands/tgsd"

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

header() { echo -e "\n${BOLD}${CYAN}$1${NC}"; }
ok()     { echo -e "  ${GREEN}✓${NC} $1"; }
err()    { echo -e "  ${RED}✗${NC} $1"; exit 1; }

# ─── Detect local vs remote ───
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" 2>/dev/null && pwd 2>/dev/null)"

is_local() {
  [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/agents/solo" ] && [ -d "$SCRIPT_DIR/agents/team" ]
}

# ─── Remote download helpers ───
TMPDIR_CLEAN=""

setup_remote() {
  if command -v git &>/dev/null; then
    header "Cloning GSD-Team from GitHub..."
    TMPDIR_CLEAN=$(mktemp -d)
    git clone --depth 1 --quiet "$REPO_URL" "$TMPDIR_CLEAN/GSD-Team" 2>/dev/null
    SCRIPT_DIR="$TMPDIR_CLEAN/GSD-Team"
    ok "Cloned successfully"
  elif command -v curl &>/dev/null; then
    header "Downloading GSD-Team from GitHub..."
    TMPDIR_CLEAN=$(mktemp -d)
    SCRIPT_DIR="$TMPDIR_CLEAN/GSD-Team"
    mkdir -p "$SCRIPT_DIR/agents/solo" "$SCRIPT_DIR/agents/team" "$SCRIPT_DIR/commands/tgsd"
    download_files
    ok "Downloaded successfully"
  else
    err "Requires git or curl. Install one and retry."
  fi
}

download_files() {
  # Solo agents
  for f in gsd-codebase-mapper gsd-debugger gsd-executor gsd-integration-checker \
           gsd-phase-researcher gsd-plan-checker gsd-planner gsd-project-researcher \
           gsd-research-synthesizer gsd-roadmapper gsd-verifier; do
    curl -sSL "$REPO_RAW/agents/solo/${f}.md" -o "$SCRIPT_DIR/agents/solo/${f}.md"
  done

  # Team agents
  for f in team-codebase-mapper team-debugger team-executor team-integration-checker \
           team-plan-checker team-planner team-researcher team-verifier; do
    curl -sSL "$REPO_RAW/agents/team/${f}.md" -o "$SCRIPT_DIR/agents/team/${f}.md"
  done

  # TGSD commands
  for f in audit-milestone debug execute-phase help map-codebase new-milestone \
           new-project plan-phase progress quick shutdown; do
    curl -sSL "$REPO_RAW/commands/tgsd/${f}.md" -o "$SCRIPT_DIR/commands/tgsd/${f}.md"
  done
}

cleanup() {
  if [ -n "$TMPDIR_CLEAN" ] && [ -d "$TMPDIR_CLEAN" ]; then
    rm -rf "$TMPDIR_CLEAN"
  fi
}
trap cleanup EXIT

# ─── Install functions ───
install_solo() {
  mkdir -p "$AGENTS_TARGET"
  cp "$SCRIPT_DIR/agents/solo/"*.md "$AGENTS_TARGET/"
  local count
  count=$(ls -1 "$SCRIPT_DIR/agents/solo/"*.md 2>/dev/null | wc -l | tr -d ' ')
  ok "$count solo agents installed"
}

install_team() {
  mkdir -p "$AGENTS_TARGET"
  cp "$SCRIPT_DIR/agents/team/"*.md "$AGENTS_TARGET/"
  local count
  count=$(ls -1 "$SCRIPT_DIR/agents/team/"*.md 2>/dev/null | wc -l | tr -d ' ')
  ok "$count team agents installed"
}

install_commands() {
  mkdir -p "$COMMANDS_TARGET"
  cp "$SCRIPT_DIR/commands/tgsd/"*.md "$COMMANDS_TARGET/"
  local count
  count=$(ls -1 "$SCRIPT_DIR/commands/tgsd/"*.md 2>/dev/null | wc -l | tr -d ' ')
  ok "$count /tgsd:* commands installed"
}

# ─── Usage ───
show_usage() {
  echo ""
  echo "Usage: $0 [solo|team|commands|all]"
  echo ""
  echo "  solo     — GSD agents (standard, no inter-agent communication)"
  echo "  team     — Team agents + /tgsd:* commands"
  echo "  commands — Only /tgsd:* slash commands"
  echo "  all      — Everything (default)"
  echo ""
  echo "Remote:"
  echo "  curl -sSL $REPO_RAW/install.sh | bash"
  echo "  curl -sSL $REPO_RAW/install.sh | bash -s team"
  exit 1
}

# ─── Main ───
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD} GSD Team Agents — Installer${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Detect source
if is_local; then
  echo -e "\nSource: ${CYAN}local${NC} ($SCRIPT_DIR)"
else
  setup_remote
fi

# Validate mode
case "$MODE" in
  solo|team|commands|all) ;;
  -h|--help|help) show_usage ;;
  *) show_usage ;;
esac

# Execute
header "Installing ($MODE)..."

case "$MODE" in
  solo)
    install_solo
    ;;
  team)
    install_team
    install_commands
    ;;
  commands)
    install_commands
    ;;
  all)
    install_solo
    install_team
    install_commands
    ;;
esac

# Summary
TOTAL_AGENTS=$(ls -1 "$AGENTS_TARGET/"*.md 2>/dev/null | wc -l | tr -d ' ')
TOTAL_COMMANDS=$(ls -1 "$COMMANDS_TARGET/"*.md 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD} Installation complete${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Agents:   ${BOLD}$TOTAL_AGENTS${NC} files in $AGENTS_TARGET/"
echo -e "  Commands: ${BOLD}$TOTAL_COMMANDS${NC} files in $COMMANDS_TARGET/"
echo ""
echo "  /gsd:help   — Solo GSD commands"
echo "  /tgsd:help  — Team GSD commands"
echo ""

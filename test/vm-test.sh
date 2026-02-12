#!/usr/bin/env bash
# CCA Plugin — Automated Install Test
#
# Runs a fresh Ubuntu container (Docker on Linux, OrbStack on macOS)
# and tests the full install flow end-to-end.
#
# Requirements:
#   - Docker OR OrbStack
#   - Claude Code authenticated on the host (for credential copy)
#
# Usage:
#   ./test/vm-test.sh              # Full test (create, test, destroy)
#   ./test/vm-test.sh --keep       # Keep container after test for debugging
#   ./test/vm-test.sh --cleanup    # Just destroy test containers
#
# What it tests:
#   1. Fresh Ubuntu environment with no prior setup
#   2. Marketplace registers via CLI
#   3. Both plugins install from marketplace
#   4. Plugins persist in installed_plugins.json
#   5. Claude can start with plugins loaded (non-interactive, requires auth)

set -euo pipefail

# ── Config ──────────────────────────────────────────────────────

CONTAINER="cca-test-$(date +%s)"
KEEP=false
CLEANUP_ONLY=false
PASS=0
FAIL=0
TESTS=()
RUNTIME=""

# ── Parse args ──────────────────────────────────────────────────

for arg in "$@"; do
  case "$arg" in
    --keep) KEEP=true ;;
    --cleanup) CLEANUP_ONLY=true ;;
  esac
done

# ── Helpers ─────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

log()  { echo -e "  ${CYAN}▸${RESET} $1"; }
pass() { echo -e "  ${GREEN}✔${RESET} $1"; PASS=$((PASS + 1)); TESTS+=("PASS: $1"); }
fail() { echo -e "  ${RED}✘${RESET} $1"; FAIL=$((FAIL + 1)); TESTS+=("FAIL: $1"); }
warn() { echo -e "  ${YELLOW}!${RESET} $1"; }

run_in() {
  docker exec "$CONTAINER" bash -c "$1"
}

# ── Detect runtime ─────────────────────────────────────────────

if command -v docker &>/dev/null; then
  RUNTIME="docker"
elif command -v orb &>/dev/null; then
  RUNTIME="orb"
else
  echo "  Neither Docker nor OrbStack found. Install one first."
  exit 1
fi

# ── Cleanup mode ────────────────────────────────────────────────

if [ "$CLEANUP_ONLY" = true ]; then
  echo ""
  echo "  Cleaning up CCA test containers..."
  docker ps -a --filter "name=cca-test-" --format "{{.Names}}" 2>/dev/null | while read -r c; do
    log "Removing $c..."
    docker rm -f "$c" 2>/dev/null || true
  done
  echo "  Done."
  exit 0
fi

# ── Pre-flight (host) ──────────────────────────────────────────

echo ""
echo "  CCA Plugin — Install Test ${DIM}($RUNTIME)${RESET}"
echo "  ─────────────────────────────"
echo ""

CREDS="$HOME/.claude/.credentials.json"
if [ ! -f "$CREDS" ] || [ ! -s "$CREDS" ]; then
  warn "No Claude credentials found at $CREDS"
  warn "The test will install plugins but can't verify Claude launches."
  warn "Run 'claude' on this machine first to authenticate."
  NO_AUTH=true
else
  NO_AUTH=false
fi

# ── Create container ───────────────────────────────────────────

log "Creating Ubuntu container: $CONTAINER"
docker run -d \
  --name "$CONTAINER" \
  --hostname cca-test \
  ubuntu:24.04 \
  sleep infinity >/dev/null

log "Installing prerequisites (git, curl, Node.js 22, Claude Code)..."

# Install everything in one layer for speed
run_in '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq git curl ca-certificates gnupg >/dev/null 2>&1

  # Node.js 22 via nodesource
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq nodejs >/dev/null 2>&1

  # Claude Code
  npm install -g @anthropic-ai/claude-code >/dev/null 2>&1
'

# ── Verify prerequisites ──────────────────────────────────────

echo ""
log "Verifying prerequisites..."

if run_in "command -v git" &>/dev/null; then
  pass "git installed"
else
  fail "git not installed"
fi

if run_in "command -v node" &>/dev/null; then
  NODE_VER=$(run_in "node --version" 2>/dev/null)
  pass "Node.js installed ($NODE_VER)"
else
  fail "Node.js not installed"
fi

if run_in "command -v claude" &>/dev/null; then
  CLAUDE_VER=$(run_in "claude --version" 2>/dev/null)
  pass "Claude Code installed ($CLAUDE_VER)"
else
  fail "Claude Code not installed — remaining tests will fail"
fi

# ── Copy auth credentials ──────────────────────────────────────

if [ "$NO_AUTH" = false ]; then
  log "Copying auth credentials..."
  run_in "mkdir -p /root/.claude"
  docker cp "$CREDS" "$CONTAINER:/root/.claude/.credentials.json"
  run_in "chmod 600 /root/.claude/.credentials.json"
  pass "Auth credentials copied"
fi

# ── Configure git for HTTPS (env-only, no global config changes) ──

# GIT_CONFIG_COUNT lets us override git config via env vars — ephemeral, no side effects
GIT_ENV='export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf" GIT_CONFIG_VALUE_0="git@github.com:"'

# ── Test: Marketplace add ──────────────────────────────────────

echo ""
log "Adding CCA marketplace..."

MARKETPLACE_OUTPUT=$(run_in "$GIT_ENV && claude plugin marketplace add blakesims/cca-marketplace 2>&1" || true)
echo -e "    ${DIM}${MARKETPLACE_OUTPUT}${RESET}"

if echo "$MARKETPLACE_OUTPUT" | grep -qi "success\|added"; then
  pass "Marketplace added"
else
  fail "Marketplace add failed"
fi

# ── Test: Plugin install ───────────────────────────────────────

log "Installing cca-plugin..."
CCA_OUTPUT=$(run_in "$GIT_ENV && claude plugin install cca-plugin@cca-marketplace --scope user 2>&1" || true)
echo -e "    ${DIM}${CCA_OUTPUT}${RESET}"

if echo "$CCA_OUTPUT" | grep -qi "success"; then
  pass "cca-plugin installed"
else
  fail "cca-plugin install failed"
fi

log "Installing task-workflow..."
TW_OUTPUT=$(run_in "$GIT_ENV && claude plugin install task-workflow@cca-marketplace --scope user 2>&1" || true)
echo -e "    ${DIM}${TW_OUTPUT}${RESET}"

if echo "$TW_OUTPUT" | grep -qi "success"; then
  pass "task-workflow installed"
else
  fail "task-workflow install failed"
fi

# ── Test: Marketplace registered ───────────────────────────────

echo ""
log "Verifying marketplace list..."

MARKETPLACE_LIST=$(run_in "claude plugin marketplace list 2>&1" || true)

if echo "$MARKETPLACE_LIST" | grep -q "cca-marketplace"; then
  pass "Marketplace 'cca-marketplace' in list"
else
  fail "Marketplace 'cca-marketplace' not in list"
  echo "    Got: $MARKETPLACE_LIST"
fi

# ── Test: Plugins in list ──────────────────────────────────────

log "Verifying plugin list..."

PLUGIN_LIST=$(run_in "claude plugin list 2>&1" || true)

if echo "$PLUGIN_LIST" | grep -q "cca-plugin@cca-marketplace"; then
  pass "cca-plugin in plugin list"
else
  fail "cca-plugin not in plugin list"
fi

if echo "$PLUGIN_LIST" | grep -q "task-workflow@cca-marketplace"; then
  pass "task-workflow in plugin list"
else
  fail "task-workflow not in plugin list"
fi

if echo "$PLUGIN_LIST" | grep -q "enabled"; then
  pass "Plugins are enabled"
else
  fail "Plugins not enabled"
fi

# ── Test: Persistence ──────────────────────────────────────────

log "Checking persistence (installed_plugins.json)..."

PERSIST=$(run_in "cat /root/.claude/plugins/installed_plugins.json 2>/dev/null || echo NO_FILE")

if echo "$PERSIST" | grep -q "cca-plugin@cca-marketplace"; then
  pass "cca-plugin persisted"
else
  fail "cca-plugin not persisted"
fi

if echo "$PERSIST" | grep -q "task-workflow@cca-marketplace"; then
  pass "task-workflow persisted"
else
  fail "task-workflow not persisted"
fi

# ── Test: Claude sees plugins (non-interactive) ────────────────

if [ "$NO_AUTH" = false ]; then
  log "Testing Claude sees plugins (--print mode, may take ~15s)..."

  CLAUDE_OUTPUT=$(run_in '
    timeout 60 claude --print "List every slash command you have available that starts with /cca-plugin: or /task-workflow:. Output ONLY the command names, one per line." 2>&1
  ' || true)

  if echo "$CLAUDE_OUTPUT" | grep -qi "cca-plugin"; then
    pass "Claude sees /cca-plugin commands"
  else
    fail "Claude does not see /cca-plugin commands"
    echo -e "    ${DIM}$(echo "$CLAUDE_OUTPUT" | head -5)${RESET}"
  fi
else
  warn "Skipping Claude launch test (no auth)"
fi

# ── Results ─────────────────────────────────────────────────────

echo ""
echo "  ─────────────────────────────"
echo -e "  Results: ${GREEN}${PASS} passed${RESET}, ${RED}${FAIL} failed${RESET}"
echo ""

for t in "${TESTS[@]}"; do
  if [[ "$t" == PASS:* ]]; then
    echo -e "    ${GREEN}✔${RESET} ${t#PASS: }"
  else
    echo -e "    ${RED}✘${RESET} ${t#FAIL: }"
  fi
done

echo ""

# ── Cleanup ─────────────────────────────────────────────────────

if [ "$KEEP" = true ]; then
  warn "Container kept: $CONTAINER"
  warn "  Shell into it:  docker exec -it $CONTAINER bash"
  warn "  Delete it:      docker rm -f $CONTAINER"
else
  log "Destroying container: $CONTAINER"
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
fi

echo ""

[ "$FAIL" -eq 0 ] || exit 1

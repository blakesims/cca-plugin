#!/usr/bin/env bash
# Claude Code Architects — Plugin Installer
#
# What it does:
#   1. Checks prerequisites (Node.js, git, Claude Code, sign-in)
#   2. Registers the CCA plugin marketplace
#   3. Installs cca-plugin (the student workflow)
#   4. Installs task-workflow (the build engine)
#   5. Launches Claude with a setup message
#
# Plugins persist across sessions — no flags needed after install.
#
# Source: https://github.com/blakesims/cca-plugin

set -e

echo ""
echo "  Claude Code Architects — Installing..."
echo ""

# Detect OS for platform-specific help
case "$(uname -s)" in
  Darwin*) OS="mac" ;;
  Linux*)  OS="linux" ;;
  *)       OS="other" ;;
esac

# ── Check prerequisites one by one ──────────────────────────────

echo "  Checking prerequisites..."
echo ""
READY=true

# 1. Node.js
if ! command -v node &>/dev/null; then
  echo "  [x] Node.js not found"
  case "$OS" in
    mac)   echo "    → brew install node" ;;
    linux) echo "    → curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -"
           echo "    → sudo apt-get install -y nodejs" ;;
    *)     echo "    → Download from https://nodejs.org" ;;
  esac
  echo ""
  READY=false
else
  echo "  [ok] Node.js $(node --version)"
fi

# 2. git
if ! command -v git &>/dev/null; then
  echo "  [x] git not found"
  case "$OS" in
    mac)   echo "    → xcode-select --install" ;;
    linux) echo "    → sudo apt install git" ;;
    *)     echo "    → Download from https://git-scm.com" ;;
  esac
  echo ""
  READY=false
else
  echo "  [ok] git $(git --version | cut -d' ' -f3)"
fi

# 3. Claude Code
if ! command -v claude &>/dev/null; then
  echo "  [x] Claude Code not found"
  echo "    → npm install -g @anthropic-ai/claude-code"
  echo ""
  READY=false
else
  echo "  [ok] Claude Code $(claude --version 2>/dev/null | head -1)"
fi

# 4. Signed in
if [ "$READY" = true ] && [ ! -s "$HOME/.claude/.credentials.json" ]; then
  echo "  [x] Not signed in to Claude"
  echo "    → Run 'claude' to open sign-in, then type /exit when done"
  echo ""
  READY=false
else
  if [ "$READY" = true ]; then
    echo "  [ok] Signed in"
  fi
fi

echo ""

if [ "$READY" = false ]; then
  echo "  Install the missing items above, then re-run:"
  echo "    curl -sSL https://raw.githubusercontent.com/blakesims/cca-plugin/main/install-simple.sh | bash"
  echo ""
  exit 1
fi

# ── Install plugins ─────────────────────────────────────────────

# Use HTTPS for GitHub clones (env-only, no config file changes)
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf"
export GIT_CONFIG_VALUE_0="git@github.com:"

echo "  Adding plugin marketplace..."
if ! claude plugin marketplace add blakesims/cca-marketplace 2>/dev/null; then
  echo "  (already registered)"
fi

echo "  Installing cca-plugin..."
if ! claude plugin install cca-plugin@cca-marketplace --scope user 2>/dev/null; then
  echo ""
  echo "  Plugin install failed. Check your internet connection and try again."
  exit 1
fi

echo "  Installing task-workflow..."
if ! claude plugin install task-workflow@cca-marketplace --scope user 2>/dev/null; then
  echo ""
  echo "  Plugin install failed. Check your internet connection and try again."
  exit 1
fi

echo ""
echo "  Plugins installed! They'll persist across sessions."
echo ""
echo "  Launching Claude..."
echo ""

exec claude "Hi! I just installed Claude Code Architects. Let's set up my project." </dev/tty

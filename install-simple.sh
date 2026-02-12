#!/usr/bin/env bash
# Claude Code Architects — Plugin Installer
#
# This script ONLY installs the CCA plugins. It assumes you already have:
#   - Node.js 18+
#   - Claude Code (npm install -g @anthropic-ai/claude-code)
#   - Claude Code signed in (run 'claude' once to authenticate)
#
# What it does:
#   1. Registers the CCA plugin marketplace
#   2. Installs cca-plugin (the student workflow)
#   3. Installs task-workflow (the build engine)
#   4. Launches Claude with a setup message
#
# Plugins persist across sessions — no flags needed after install.

set -e

echo ""
echo "  Claude Code Architects — Installing plugins..."
echo ""

# Check Claude Code is available
if ! command -v claude &>/dev/null; then
  echo "  Claude Code not found. Install it first:"
  echo "     npm install -g @anthropic-ai/claude-code"
  echo ""
  exit 1
fi

# Use HTTPS for GitHub clones (env-only, no config changes)
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf"
export GIT_CONFIG_VALUE_0="git@github.com:"

# Register the plugin marketplace
echo "  Adding plugin marketplace..."
claude plugin marketplace add blakesims/cca-marketplace 2>/dev/null || true

# Install both plugins (persistent across sessions)
echo "  Installing cca-plugin..."
claude plugin install cca-plugin@cca-marketplace --scope user 2>/dev/null

echo "  Installing task-workflow..."
claude plugin install task-workflow@cca-marketplace --scope user 2>/dev/null

echo ""
echo "  Done! Plugins installed and will persist across sessions."
echo "  Launching Claude..."
echo ""

exec claude "Hi! I just installed Claude Code Architects. Let's set up my project." </dev/tty

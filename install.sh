#!/usr/bin/env bash
set -e

echo ""
echo "  Claude Code Architects — Installing..."
echo ""

if ! command -v claude &>/dev/null; then
  echo "  Claude Code CLI not found."
  echo "  Install it first: https://docs.anthropic.com/en/docs/claude-code"
  echo ""
  exit 1
fi

# ── Register marketplace + install plugins ─────────────────────

echo "  Adding CCA marketplace..."
claude plugin marketplace add blakesims/cca-marketplace 2>&1 | sed 's/^/  /'

echo ""
echo "  Installing plugins..."
claude plugin install cca-plugin@cca-marketplace --scope user 2>&1 | sed 's/^/  /'
claude plugin install task-workflow@cca-marketplace --scope user 2>&1 | sed 's/^/  /'

echo ""
echo "  Done! Launching Claude..."
echo ""

# Launch Claude with an initial message — setup kicks in automatically
exec claude "Hi! I just installed Claude Code Architects. Let's set up my project."

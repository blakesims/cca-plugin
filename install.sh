#!/usr/bin/env bash
set -e

echo ""
echo "  Claude Code Architects — Installing..."
echo ""

if ! command -v git &>/dev/null; then
  echo "  git not found. Install it first:"
  echo "    macOS:  xcode-select --install"
  echo "    Linux:  sudo apt install git"
  echo ""
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "  Claude Code CLI not found."
  echo "  Install it first: https://docs.anthropic.com/en/docs/claude-code"
  echo ""
  exit 1
fi

PLUGIN_DIR="${HOME}/.claude/plugins"
mkdir -p "$PLUGIN_DIR"

# ── Clone / update plugins ─────────────────────────────────────

# task-workflow engine (dependency)
if [ -d "$PLUGIN_DIR/task-workflow/.git" ]; then
  echo "  Updating task-workflow..."
  git -C "$PLUGIN_DIR/task-workflow" pull --quiet 2>/dev/null || true
else
  rm -rf "$PLUGIN_DIR/task-workflow"
  echo "  Cloning task-workflow..."
  git clone --quiet https://github.com/blakesims/task-workflow-plugin.git "$PLUGIN_DIR/task-workflow"
fi

# cca-plugin (student-facing)
if [ -d "$PLUGIN_DIR/cca-plugin/.git" ]; then
  echo "  Updating cca-plugin..."
  git -C "$PLUGIN_DIR/cca-plugin" pull --quiet 2>/dev/null || true
else
  rm -rf "$PLUGIN_DIR/cca-plugin"
  echo "  Cloning cca-plugin..."
  git clone --quiet https://github.com/blakesims/cca-plugin.git "$PLUGIN_DIR/cca-plugin"
fi

# Make statusline script executable
chmod +x "$PLUGIN_DIR/cca-plugin/statusline/cca-status.sh" 2>/dev/null || true

echo ""
echo "  Done! Launching Claude..."
echo ""

# Launch Claude with both plugins and an initial message
exec claude \
  --plugin-dir "$PLUGIN_DIR/cca-plugin" \
  --plugin-dir "$PLUGIN_DIR/task-workflow" \
  "Hi! I just installed Claude Code Architects. Let's set up my project."

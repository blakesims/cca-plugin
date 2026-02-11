#!/usr/bin/env bash
set -e

PLUGIN_DIR="${HOME}/.claude/plugins"
mkdir -p "$PLUGIN_DIR"

echo "Installing Claude Code Architects..."
echo ""

# ── Clone / update repos ──────────────────────────────────────

# task-workflow engine (dependency)
if [ -d "$PLUGIN_DIR/task-workflow/.git" ]; then
  echo "  Updating task-workflow..."
  git -C "$PLUGIN_DIR/task-workflow" pull --quiet
else
  rm -rf "$PLUGIN_DIR/task-workflow"
  echo "  Cloning task-workflow..."
  git clone --quiet https://github.com/blakesims/task-workflow-plugin.git "$PLUGIN_DIR/task-workflow"
fi

# cca-plugin (student-facing)
if [ -d "$PLUGIN_DIR/cca-plugin/.git" ]; then
  echo "  Updating cca-plugin..."
  git -C "$PLUGIN_DIR/cca-plugin" pull --quiet
else
  rm -rf "$PLUGIN_DIR/cca-plugin"
  echo "  Cloning cca-plugin..."
  git clone --quiet https://github.com/blakesims/cca-plugin.git "$PLUGIN_DIR/cca-plugin"
fi

# Make statusline script executable
chmod +x "$PLUGIN_DIR/cca-plugin/statusline/cca-status.sh" 2>/dev/null || true

echo ""

# ── Register plugins (persistent — no --plugin-dir flags needed) ──

if command -v claude &>/dev/null; then
  echo "  Registering plugins with Claude Code..."

  # Install both plugins to user scope so they load automatically
  claude plugin install "$PLUGIN_DIR/task-workflow" --scope user 2>/dev/null || true
  claude plugin install "$PLUGIN_DIR/cca-plugin" --scope user 2>/dev/null || true

  echo ""
  echo "Done! Both plugins are registered — just run 'claude' normally."
  echo ""
  echo "Next steps:"
  echo "  1. cd into your project directory (or mkdir a new one)"
  echo "  2. Run: claude"
  echo "  3. Type: /cca-plugin:setup"
  echo ""
else
  echo "Done! Plugins cloned to $PLUGIN_DIR"
  echo ""
  echo "Claude CLI not found — could not auto-register plugins."
  echo "You'll need to launch with:"
  echo "  claude --plugin-dir $PLUGIN_DIR/cca-plugin --plugin-dir $PLUGIN_DIR/task-workflow"
  echo ""
  echo "Or install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
  echo ""
fi

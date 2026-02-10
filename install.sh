#!/usr/bin/env bash
set -e

PLUGIN_DIR="${HOME}/.claude/plugins"
mkdir -p "$PLUGIN_DIR"

echo "Installing Claude Code Architects..."

# task-workflow engine (dependency)
if [ -d "$PLUGIN_DIR/task-workflow" ]; then
  git -C "$PLUGIN_DIR/task-workflow" pull --quiet
else
  git clone --quiet git@github.com:blakesims/task-workflow-plugin.git "$PLUGIN_DIR/task-workflow"
fi

# cca-plugin (student-facing)
if [ -d "$PLUGIN_DIR/cca-plugin" ]; then
  git -C "$PLUGIN_DIR/cca-plugin" pull --quiet
else
  git clone --quiet git@github.com:blakesims/cca-plugin.git "$PLUGIN_DIR/cca-plugin"
fi

echo ""
echo "Installed. Open a project and run /cca-plugin:setup to get started."

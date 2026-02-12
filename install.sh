#!/usr/bin/env bash
set -e

echo ""
echo "  Claude Code Architects — Installing..."
echo ""

# ── Detect OS ────────────────────────────────────────────────────

OS="unknown"
case "$(uname -s)" in
  Darwin*) OS="mac" ;;
  Linux*)  OS="linux" ;;
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
esac

# ── Pre-flight checks ───────────────────────────────────────────

MISSING=()

# 1. Node.js (required by Claude Code)
if ! command -v node &>/dev/null; then
  MISSING+=("node")
elif [ "$(node -e 'console.log(process.versions.node.split(".")[0] >= 18)' 2>/dev/null)" != "true" ]; then
  MISSING+=("node-upgrade")
fi

# 2. git
if ! command -v git &>/dev/null; then
  MISSING+=("git")
fi

# 3. Claude Code CLI
if ! command -v claude &>/dev/null; then
  MISSING+=("claude")
fi

# ── Show what's missing with exact install commands ──────────────

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "  Almost there! You need to install a few things first."
  echo "  Run these commands, then re-run this installer."
  echo ""

  for dep in "${MISSING[@]}"; do
    case "$dep" in
      node)
        echo "  1) Install Node.js 18+ (needed by Claude Code):"
        case "$OS" in
          mac)
            echo "     brew install node"
            echo "     — or download from https://nodejs.org" ;;
          linux)
            echo "     curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -"
            echo "     sudo apt-get install -y nodejs" ;;
          windows)
            echo "     winget install OpenJS.NodeJS.LTS"
            echo "     — or download from https://nodejs.org" ;;
          *)
            echo "     Download from https://nodejs.org" ;;
        esac
        echo ""
        ;;

      node-upgrade)
        CURRENT_NODE=$(node --version 2>/dev/null || echo "unknown")
        echo "  1) Upgrade Node.js (you have $CURRENT_NODE, need 18+):"
        case "$OS" in
          mac)    echo "     brew upgrade node" ;;
          linux)  echo "     curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -"
                  echo "     sudo apt-get install -y nodejs" ;;
          *)      echo "     Download from https://nodejs.org" ;;
        esac
        echo ""
        ;;

      git)
        echo "  2) Install git:"
        case "$OS" in
          mac)     echo "     xcode-select --install" ;;
          linux)   echo "     sudo apt install git" ;;
          windows) echo "     winget install Git.Git" ;;
          *)       echo "     https://git-scm.com/downloads" ;;
        esac
        echo ""
        ;;

      claude)
        echo "  3) Install Claude Code and sign in:"
        echo "     npm install -g @anthropic-ai/claude-code"
        echo "     claude"
        echo ""
        echo "     This opens your browser to sign in. Once done, close Claude"
        echo "     (Ctrl+C) and re-run this installer."
        echo ""
        ;;
    esac
  done

  echo "  Then re-run:"
  echo "     curl -sSL https://raw.githubusercontent.com/blakesims/cca-plugin/main/install.sh | bash"
  echo ""
  exit 1
fi

echo "  All prerequisites found."
echo ""

# ── Install via marketplace (persistent across sessions) ─────────

# Ensure GitHub clones use HTTPS (most students won't have SSH keys)
git config --global url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true

INSTALL_OK=true

echo "  Adding plugin marketplace..."
if claude plugin marketplace add blakesims/cca-marketplace 2>/dev/null; then
  echo "  Marketplace added."
else
  echo "  Marketplace already registered or add failed — continuing."
fi

echo "  Installing cca-plugin..."
if ! claude plugin install cca-plugin@cca-marketplace --scope user 2>/dev/null; then
  echo "  Warning: cca-plugin install failed."
  INSTALL_OK=false
fi

echo "  Installing task-workflow..."
if ! claude plugin install task-workflow@cca-marketplace --scope user 2>/dev/null; then
  echo "  Warning: task-workflow install failed."
  INSTALL_OK=false
fi

if [ "$INSTALL_OK" = true ]; then
  echo ""
  echo "  Plugins installed and will persist across sessions."
  echo ""
  echo "  Done! Launching Claude..."
  echo ""
  exec claude "Hi! I just installed Claude Code Architects. Let's set up my project."
fi

# ── Fallback: clone + --plugin-dir (session-only) ────────────────

echo ""
echo "  Marketplace install failed. Falling back to manual clone..."

PLUGIN_DIR="${HOME}/.claude/plugins"
mkdir -p "$PLUGIN_DIR"

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
echo "  Plugins cloned (session-only mode — use --plugin-dir to load)."
echo "  Done! Launching Claude..."
echo ""

exec claude \
  --plugin-dir "$PLUGIN_DIR/cca-plugin" \
  --plugin-dir "$PLUGIN_DIR/task-workflow" \
  "Hi! I just installed Claude Code Architects. Let's set up my project."

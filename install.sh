#!/usr/bin/env bash
set -e

echo ""
echo "  Claude Code Architects — Installing..."
echo ""

# When run via curl|bash, stdin is the pipe. We need the real terminal
# for interactive prompts (Y/n) and for launching Claude at the end.
if [ -t 0 ]; then
  TTY_IN="/dev/stdin"
else
  TTY_IN="/dev/tty"
fi

# ── Detect OS ────────────────────────────────────────────────────

OS="unknown"
case "$(uname -s)" in
  Darwin*) OS="mac" ;;
  Linux*)  OS="linux" ;;
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
esac

# ── Check what's missing ────────────────────────────────────────

NEED_NODE=false
NEED_GIT=false
NEED_CLAUDE=false
NEED_AUTH=false

if ! command -v node &>/dev/null; then
  NEED_NODE=true
elif [ "$(node -e 'console.log(+(process.versions.node.split(".")[0]) >= 18)' 2>/dev/null)" != "true" ]; then
  NEED_NODE=true
fi

if ! command -v git &>/dev/null; then
  NEED_GIT=true
fi

if ! command -v claude &>/dev/null; then
  NEED_CLAUDE=true
fi

# Auth check — credentials file must exist and not be empty
if [ ! -s "$HOME/.claude/.credentials.json" ]; then
  NEED_AUTH=true
fi

# ── Nothing missing? Skip to plugin install ──────────────────────

if [ "$NEED_NODE" = false ] && [ "$NEED_GIT" = false ] && [ "$NEED_CLAUDE" = false ] && [ "$NEED_AUTH" = false ]; then
  echo "  All prerequisites found."
  echo ""
else

  # ── Show what's needed ───────────────────────────────────────────

  echo "  Checking your system..."
  echo ""

  if [ "$NEED_NODE" = true ]; then
    echo "  [ ] Node.js 18+    (needed by Claude Code)"
  else
    echo "  [x] Node.js         $(node --version 2>/dev/null)"
  fi

  if [ "$NEED_GIT" = true ]; then
    echo "  [ ] git             (needed for plugins)"
  else
    echo "  [x] git             $(git --version 2>/dev/null | cut -d' ' -f3)"
  fi

  if [ "$NEED_CLAUDE" = true ]; then
    echo "  [ ] Claude Code     (the AI coding assistant)"
  else
    echo "  [x] Claude Code     $(claude --version 2>/dev/null | head -1)"
  fi

  if [ "$NEED_AUTH" = true ] && [ "$NEED_CLAUDE" = false ]; then
    echo "  [ ] Claude sign-in  (opens browser)"
  fi

  echo ""

  # ── Can we auto-install? ───────────────────────────────────────

  CAN_AUTO=false

  case "$OS" in
    mac)
      if command -v brew &>/dev/null; then
        CAN_AUTO=true
        PKG_MGR="Homebrew"
      fi
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        CAN_AUTO=true
        PKG_MGR="apt"
      fi
      ;;
  esac

  if [ "$CAN_AUTO" = true ] && { [ "$NEED_NODE" = true ] || [ "$NEED_GIT" = true ] || [ "$NEED_CLAUDE" = true ]; }; then
    echo "  I can install the missing pieces using $PKG_MGR."
    echo ""

    # Build description of what we'll do
    STEPS=()
    [ "$NEED_GIT" = true ] && STEPS+=("git")
    [ "$NEED_NODE" = true ] && STEPS+=("Node.js 22")
    [ "$NEED_CLAUDE" = true ] && STEPS+=("Claude Code (via npm)")

    echo "  Will install: ${STEPS[*]}"
    [ "$OS" = "linux" ] && echo "  Note: This will use sudo for apt — you may be prompted for your password."
    echo ""

    printf "  Install now? [Y/n] "
    read -r REPLY < "$TTY_IN"
    echo ""

    if [ -z "$REPLY" ] || [[ "$REPLY" =~ ^[Yy] ]]; then

      # ── macOS install ────────────────────────────────────────────

      if [ "$OS" = "mac" ]; then
        if [ "$NEED_GIT" = true ]; then
          echo "  Installing git..."
          # Prefer xcode CLI tools (gets git + other dev tools)
          if ! xcode-select -p &>/dev/null; then
            echo "  Running xcode-select --install (a dialog will pop up)..."
            xcode-select --install 2>/dev/null || true
            echo ""
            echo "  Click 'Install' in the dialog, then re-run this installer when done."
            echo "     curl -sSL https://raw.githubusercontent.com/blakesims/cca-plugin/main/install.sh | bash"
            echo ""
            exit 0
          fi
        fi

        if [ "$NEED_NODE" = true ]; then
          echo "  Installing Node.js..."
          brew install node 2>/dev/null
        fi

        if [ "$NEED_CLAUDE" = true ]; then
          echo "  Installing Claude Code..."
          npm install -g @anthropic-ai/claude-code 2>/dev/null
        fi
      fi

      # ── Linux install ────────────────────────────────────────────

      if [ "$OS" = "linux" ]; then
        if [ "$NEED_GIT" = true ]; then
          echo "  Installing git..."
          sudo apt-get update -qq >/dev/null 2>&1
          sudo apt-get install -y -qq git >/dev/null 2>&1
        fi

        if [ "$NEED_NODE" = true ]; then
          echo "  Installing Node.js 22..."
          sudo apt-get install -y -qq ca-certificates curl gnupg >/dev/null 2>&1
          sudo mkdir -p /etc/apt/keyrings
          curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
          echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
          sudo apt-get update -qq >/dev/null 2>&1
          sudo apt-get install -y -qq nodejs >/dev/null 2>&1
        fi

        if [ "$NEED_CLAUDE" = true ]; then
          echo "  Installing Claude Code..."
          sudo npm install -g @anthropic-ai/claude-code >/dev/null 2>&1
        fi
      fi

      echo ""
      echo "  Done installing prerequisites."
      echo ""

    else
      echo "  No problem! Install manually, then re-run this installer."
      echo ""
    fi
  fi

  # If we still have missing deps (user declined, or auto-install not available), show manual steps
  # Re-check after potential install
  STILL_MISSING=false
  command -v node &>/dev/null || STILL_MISSING=true
  command -v git &>/dev/null || STILL_MISSING=true
  command -v claude &>/dev/null || STILL_MISSING=true

  if [ "$STILL_MISSING" = true ]; then
    echo "  Please install the missing items, then re-run this installer:"
    echo ""

    if ! command -v node &>/dev/null; then
      echo "  1) Node.js 18+:"
      case "$OS" in
        mac)     echo "     brew install node  — or download from https://nodejs.org" ;;
        linux)   echo "     curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -"
                 echo "     sudo apt-get install -y nodejs" ;;
        windows) echo "     Download from https://nodejs.org" ;;
        *)       echo "     Download from https://nodejs.org" ;;
      esac
      echo ""
    fi

    if ! command -v git &>/dev/null; then
      echo "  2) git:"
      case "$OS" in
        mac)     echo "     xcode-select --install" ;;
        linux)   echo "     sudo apt install git" ;;
        windows) echo "     Download from https://git-scm.com" ;;
        *)       echo "     https://git-scm.com/downloads" ;;
      esac
      echo ""
    fi

    if ! command -v claude &>/dev/null; then
      echo "  3) Claude Code:"
      echo "     npm install -g @anthropic-ai/claude-code"
      echo ""
    fi

    echo "  Then re-run:"
    echo "     curl -sSL https://raw.githubusercontent.com/blakesims/cca-plugin/main/install.sh | bash"
    echo ""
    exit 1
  fi

  # ── Auth check (after installs) ──────────────────────────────────

  if [ "$NEED_AUTH" = true ] || [ ! -s "$HOME/.claude/.credentials.json" ]; then
    echo "  One last step — you need to sign in to Claude."
    echo ""
    echo "  I'll open Claude now. It will open your browser to sign in."
    echo "  Once signed in, type /exit or press Ctrl+C, then re-run this installer."
    echo ""
    printf "  Ready? [Y/n] "
    read -r REPLY < "$TTY_IN"
    echo ""

    if [ -z "$REPLY" ] || [[ "$REPLY" =~ ^[Yy] ]]; then
      claude < "$TTY_IN" || true
      echo ""

      # Check if auth succeeded
      if [ ! -s "$HOME/.claude/.credentials.json" ]; then
        echo "  Hmm, doesn't look like sign-in completed."
        echo "  Run 'claude' to sign in, then re-run this installer."
        echo ""
        exit 1
      fi

      echo "  Signed in! Continuing with install..."
      echo ""
    else
      echo "  Run 'claude' to sign in, then re-run:"
      echo "     curl -sSL https://raw.githubusercontent.com/blakesims/cca-plugin/main/install.sh | bash"
      echo ""
      exit 0
    fi
  fi
fi

# ── Install plugins via marketplace ──────────────────────────────

# Use HTTPS for GitHub clones (env-only, no global git config changes)
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf"
export GIT_CONFIG_VALUE_0="git@github.com:"

echo "  Adding plugin marketplace..."
if claude plugin marketplace add blakesims/cca-marketplace 2>&1; then
  echo "  Marketplace added."
else
  echo "  Marketplace already registered — continuing."
fi

INSTALL_OK=true

echo "  Installing cca-plugin..."
if ! claude plugin install cca-plugin@cca-marketplace --scope user 2>&1; then
  echo ""
  echo "  cca-plugin install failed."
  INSTALL_OK=false
fi

echo "  Installing task-workflow..."
if ! claude plugin install task-workflow@cca-marketplace --scope user 2>&1; then
  echo ""
  echo "  task-workflow install failed."
  INSTALL_OK=false
fi

if [ "$INSTALL_OK" = true ]; then
  echo ""
  echo "  Plugins installed (user scope — persists across all sessions)."
  echo ""
  echo "  Done! Launching Claude..."
  echo ""
  exec claude "Hi! I just installed Claude Code Architects. Let's set up my project." < "$TTY_IN"
fi

# ── Install failed — show error and manual steps ─────────────────

echo ""
echo "  Plugin install failed. This usually means a git or network issue."
echo ""
echo "  Try running these commands manually:"
echo ""
echo "    claude plugin marketplace add blakesims/cca-marketplace"
echo "    claude plugin install cca-plugin@cca-marketplace --scope user"
echo "    claude plugin install task-workflow@cca-marketplace --scope user"
echo ""
echo "  If you see 'Permission denied (publickey)', run this first:"
echo "    git config --global url.\"https://github.com/\".insteadOf \"git@github.com:\""
echo ""
echo "  Then re-run the install commands above."
echo ""
exit 1

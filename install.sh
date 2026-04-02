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

NEED_GIT=false
NEED_CLAUDE=false
NEED_AUTH=false

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

if [ "$NEED_GIT" = false ] && [ "$NEED_CLAUDE" = false ] && [ "$NEED_AUTH" = false ]; then
  echo "  All prerequisites found."
  echo ""
else

  # ── Show what's needed ───────────────────────────────────────────

  echo "  Checking your system..."
  echo ""

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
      # macOS: xcode-select provides git, native installer provides claude
      CAN_AUTO=true
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        CAN_AUTO=true
      fi
      ;;
  esac

  if [ "$CAN_AUTO" = true ] && { [ "$NEED_GIT" = true ] || [ "$NEED_CLAUDE" = true ]; }; then
    STEPS=()
    [ "$NEED_GIT" = true ] && STEPS+=("git")
    [ "$NEED_CLAUDE" = true ] && STEPS+=("Claude Code")

    echo "  Will install: ${STEPS[*]}"
    echo ""

    printf "  Install now? [Y/n] "
    read -r REPLY < "$TTY_IN"
    echo ""

    if [ -z "$REPLY" ] || [[ "$REPLY" =~ ^[Yy] ]]; then

      # ── macOS install ────────────────────────────────────────────

      if [ "$OS" = "mac" ]; then
        if [ "$NEED_GIT" = true ]; then
          echo "  Installing git..."
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

        if [ "$NEED_CLAUDE" = true ]; then
          echo "  Installing Claude Code..."
          curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null
        fi
      fi

      # ── Linux install ────────────────────────────────────────────

      if [ "$OS" = "linux" ]; then
        if [ "$NEED_GIT" = true ]; then
          echo "  Installing git..."
          sudo apt-get update -qq >/dev/null 2>&1
          sudo apt-get install -y -qq git >/dev/null 2>&1
        fi

        if [ "$NEED_CLAUDE" = true ]; then
          echo "  Installing Claude Code..."
          curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null
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

  # If we still have missing deps, show manual steps
  STILL_MISSING=false
  command -v git &>/dev/null || STILL_MISSING=true
  command -v claude &>/dev/null || STILL_MISSING=true

  if [ "$STILL_MISSING" = true ]; then
    echo "  Please install the missing items, then re-run this installer:"
    echo ""

    if ! command -v git &>/dev/null; then
      echo "  1) git:"
      case "$OS" in
        mac)     echo "     xcode-select --install" ;;
        linux)   echo "     sudo apt install git" ;;
        windows) echo "     Download from https://git-scm.com/downloads/win" ;;
        *)       echo "     https://git-scm.com/downloads" ;;
      esac
      echo ""
    fi

    if ! command -v claude &>/dev/null; then
      echo "  2) Claude Code:"
      case "$OS" in
        mac|linux) echo "     curl -fsSL https://claude.ai/install.sh | bash" ;;
        windows)   echo "     In PowerShell: irm https://claude.ai/install.ps1 | iex" ;;
        *)         echo "     Visit https://claude.ai/code for instructions" ;;
      esac
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
  echo "  Next steps:"
  echo "    1. Create a project folder:  mkdir ~/projects/my-app && cd ~/projects/my-app"
  echo "    2. Start Claude Code:        claude"
  echo "    3. Type inside Claude:       /cca-plugin:setup"
  echo ""
  echo "  Or follow your personalized build guide for detailed instructions."
  echo ""
  exit 0
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

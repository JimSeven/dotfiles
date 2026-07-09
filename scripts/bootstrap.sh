#!/usr/bin/env bash
set -euo pipefail

# Two-phase bootstrap for a fresh Mac (see docs/adr/0002).
#
#   Phase 1 (default): install prerequisites + 1Password, then pause so you can
#                      sign in and enable the 1Password SSH agent.
#   Phase 2 (--continue): install chezmoi and apply everything.
#
# Usage on a clean machine:
#   curl -fsSL https://raw.githubusercontent.com/JimSeven/dotfiles/main/scripts/bootstrap.sh | bash
#   # …sign into 1Password, enable the SSH agent…
#   curl -fsSL https://raw.githubusercontent.com/JimSeven/dotfiles/main/scripts/bootstrap.sh | bash -s -- --continue

REPO="JimSeven/dotfiles"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

ensure_command_line_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    return
  fi
  log "Installing Xcode Command Line Tools"
  xcode-select --install || true
  echo "Finish the Command Line Tools dialog, then re-run this script." >&2
  exit 1
}

ensure_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

phase1() {
  ensure_command_line_tools
  ensure_homebrew
  log "Installing 1Password"
  brew install --cask 1password 1password-cli
  cat <<'MSG'

──────────────────────────────────────────────────────────────────────
Phase 1 complete.

Next:
  1. Open 1Password and sign in.
  2. Settings → Developer → enable "Use the SSH agent".
  3. Run phase 2 to install everything else and apply your dotfiles:

     curl -fsSL https://raw.githubusercontent.com/JimSeven/dotfiles/main/scripts/bootstrap.sh | bash -s -- --continue
──────────────────────────────────────────────────────────────────────
MSG
}

phase2() {
  ensure_homebrew
  log "Installing chezmoi"
  brew install chezmoi
  log "chezmoi init --apply ${REPO}"
  chezmoi init --apply "$REPO"
  log "Done. Open Ghostty or restart your shell."
}

case "${1:-}" in
  --continue) phase2 ;;
  "")         phase1 ;;
  *)          echo "Unknown argument: $1 (use --continue for phase 2)" >&2; exit 2 ;;
esac

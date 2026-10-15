#!/usr/bin/env bash
set -euo pipefail

# Trust the third-party taps listed in the Brewfile. Homebrew 5.1.15+ warns on
# untrusted taps and a future release will refuse to load them; `brew bundle`
# can't express trust, so it lives here. Runs before run_onchange_before_10 so
# the bundle never sees an untrusted tap. `brew trust` only writes
# ~/.homebrew/trust.json — the tap need not be tapped yet — and is idempotent.
#
# run_once_ (not run_onchange_): re-runs on the next apply if it failed. Adding
# a tap here changes the script content, so chezmoi runs it again. See docs/adr/0008.

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found — run the bootstrap script first (see README)." >&2
  exit 1
fi

echo "==> brew trust: third-party taps"
brew trust --tap \
  pchuri/tap   # confluence-cli

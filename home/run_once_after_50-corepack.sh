#!/usr/bin/env bash
set -euo pipefail

# Enable Corepack (ADR-0003): activates the Yarn/pnpm shims that ship with Node.
# Node comes from Homebrew (explicit `brew "node"` in the Brewfile), installed by
# run_onchange_before_10-install-packages before this `after` script runs, so npm
# is on PATH here. `npm install -g corepack` bumps the bundled Corepack to latest;
# `corepack enable` writes the yarn/pnpm shims next to the brew Node binary.
#
# run_once_after_ (not run_onchange_): this has no in-content change source, so
# run_onchange_ would run it exactly once and never retry a failed run. run_once_
# re-runs on the next apply if it failed (network) — the right semantics for a
# one-time setup step that can fail. See docs/adr/0008.

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found — Node isn't installed yet (brew bundle installs it via the Brewfile)." >&2
  echo "Skipping Corepack for now; re-apply after 'brew bundle'." >&2
  exit 0
fi

echo "==> npm install -g corepack"
npm install -g corepack

echo "==> corepack enable"
corepack enable

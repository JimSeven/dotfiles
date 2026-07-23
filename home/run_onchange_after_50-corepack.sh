#!/usr/bin/env bash
set -euo pipefail

# Enable Corepack (ADR-0003): activates the Yarn/pnpm shims that ship with Node.
# Node comes from Homebrew (explicit `brew "node"` in the Brewfile), installed by
# run_onchange_before_10-install-packages before this `after` script runs, so npm
# is on PATH here. `npm install -g corepack` bumps the bundled Corepack to latest;
# `corepack enable` writes the yarn/pnpm shims next to the brew Node binary.
# chezmoi re-runs this whenever the script below changes.

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found — Node isn't installed yet (brew bundle installs it via the Brewfile)." >&2
  echo "Skipping Corepack for now; re-apply after 'brew bundle'." >&2
  exit 0
fi

echo "==> npm install -g corepack"
npm install -g corepack

echo "==> corepack enable"
corepack enable

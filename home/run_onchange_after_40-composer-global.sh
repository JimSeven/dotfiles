#!/usr/bin/env bash
set -euo pipefail

# Global Composer CLIs (ADR-0009).
#
# The standing set of global Composer tools that get reinstalled on every machine.
# Stable and idempotent — unlike npm globals, which live under Herd's NVM and break
# on a Node switch (ADR-0003), so those stay a manual step. chezmoi re-runs this
# whenever the package list below changes.

packages=(
  laravel/forge-cli   # Laravel Forge CLI
  laravel/installer   # `laravel new`
  statamic/cli        # Statamic CLI
  spatie/global-ray   # Ray debugging in any PHP file
)

# composer ships with Laravel Herd (ADR-0003) and is not on the default PATH used
# by chezmoi's run scripts, so add Herd's bin dir explicitly.
herd_bin="$HOME/Library/Application Support/Herd/bin"
[ -x "$herd_bin/composer" ] && PATH="$herd_bin:$PATH"

if ! command -v composer >/dev/null 2>&1; then
  if [ -d "/Applications/Herd.app" ]; then
    echo "composer not found — Herd is installed but hasn't been launched yet." >&2
    echo "Open Herd once (it sets up bundled PHP + composer), then re-apply." >&2
  else
    echo "composer not found — install and launch Herd (see docs/GUIDE.md), then re-apply." >&2
  fi
  echo "Skipping global Composer CLIs for now." >&2
  exit 0
fi

echo "==> composer global require: ${packages[*]}"
composer global require "${packages[@]}"

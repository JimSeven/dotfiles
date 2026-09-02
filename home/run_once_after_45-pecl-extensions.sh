#!/usr/bin/env bash
set -euo pipefail

# Global PECL extensions for Herd's PHP (ADR-0003).
#
# The standing set of PECL extensions reinstalled on every machine. Currently only
# phpredis — the PHP <-> Redis client extension. Note: this is the *client*, not the
# Redis server; the server runs per-project in OrbStack (ADR-0005). The extension is
# a machine-wide PHP capability, analogous to the global Composer CLIs (see 40).
#
# run_once_after_ (not run_onchange_): re-runs when this file's contents change
# (e.g. the extension list below) AND retries on the next apply if it failed —
# run_onchange_ only guarantees the former, so a network/build failure on a fresh
# machine would never be retried.

extensions=(
  redis   # phpredis — PHP client for Redis (talks to the per-project OrbStack container)
)

# php/pecl ship with Laravel Herd (ADR-0003) and are not on the default PATH used
# by chezmoi's run scripts, so add Herd's bin dir explicitly. pecl builds against
# whichever PHP is active in Herd; per-version installs stay a manual step.
herd_bin="$HOME/Library/Application Support/Herd/bin"
[ -x "$herd_bin/php" ] && PATH="$herd_bin:$PATH"

if ! command -v pecl >/dev/null 2>&1; then
  if [ -d "/Applications/Herd.app" ]; then
    echo "pecl not found — Herd is installed but hasn't been launched yet." >&2
    echo "Open Herd once (it sets up bundled PHP + pecl), then re-apply." >&2
  else
    echo "pecl not found — install and launch Herd (see docs/GUIDE.md), then re-apply." >&2
  fi
  echo "Skipping PECL extensions for now." >&2
  exit 0
fi

for ext in "${extensions[@]}"; do
  # Idempotency: skip if the extension is already loaded by the active PHP.
  if php -m 2>/dev/null | grep -qix "$ext"; then
    echo "==> pecl: $ext already installed — skipping"
    continue
  fi
  # `yes ''` accepts every interactive prompt's default (phpredis asks about
  # igbinary/lzf/etc. support — defaults = no) so the build stays non-interactive.
  echo "==> pecl install $ext"
  yes '' | pecl install "$ext"
done

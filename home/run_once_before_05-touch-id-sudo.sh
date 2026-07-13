#!/usr/bin/env bash
set -euo pipefail

# Enable Touch ID for `sudo` (ADR-0009).
#
# Writes the pam_tid line to /etc/pam.d/sudo_local — the file Apple added so this
# survives macOS updates, unlike editing /etc/pam.d/sudo directly. Runs once
# (run_once) and early (before file writes and the macos-defaults `sudo nvram`
# step), so the rest of the very first apply can already authenticate by touch.
#
# On a Mac without a Touch ID sensor pam_tid.so simply falls through to the
# password prompt, so this is harmless there.

file="/etc/pam.d/sudo_local"
line="auth       sufficient     pam_tid.so"

if [ -f "$file" ] && grep -q "pam_tid.so" "$file"; then
  echo "==> Touch ID for sudo already enabled ($file)"
  exit 0
fi

echo "==> Enabling Touch ID for sudo ($file) — you may be prompted for your password once"
printf '# Managed by dotfiles (ADR-0009): Touch ID for sudo.\n%s\n' "$line" \
  | sudo tee "$file" >/dev/null
sudo chmod 444 "$file"
echo "==> Touch ID for sudo enabled"

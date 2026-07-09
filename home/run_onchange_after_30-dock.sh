#!/usr/bin/env bash
set -euo pipefail

# Rebuild the Dock with dockutil (managed by chezmoi; re-runs when this changes).
# dockutil is installed via the Brewfile.

if ! command -v dockutil >/dev/null 2>&1; then
  echo "dockutil not found — skipping Dock setup (install via Brewfile first)." >&2
  exit 0
fi

dockutil --no-restart --remove all

# Music
dockutil --no-restart --add "/System/Applications/Music.app"
dockutil --no-restart --add "/Applications/Spotify.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Browsers
dockutil --no-restart --add "/Applications/Safari.app"
dockutil --no-restart --add "/Applications/Google Chrome.app"
dockutil --no-restart --add "/Applications/Firefox Developer Edition.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Communication
dockutil --no-restart --add "/Applications/Mimestream.app"
dockutil --no-restart --add "/Applications/Slack.app"
dockutil --no-restart --add "/System/Applications/Messages.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Productivity
dockutil --no-restart --add "/Applications/Notion.app"
dockutil --no-restart --add "/System/Applications/Calendar.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# Dev
dockutil --no-restart --add "/Applications/Visual Studio Code.app"
dockutil --no-restart --add "/Applications/Ghostty.app"
dockutil --no-restart --add '' --type small-spacer --section apps

# System
dockutil --no-restart --add "/System/Applications/System Settings.app"

# Folders
dockutil --no-restart --add "/Applications" --view auto --display folder --sort name
dockutil --no-restart --add '~/Downloads' --view auto --display folder --sort dateadded

killall Dock

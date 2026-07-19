#!/usr/bin/env bash
set -euo pipefail

# Rebuild the Dock with dockutil (managed by chezmoi; re-runs when this changes).
# dockutil is installed via the Brewfile.

if ! command -v dockutil >/dev/null 2>&1; then
  echo "dockutil not found — skipping Dock setup (install via Brewfile first)." >&2
  exit 0
fi

# add_app <path> [extra dockutil args...] — add to the Dock only if the app is
# actually installed, so a not-yet-installed cask (or one absent from the
# Manifest) skips gracefully instead of aborting the whole Dock rebuild.
add_app() {
  if [ -e "$1" ]; then
    dockutil --no-restart --add "$@"
  else
    printf '  skip (not installed): %s\n' "$1" >&2
  fi
}
spacer() { dockutil --no-restart --add '' --type small-spacer --section apps; }

# Let any in-flight Dock/cfprefsd restart (e.g. from the macOS-defaults script
# that runs just before this one) settle first. Editing the Dock plist while a
# relaunching Dock is rewriting it clobbers dockutil's writes — items silently
# go missing. A brief pause plus a single clean restart at the end avoids the race.
sleep 3

dockutil --no-restart --remove all

# Music
add_app "/System/Applications/Music.app"
add_app "/Applications/Spotify.app"   # not in the Brewfile — skipped if absent
spacer

# Browsers
add_app "/Applications/Safari.app"
add_app "/Applications/Google Chrome.app"
add_app "/Applications/Firefox Developer Edition.app"
spacer

# Communication
add_app "/Applications/Mimestream.app"
add_app "/Applications/Slack.app"
add_app "/System/Applications/Messages.app"
spacer

# Productivity
add_app "/Applications/Notion.app"
add_app "/System/Applications/Calendar.app"
spacer

# Dev
add_app "/Applications/Visual Studio Code.app"
add_app "/Applications/Ghostty.app"
spacer

# System
add_app "/System/Applications/System Settings.app"

# Folders
add_app "/Applications" --view auto --display folder --sort name
add_app "$HOME/Downloads" --view auto --display folder --sort dateadded

# Flush the preferences cache so Dock reloads the plist we just wrote rather than
# a stale in-memory copy, then restart it once.
killall cfprefsd &>/dev/null || true
killall Dock

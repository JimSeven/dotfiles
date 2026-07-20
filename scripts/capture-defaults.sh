#!/usr/bin/env bash
set -uo pipefail

# capture-defaults.sh — read the CURRENT machine's macOS preferences for a
# curated vocabulary of settings and print them as ready-to-review
# `defaults write` lines (and `dockutil --add` lines for the Dock).
#
# This is a DISCOVERY aid, not a Provisioning script: it never writes anything.
# The workflow is deliberately human-in-the-loop and matches the "minimal
# deterministic core" philosophy (ADR-0009):
#
#   1. Change a setting in System Settings.
#   2. Run `bash scripts/capture-defaults.sh` (optionally `| grep -i mouse`).
#   3. Copy the emitted line(s) into `home/run_onchange_after_20-macos-defaults.sh`
#      (or the Dock into `home/run_onchange_after_30-dock.sh`), then `chezmoi apply`.
#
# Only keys in the curated list below are read — `defaults` domains hold far more
# noise than is worth versioning. Add a `domain|key` pair to grow the vocabulary.
# Type (bool/int/float/string) is auto-detected, so you only maintain the keys.

# emit <domain> <key> — print a `defaults write` line for the current value,
# or a commented "(unset)" marker if the key is not currently set.
emit() {
  local domain="$1" key="$2" type value flag
  if ! type=$(defaults read-type "$domain" "$key" 2>/dev/null); then
    printf '#   (unset)  %s "%s"\n' "$domain" "$key"
    return
  fi
  value=$(defaults read "$domain" "$key" 2>/dev/null)
  case "$type" in
    "Type is boolean") flag="-bool";   [ "$value" = "1" ] && value="true" || value="false" ;;
    "Type is integer") flag="-int" ;;
    "Type is float")   flag="-float" ;;
    "Type is string")  flag="-string" ;;
    *) printf '#   (complex: %s) inspect with: defaults read %s "%s"\n' "$type" "$domain" "$key"; return ;;
  esac
  printf 'defaults write %s "%s" %s "%s"\n' "$domain" "$key" "$flag" "$value"
}

# section <title> <domain|key>... — print a header then one emit per pair.
section() {
  local title="$1"; shift
  printf '\n# --- %s %s\n' "$title" "$(printf '#%.0s' $(seq 1 $((60 - ${#title}))))"
  local pair
  for pair in "$@"; do
    emit "${pair%%|*}" "${pair#*|}"
  done
}

# --watch — discovery for settings NOT in the curated list above (e.g. anything
# under System Settings › Accessibility). Snapshots the common UI domains, waits
# for you to change one setting, then shows exactly which key moved and prints a
# ready `defaults write` line for it. This is how you find the key for a control
# whose defaults domain/key you don't already know. Known runtime noise (cursor
# position, zoom level, event timestamps) is filtered out so you can move the
# mouse freely while changing the setting — you don't need to keep it still.
if [ "${1:-}" = "--watch" ]; then
  watch_domains="NSGlobalDomain com.apple.AppleMultitouchTrackpad \
com.apple.driver.AppleBluetoothMultitouch.trackpad com.apple.universalaccess \
com.apple.Accessibility com.apple.dock com.apple.finder com.apple.controlcenter"
  snap="$(mktemp -d)"
  for d in $watch_domains; do defaults read "$d" >"$snap/$d.before" 2>/dev/null || true; done
  printf 'Snapshot taken. Change ONE setting in System Settings now, then press Enter… '
  read -r _ </dev/tty || true
  # Runtime state that macOS rewrites on its own — cursor position, current zoom
  # level, event-log timestamps. Never a durable preference, so it is filtered
  # out of the results (both the ready-to-paste keys and the raw-diff context).
  # A setting whose ONLY diff is noise is not stored in `defaults` at all.
  noise_keys='displaysLastCursorLocation|closeViewZoomFactor|closeViewZoomFactorBeforeTermination|closeViewZoomDisplayID|closeViewZoomDisplayHeight|closeViewZoomDisplayWidth|MouseKeys'
  noise_lines="$noise_keys"'|^[<>].*(Date|Reason|State|[XY]) ='
  found=0
  for d in $watch_domains; do
    defaults read "$d" >"$snap/$d.after" 2>/dev/null || true
    diff -q "$snap/$d.before" "$snap/$d.after" >/dev/null 2>&1 && continue
    # Durable top-level keys that changed, minus the runtime noise.
    # Drop the noise keys, plus nested dict artefacts that look like top-level
    # keys after stripping the diff marker: numeric indices (1, 2, …) and the
    # single-letter X/Y coordinate keys inside displaysLastCursorLocation.
    keys=$(diff "$snap/$d.before" "$snap/$d.after" | sed -n 's/^> *//p' \
      | sed -n 's/^\([A-Za-z0-9_.]*\) = .*/\1/p' | sort -u \
      | grep -Ev "^($noise_keys|[0-9]+|[A-Z])$" || true)
    if [ -z "$keys" ]; then
      printf '\n# === %s changed — only runtime noise, ignored ===\n' "$d"
      continue
    fi
    found=1
    printf '\n# === %s changed ===\n' "$d"
    # Ready-to-paste line for each changed simple (unquoted, top-level) key.
    printf '%s\n' "$keys" | while read -r key; do [ -n "$key" ] && emit "$d" "$key"; done
    # Raw diff for full context (nested/quoted keys, removals), noise stripped.
    diff "$snap/$d.before" "$snap/$d.after" | grep -Ev "$noise_lines" | sed 's/^/#   /'
  done
  if [ "$found" -eq 0 ]; then
    printf '\nNo durable setting changed in the watched domains.\n'
    printf 'If you did change something, it is likely not stored in defaults at all\n'
    printf '(e.g. display resolution lives in a per-host WindowServer plist) — such\n'
    printf 'settings are out of scope for this repo (ADR-0009).\n'
  fi
  rm -rf "$snap"
  exit 0
fi

printf '# macOS defaults captured from this machine — review, then paste into\n'
printf '# home/run_onchange_after_20-macos-defaults.sh. Generated by scripts/capture-defaults.sh.\n'

section "Input — mouse, trackpad speed & scroll" \
  "NSGlobalDomain|com.apple.mouse.scaling" \
  "NSGlobalDomain|com.apple.scrollwheel.scaling" \
  "NSGlobalDomain|com.apple.trackpad.scaling" \
  "NSGlobalDomain|com.apple.swipescrolldirection"

section "Keyboard" \
  "NSGlobalDomain|KeyRepeat" \
  "NSGlobalDomain|InitialKeyRepeat" \
  "NSGlobalDomain|AppleKeyboardUIMode" \
  "NSGlobalDomain|ApplePressAndHoldEnabled" \
  "NSGlobalDomain|NSAutomaticSpellingCorrectionEnabled" \
  "NSGlobalDomain|NSAutomaticCapitalizationEnabled"

section "Appearance & sound" \
  "NSGlobalDomain|AppleInterfaceStyle" \
  "NSGlobalDomain|AppleShowScrollBars" \
  "NSGlobalDomain|com.apple.sound.beep.feedback"

section "Accessibility — zoom" \
  "com.apple.universalaccess|closeViewScrollWheelToggle" \
  "com.apple.universalaccess|closeViewScrollWheelModifiersInt"

# Trackpad gestures live in TWO domains (built-in vs Bluetooth); capture both.
for td in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  section "Trackpad gestures ($td)" \
    "$td|Clicking" \
    "$td|TrackpadThreeFingerDrag" \
    "$td|TrackpadRightClick" \
    "$td|TrackpadTwoFingerDoubleTapGesture" \
    "$td|TrackpadThreeFingerHorizSwipeGesture" \
    "$td|TrackpadThreeFingerVertSwipeGesture" \
    "$td|TrackpadFourFingerHorizSwipeGesture" \
    "$td|TrackpadFourFingerVertSwipeGesture" \
    "$td|TrackpadFourFingerPinchGesture" \
    "$td|TrackpadPinch" \
    "$td|TrackpadRotate" \
    "$td|TrackpadTwoFingerFromRightEdgeSwipeGesture"
done

section "Dock — sizing, effects, gestures" \
  "com.apple.dock|tilesize" \
  "com.apple.dock|magnification" \
  "com.apple.dock|largesize" \
  "com.apple.dock|show-recents" \
  "com.apple.dock|mineffect" \
  "com.apple.dock|autohide" \
  "com.apple.dock|orientation" \
  "com.apple.dock|showAppExposeGestureEnabled" \
  "com.apple.dock|showLaunchpadGestureEnabled" \
  "com.apple.dock|showMissionControlGestureEnabled"

section "Finder" \
  "com.apple.finder|NewWindowTarget" \
  "com.apple.finder|ShowExternalHardDrivesOnDesktop" \
  "com.apple.finder|ShowRecentTags" \
  "com.apple.finder|FXDefaultSearchScope" \
  "com.apple.finder|ShowPathbar" \
  "com.apple.finder|ShowStatusBar" \
  "com.apple.finder|FXPreferredViewStyle"

section "Menu bar & privacy" \
  "com.apple.controlcenter|NSStatusItem Visible Bluetooth" \
  "com.apple.AdLib|allowApplePersonalizedAdvertising"

# --- Dock layout -----------------------------------------------------------
printf '\n# --- Dock layout (paste into home/run_onchange_after_30-dock.sh) %s\n' "$(printf '#%.0s' $(seq 1 10))"
if command -v dockutil >/dev/null 2>&1; then
  # dockutil --list is tab-separated: name<TAB>file-URL<TAB>...  Convert the
  # URL column back to a filesystem path and emit an --add line per app.
  dockutil --list 2>/dev/null | while IFS=$'\t' read -r name url _rest; do
    [ -z "${url:-}" ] && continue
    path=$(python3 -c 'import sys,urllib.parse;print(urllib.parse.unquote(sys.argv[1]))' "${url#file://}" 2>/dev/null)
    path="${path%/}"
    printf 'dockutil --no-restart --add "%s"   # %s\n' "$path" "$name"
  done
else
  printf '# dockutil not installed — skipping Dock capture.\n'
fi

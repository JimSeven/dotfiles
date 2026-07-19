#!/usr/bin/env bash
set -uo pipefail

# sync-defaults.sh — interactively reconcile the CURRENT machine's macOS
# preferences with the values stored in the repo.
#
# For every setting managed in home/run_onchange_after_20-macos-defaults.sh it
# compares the repo's value (the "should be") with what the machine actually has
# right now (the "is"). Where they differ it explains the setting in plain words
# and asks whether to ADOPT the machine's current value into the repo — writing
# the change back into the provisioning script for you.
#
# This is the write-back companion to scripts/capture-defaults.sh (which only
# ever prints). The workflow:
#
#   1. Tweak settings in System Settings.
#   2. Run `bash scripts/sync-defaults.sh` and answer y/n per drifted setting.
#   3. Review the diff, then commit and apply with chezmoi.
#
#   bash scripts/sync-defaults.sh --dry-run   # just list drift, change nothing
#
# Adopted changes edit the repo source, not $HOME — nothing is applied until you
# run chezmoi. Coverage follows the provisioning script: to manage a new key, add
# a `dw` line there (and, optionally, a human description in desc() below).
#
# Deliberately POSIX-bash-3.2 compatible (macOS ships bash 3.2): no associative
# arrays, so descriptions are a case statement and settings are read line by line.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script20="$here/../home/run_onchange_after_20-macos-defaults.sh"

dry_run=0
[ "${1:-}" = "--dry-run" ] && dry_run=1

if [ ! -f "$script20" ]; then
  echo "Cannot find $script20" >&2
  exit 1
fi

# desc <domain> <key> — plain-language description, or the raw key as fallback.
desc() {
  case "$1|$2" in
  "com.apple.dock|tilesize")             echo "Dock icon size, in pixels" ;;
  "com.apple.dock|magnification")        echo "Magnify Dock icons on hover" ;;
  "com.apple.dock|largesize")            echo "Magnified Dock icon size, in pixels" ;;
  "com.apple.dock|show-recents")         echo "Show recent apps in the Dock" ;;
  "com.apple.dock|mineffect")            echo "Window minimise animation (genie/scale/suck)" ;;
  "com.apple.dock|showAppExposeGestureEnabled") echo "Trackpad App Exposé gesture" ;;
  "NSGlobalDomain|com.apple.mouse.scaling")     echo "Mouse pointer tracking speed (higher = faster)" ;;
  "NSGlobalDomain|com.apple.trackpad.scaling")  echo "Trackpad pointer tracking speed (higher = faster)" ;;
  "NSGlobalDomain|KeyRepeat")            echo "Key repeat rate (lower = faster)" ;;
  "NSGlobalDomain|InitialKeyRepeat")     echo "Delay before a held key repeats (lower = shorter)" ;;
  "NSGlobalDomain|AppleKeyboardUIMode")  echo "Full keyboard access (Tab moves between all controls)" ;;
  "NSGlobalDomain|NSAutomaticSpellingCorrectionEnabled") echo "Automatic spelling correction" ;;
  "NSGlobalDomain|NSAutomaticCapitalizationEnabled")     echo "Automatic capitalisation" ;;
  "NSGlobalDomain|com.apple.sound.beep.feedback")        echo "Play feedback sound on volume change" ;;
  "com.apple.AppleMultitouchTrackpad|Clicking")          echo "Tap to click (built-in trackpad)" ;;
  "com.apple.AppleMultitouchTrackpad|TrackpadThreeFingerDrag") echo "Three-finger drag (built-in trackpad)" ;;
  "com.apple.driver.AppleBluetoothMultitouch.trackpad|Clicking") echo "Tap to click (Bluetooth trackpad)" ;;
  "com.apple.driver.AppleBluetoothMultitouch.trackpad|TrackpadThreeFingerDrag") echo "Three-finger drag (Bluetooth trackpad)" ;;
  "com.apple.AdLib|allowApplePersonalizedAdvertising")   echo "Personalised Apple advertising" ;;
  "com.apple.controlcenter|NSStatusItem Visible Bluetooth") echo "Show Bluetooth in the menu bar" ;;
  "com.apple.loginwindow|TALLogoutSavesState")           echo "Reopen windows when logging back in" ;;
  "com.apple.finder|NewWindowTarget")    echo "Folder new Finder windows open to" ;;
  "com.apple.finder|ShowExternalHardDrivesOnDesktop")    echo "Show external drives on the Desktop" ;;
  "com.apple.finder|ShowRecentTags")     echo "Show recent tags in the Finder sidebar" ;;
  "com.apple.finder|FXDefaultSearchScope") echo "Default Finder search scope (this folder / Mac)" ;;
  "com.apple.finder|ShowPathbar")        echo "Show the Finder path bar" ;;
  "com.apple.finder|ShowStatusBar")      echo "Show the Finder status bar" ;;
  "com.apple.finder|FXPreferredViewStyle") echo "Default Finder view (icon/list/column/gallery)" ;;
  "com.apple.addressbook|ABNameSortingFormat") echo "Contacts name sort order" ;;
  "com.apple.iCal|Show Week Numbers")    echo "Show week numbers in Calendar" ;;
  "com.apple.iCal|CalendarSidebarShown") echo "Show the Calendar sidebar" ;;
  "com.apple.messages.text|SpellChecking") echo "Spell checking in Messages" ;;
  *) echo "$1 $2" ;;
  esac
}

# norm <flag> <value> — canonical form for comparison (booleans → true/false).
norm() {
  if [ "$1" = "-bool" ]; then
    case "$2" in 1 | true | TRUE | yes | YES) echo true ;; *) echo false ;; esac
  else
    echo "$2"
  fi
}

# qtoken <str> — quote a token for the rewritten `dw` line if it needs it.
qtoken() { case "$1" in *[[:space:]]*) printf '"%s"' "$1" ;; *) printf '%s' "$1" ;; esac; }

# adopt <domain> <key> <flag> <newvalue> — rewrite the one matching dw line.
adopt() {
  local tdomain="$1" tkey="$2" nflag="$3" nval="$4" tmp d k
  tmp="$(mktemp)"
  while IFS= read -r l; do
    if [ "${l#dw }" != "$l" ]; then
      d=""; k=""
      eval "set -- ${l#dw }" 2>/dev/null && d="${1:-}" && k="${2:-}"
      if [ "$d" = "$tdomain" ] && [ "$k" = "$tkey" ]; then
        printf 'dw %s %s %s %s\n' "$(qtoken "$tdomain")" "$(qtoken "$tkey")" "$nflag" "$(qtoken "$nval")" >>"$tmp"
        continue
      fi
    fi
    printf '%s\n' "$l" >>"$tmp"
  done <"$script20"
  cat "$tmp" >"$script20"   # keep original file's permissions
  rm -f "$tmp"
}

# Snapshot the dw lines first so adopt() rewriting the file mid-loop is safe.
dw_lines=()
while IFS= read -r line; do
  [ "${line#dw }" != "$line" ] && dw_lines+=("$line")
done <"$script20"

drift=0
adopted=0
for line in ${dw_lines+"${dw_lines[@]}"}; do
  eval "set -- ${line#dw }" 2>/dev/null || continue
  domain="${1:-}"; key="${2:-}"; flag="${3:-}"
  shift 3 2>/dev/null || continue
  repo_raw="$*"

  # Templated values (e.g. file://$HOME) aren't reconcilable — skip.
  case "$repo_raw" in *'$'*) continue ;; esac

  cur_raw="$(defaults read "$domain" "$key" 2>/dev/null)" || continue

  [ "$(norm "$flag" "$repo_raw")" = "$(norm "$flag" "$cur_raw")" ] && continue

  drift=$((drift + 1))
  printf '\n\033[1m%s\033[0m\n' "$(desc "$domain" "$key")"
  printf '  key:   %s %s\n' "$domain" "$key"
  printf '  repo:  %s\n' "$(norm "$flag" "$repo_raw")"
  printf '  now:   \033[33m%s\033[0m\n' "$(norm "$flag" "$cur_raw")"

  [ "$dry_run" -eq 1 ] && continue

  printf '  Adopt the current value into the repo? [y/N] '
  read -r answer || answer=""
  case "$answer" in
  y | Y)
    adopt "$domain" "$key" "$flag" "$cur_raw"
    adopted=$((adopted + 1))
    printf '  \033[32m updated %s\033[0m\n' "$(basename "$script20")"
    ;;
  *) printf '  skipped\n' ;;
  esac
done

echo
if [ "$drift" -eq 0 ]; then
  echo "In sync — every managed setting matches the repo."
elif [ "$dry_run" -eq 1 ]; then
  printf '%d setting(s) differ from the repo. Re-run without --dry-run to adopt.\n' "$drift"
else
  printf '%d drifted, %d adopted. Review the diff, then commit and apply with chezmoi.\n' "$drift" "$adopted"
fi

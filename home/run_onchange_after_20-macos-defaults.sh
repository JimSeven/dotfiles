#!/usr/bin/env bash
set -uo pipefail

# macOS system preferences (managed by chezmoi; re-runs when this file changes).
# All settings are idempotent and best-effort.
#
# Best-effort by design: some domains are TCC-protected (Contacts, Calendar,
# Messages) and `defaults write` to them fails unless the running terminal holds
# the matching privacy permission — which a fresh-Mac Apply does not. A single
# such failure must NOT abort the whole run (that used to skip the Dock rebuild
# and Verification), so writes go through `dw`, which warns and continues. The
# loud invariant checks live in Verification (ADR-0008), not here.
#
# To capture new values from a configured machine, use scripts/capture-defaults.sh.

skipped=0

# dw <domain> <key> <flag> <value> — best-effort `defaults write`.
dw() {
  if ! defaults write "$@" 2>/dev/null; then
    printf '  skip: defaults write %s\n' "$*" >&2
    skipped=$((skipped + 1))
  fi
}

# Close System Settings to stop it overriding values we're about to change.
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

###############################################################################
# General                                                                     #
###############################################################################

# Number of recent items (Documents, Apps, Servers)
for category in 'applications' 'documents' 'servers'; do
  /usr/bin/osascript -e "tell application \"System Events\" to tell appearance preferences to set recent $category limit to 5" 2>/dev/null || true
done

###############################################################################
# Dock & Menu Bar                                                             #
###############################################################################

dw com.apple.dock tilesize -int 36
dw com.apple.dock magnification -bool true
dw com.apple.dock largesize -int 90
dw com.apple.dock show-recents -bool false
dw com.apple.dock mineffect -string suck
dw com.apple.dock showAppExposeGestureEnabled -bool true

###############################################################################
# Accessibility                                                               #
###############################################################################

# Three-finger drag
dw com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
dw com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# Zoom with scroll gesture + modifier key (Accessibility › Zoom).
# 262144 = the Control (⌃) modifier flag; hold it and scroll to zoom the screen.
dw com.apple.universalaccess closeViewScrollWheelToggle -bool true
dw com.apple.universalaccess closeViewScrollWheelModifiersInt -int 262144

###############################################################################
# Security & Privacy                                                          #
###############################################################################

# Turn off personalized ads
dw com.apple.AdLib allowApplePersonalizedAdvertising -bool false

###############################################################################
# Bluetooth                                                                   #
###############################################################################

dw com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true

###############################################################################
# Sound                                                                       #
###############################################################################

dw NSGlobalDomain com.apple.sound.beep.feedback -bool true
sudo nvram StartupMute=%01 2>/dev/null \
  || printf '  skip: sudo nvram StartupMute (needs an interactive sudo)\n' >&2

###############################################################################
# Keyboard                                                                    #
###############################################################################

dw NSGlobalDomain KeyRepeat -int 2
dw NSGlobalDomain InitialKeyRepeat -int 15
dw NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
dw NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Full keyboard access for controls (Tab moves focus between all controls)
dw NSGlobalDomain AppleKeyboardUIMode -int 3

###############################################################################
# Mouse & Trackpad                                                            #
###############################################################################

# Pointer tracking speed (System Settings → Mouse / Trackpad).
dw NSGlobalDomain com.apple.mouse.scaling -float 2
dw NSGlobalDomain com.apple.trackpad.scaling -float 2.5

dw com.apple.AppleMultitouchTrackpad Clicking -bool true
dw com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
dw com.apple.dock showAppExposeGestureEnabled -bool true

###############################################################################
# Other                                                                       #
###############################################################################

# Don't reopen windows when logging back in
dw com.apple.loginwindow TALLogoutSavesState -bool false

###############################################################################
# Finder                                                                      #
###############################################################################

dw com.apple.finder NewWindowTarget -string "PfHm"
dw com.apple.finder NewWindowTargetPath -string "file://${HOME}"
dw com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
dw com.apple.finder ShowRecentTags -bool false
dw com.apple.finder FXDefaultSearchScope -string "SCcf"
dw com.apple.finder ShowPathbar -bool true
dw com.apple.finder ShowStatusBar -bool true
dw com.apple.finder FXPreferredViewStyle -string "clmv"
chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy name" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

###############################################################################
# Address Book                                                                #
###############################################################################

dw com.apple.addressbook ABNameSortingFormat -string "sortingFirstName sortingLastName"

###############################################################################
# Calendar                                                                    #
###############################################################################

dw com.apple.iCal "Show Week Numbers" -bool true
dw com.apple.iCal CalendarSidebarShown -bool true

###############################################################################
# Messages                                                                    #
###############################################################################

dw com.apple.messages.text SpellChecking -int 2

# Restart affected apps. Dock is deliberately NOT restarted here: the Dock
# rebuild script (run_onchange_after_30) runs right after and owns the single
# Dock restart. Restarting Dock here would race with that script's dockutil
# writes and silently drop Dock items.
for app in "Calendar" "cfprefsd" "Contacts" "Finder" "Messages"; do
  killall "${app}" &>/dev/null || true
done

if [ "$skipped" -gt 0 ]; then
  printf '⚠️  %d setting(s) skipped (usually TCC-protected domains — grant the\n' "$skipped" >&2
  printf '   terminal Contacts/Calendar/Automation access and re-apply if you need them).\n' >&2
fi
echo "⚠️  Some changes require a logout/restart to take effect. 🚀"

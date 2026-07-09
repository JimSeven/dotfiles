#!/usr/bin/env bash
set -euo pipefail

# macOS system preferences (managed by chezmoi; re-runs when this file changes).
# All settings are idempotent `defaults write` calls.

# Close System Settings to stop it overriding values we're about to change.
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

###############################################################################
# General                                                                     #
###############################################################################

# Number of recent items (Documents, Apps, Servers)
for category in 'applications' 'documents' 'servers'; do
  /usr/bin/osascript -e "tell application \"System Events\" to tell appearance preferences to set recent $category limit to 5"
done

###############################################################################
# Dock & Menu Bar                                                             #
###############################################################################

defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 90
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mineffect -string suck

###############################################################################
# Accessibility                                                               #
###############################################################################

# Three-finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

###############################################################################
# Security & Privacy                                                          #
###############################################################################

# Turn off personalized ads
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false

###############################################################################
# Bluetooth                                                                   #
###############################################################################

defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true

###############################################################################
# Sound                                                                       #
###############################################################################

defaults write NSGlobalDomain com.apple.sound.beep.feedback -bool true
sudo nvram StartupMute=%01

###############################################################################
# Keyboard                                                                    #
###############################################################################

defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Full keyboard access for controls (Tab moves focus between all controls)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

###############################################################################
# Trackpad                                                                    #
###############################################################################

defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.5
defaults write com.apple.dock showAppExposeGestureEnabled -bool true

###############################################################################
# Other                                                                       #
###############################################################################

# Don't reopen windows when logging back in
defaults write com.apple.loginwindow TALLogoutSavesState -bool false

###############################################################################
# Finder                                                                      #
###############################################################################

defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowRecentTags -bool false
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy name" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

###############################################################################
# Address Book                                                                #
###############################################################################

defaults write com.apple.addressbook ABNameSortingFormat -string "sortingFirstName sortingLastName"

###############################################################################
# Calendar                                                                    #
###############################################################################

defaults write com.apple.iCal "Show Week Numbers" -bool true
defaults write com.apple.iCal CalendarSidebarShown -bool true

###############################################################################
# Messages                                                                    #
###############################################################################

defaults write com.apple.messages.text SpellChecking -int 2

# Restart affected apps
for app in "Calendar" "cfprefsd" "Contacts" "Dock" "Finder" "Messages"; do
  killall "${app}" &>/dev/null || true
done

echo "⚠️  Some changes require a logout/restart to take effect. 🚀"

#!/usr/bin/env bash

DOTFILES_PATH="$HOME/.dotfiles"

sudo -v

# Update macOS
sudo softwareupdate -i -a

# Command Line Tools
if ! [ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]; then
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
  PROD=$(softwareupdate -l | grep "*.*Command Line" | tail -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | sed 's/Label: //g' | tr -d '\n')
  softwareupdate -i "$PROD" --verbose
  rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
fi

if [ ! -d "$DOTFILES_PATH" ]; then
  echo "Installing dotfiles..."
  git clone https://github.com/JimSeven/dotfiles.git $DOTFILES_PATH
else
  echo "Updating dotfiles..."
  git -C $DOTFILES_PATH pull --rebase
fi

cd $DOTFILES_PATH
make
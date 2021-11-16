# The default shell is /bin/sh. We use bash
SHELL = /bin/bash
# Path to oh-my-zsh
OH_MY_ZSH_DIR := $(HOME)/.oh-my-zsh
# Path to .dotfiles
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# List all dotfiles
HOMEFILES := $(shell ls -A files | grep "^\.")
DOTFILES := $(addprefix $(HOME)/,$(HOMEFILES))
# Path to dockutil script
DOCKUTIL_PATH = /usr/local/bin/dockutil
# Path to macOS user fonts
FONTS_DIR := $(HOME)/Library/Fonts
# Path to website project
SITES_DIR := $(HOME)/Sites

# Helper functions
install_vscode_extension = code --install-extension $(1)
install_brew_package = brew list --versions $(1) > /dev/null || brew install $(1)
install_brew_cask = brew list --cask --versions $(1) > /dev/null || brew install --cask --no-quarantine  --force $(1)
install_mas_app = mas install $(1)
uninstall_brew_package = brew rm $$(brew deps $(1)) $(1)
uninstall_brew_cask = brew rm $(1)

# Do not care about local files
.PHONY: all install sudo brew

all: install

install: brew-packages addons macos-preferences link valet

addons: vs-code-extensions meslo-nerd-font

valet: @$(call install_brew_package,php)
	composer global require laravel/valet
	valet install
	valet domain localhost
	valet use php@8.0
	[ -d $(SITES_DIR) ] || mkdir -p $(SITES_DIR)
	cd $(SITES_DIR)
	valet park
	cd $(HOME)


brew-packages: brew-taps
	@brew update --force
# Programming language prerequisites and package managers
	@$(call install_brew_package,composer)
	@$(call install_brew_package,git)
	@$(call install_brew_package,volta)
# Terminal tools
	@$(call install_brew_package,antigen)
	@$(call install_brew_cask,iterm2)
	@$(call install_brew_cask,fig)
	@defaults write com.googlecode.iterm2 PrefsCustomFolder $(DOTFILES_DIR)/files
	@defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
# Dev tools
	@$(call install_brew_package,php-cs-fixer)
	@$(call install_brew_package,jpegoptim)
	@$(call install_brew_package,optipng)
	@$(call install_brew_package,imagemagick)
	@$(call install_brew_package,browserstacklocal)
	@$(call install_brew_cask,sketch)
	@$(call install_brew_cask,tableplus)
	@$(call install_brew_cask,tunnelblick)
	@$(call install_brew_cask,visual-studio-code)
# Productivity
	@$(call install_brew_cask,clockify)
	@$(call install_brew_cask,dropbox)
	@$(call install_brew_cask,google-drive)
	@$(call install_brew_cask,1password)
	@$(call install_brew_cask,notion)
# Communication
	@$(call install_brew_cask,microsoft-teams)
	@$(call install_brew_cask,slack)
	@$(call install_brew_cask,whatsapp)
# Browsers
	@$(call install_brew_cask,google-chrome)
	@$(call install_brew_cask,firefox-developer-edition)
# Audio & Video
	@$(call install_brew_cask,amazon-music)
	@$(call install_brew_cask,iina)
	@$(call install_brew_cask,spotify)
# macOS utils
	@$(call install_brew_package,dockutil)
	@sudo curl -sL https://raw.githubusercontent.com/kcrawford/dockutil/master/scripts/dockutil -o $(DOCKUTIL_PATH) && sudo chmod +x $(DOCKUTIL_PATH)
	@$(call install_brew_cask,finicky)
	@$(call install_brew_package,mas)

mas-apps: brew-packages
ifndef GITHUB_ACTION
# Keynote
	@$(call install_mas_app,409183694)
# Numbers
	@$(call install_mas_app,409203825)
# Pages
	@$(call install_mas_app,409201541)
# Magnet
	@$(call install_mas_app,441258766)
# LittleIpsum
	@$(call install_mas_app,405772121)
# Microsoft To Do
	@$(call install_mas_app,1274495053)
# Save to Raindrop.io
	@$(call install_mas_app,1549370672)
# Flycut
	@$(call install_mas_app,442160987)
# Affinity Designer
	@$(call install_mas_app,824171161)
# Affinity Photo
	@$(call install_mas_app,824183456)
# Spark
	@$(call install_mas_app,1176895641)

endif

sudo:
ifndef GITHUB_ACTION
	@sudo -v
	@while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

brew: sudo
	@command -v brew >/dev/null 2>&1 || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

uninstall-brew: sudo
	@! command -v brew >/dev/null 2>&1 || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh | bash

brew-taps: brew
	@brew tap homebrew/cask-versions
	@brew tap homebrew/command-not-found

oh-my-zsh:
	@[[ -d $(OH_MY_ZSH_DIR) ]] || curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash

uninstall-oh-my-zsh:
# https://github.com/ohmyzsh/ohmyzsh/wiki/FAQ#how-do-i-uninstall-oh-my-zsh
	#curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/uninstall.sh | bash

vs-code-extensions:
	@$(call install_vscode_extension,bernardodsanderson.theme-material-neutral)
	@$(call install_vscode_extension,pkief.material-icon-theme)
	@$(call install_vscode_extension,graphql.vscode-graphql)
	@$(call install_vscode_extension,ms-azuretools.vscode-docker)
	@$(call install_vscode_extension,mechatroner.rainbow-csv)
	@$(call install_vscode_extension,redhat.vscode-yaml)
	@$(call install_vscode_extension,mikestead.dotenv)
	@$(call install_vscode_extension,prisma.prisma)
	@$(call install_vscode_extension,dbaeumer.vscode-eslint)
	@$(call install_vscode_extension,ms-vsliveshare.vsliveshare)
	@$(call install_vscode_extension,esbenp.prettier-vscode)
	@$(call install_vscode_extension,richie5um2.vscode-sort-json)
	@$(call install_vscode_extension,stylelint.vscode-stylelint)
	@$(call install_vscode_extension,vivaxy.vscode-conventional-commits)

meslo-nerd-font:
	@echo Installing Meslo LGS Nerd Font...
	@[[ -d $(FONTS_DIR) ]] || mkdir -p "$(FONTS_DIR)"
	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -o "$(FONTS_DIR)/Meslo LGS NF Regular.ttf"
	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -o "$(FONTS_DIR)/Meslo LGS NF Bold.ttf"
	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -o "$(FONTS_DIR)/Meslo LGS NF Italic.ttf"
	@curl -sL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -o "$(FONTS_DIR)/Meslo LGS NF Bold Italic.ttf"

macos-preferences:
	@$(SHELL) scripts/macos-system-preferences.sh
	@$(SHELL) scripts/dock-items.sh

link: | $(DOTFILES)
	@[[ -d "$(HOME)/Library/Application Support/Code/User" ]] || mkdir -p "$(HOME)/Library/Application Support/Code/User"
	@ln -sfv $(DOTFILES_DIR)/files/vscode.settings.json "$(HOME)/Library/Application Support/Code/User/settings.json"
	@ln -sfv $(DOTFILES_DIR)/files/com.colliderli.iina.plist $(HOME)/Library/Preferences/com.colliderli.iina.plist

# This will link all of our dot files into our files directory. The
# magic happening in the first arg to ln is just grabbing the file name
# and appending the path to dotfiles/home
$(DOTFILES):
	@ln -sfv "$(PWD)/files/$(notdir $@)" $@

# Interactively delete symbolic links.
unlink:
	@echo "Unlinking dotfiles"
	@for f in $(DOTFILES); do if [ -h $$f ]; then rm -i $$f; fi ; done

test:
	@brew unlink bats
	@$(call install_brew_package,bats-core)
	@bats tests
	@$(call uninstall_brew_package,bats-core)
	@brew cleanup

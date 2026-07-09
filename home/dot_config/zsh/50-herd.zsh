# Laravel Herd — PHP (7.4–8.5) + Node via Herd's bundled NVM (see ADR-0003).
# Managed here so a fresh Mac reproduces it. Herd may also re-inject these into
# ~/.zshrc; chezmoi cleans that up on the next apply.

herd_config="$HOME/Library/Application Support/Herd/config"

# PHP ini scan dirs (one per installed version)
export HERD_PHP_74_INI_SCAN_DIR="$herd_config/php/74/"
export HERD_PHP_82_INI_SCAN_DIR="$herd_config/php/82/"
export HERD_PHP_83_INI_SCAN_DIR="$herd_config/php/83/"
export HERD_PHP_84_INI_SCAN_DIR="$herd_config/php/84/"
export HERD_PHP_85_INI_SCAN_DIR="$herd_config/php/85/"

# Herd binaries on PATH
path=("$HOME/Library/Application Support/Herd/bin" $path)
typeset -U path
export PATH

# Node via Herd's NVM
export NVM_DIR="$herd_config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Herd shell integration
[[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] \
  && builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"

unset herd_config

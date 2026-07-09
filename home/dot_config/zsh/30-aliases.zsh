# Aliases. Git aliases come from the oh-my-zsh git plugin (see ~/.zsh_plugins.txt).

# Listing (eza)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --git --group-directories-first'
  alias la='eza -a --group-directories-first'
  alias lt='eza --tree --level=2'
fi

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias o='open .'

# Quality of life
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'
alias reload='exec zsh'
alias path='echo $PATH | tr ":" "\n"'

# This dotfiles setup
alias cz='chezmoi'
alias cza='chezmoi apply'
alias czd='chezmoi diff'
alias cze='chezmoi edit'
alias brewup='brew update && brew upgrade && brew cleanup'
alias zshconfig='${EDITOR:-micro} ${XDG_CONFIG_HOME:-$HOME/.config}/zsh'

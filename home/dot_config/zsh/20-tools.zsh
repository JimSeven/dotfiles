# Tool initialisation. Order matters:
# antidote (plugins) → fzf → zoxide → direnv → Starship (prompt last).

# --- antidote: load plugins from ~/.zsh_plugins.txt ---
antidote_zsh="$(brew --prefix antidote 2>/dev/null)/share/antidote/antidote.zsh"
if [[ -r "$antidote_zsh" ]]; then
  source "$antidote_zsh"
  antidote load "${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
fi
unset antidote_zsh

# --- fzf: Ctrl-R history, Ctrl-T files, ** completion ---
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)

# --- zoxide: smart cd (`z`, `zi`) ---
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# --- direnv: per-directory environments ---
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# --- Starship prompt (keep last) ---
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

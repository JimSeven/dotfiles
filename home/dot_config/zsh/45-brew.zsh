# Homebrew maintenance + staleness reminder.
#
# Best practice on a controlled dev machine is no background auto-upgrade: brew
# upgrades should happen when *you* pick the moment (they can pull breaking
# minors and restart GUI casks). So this module keeps the trigger manual —
# `brewup` — but records when it last ran and nudges once a shell starts if that
# was too long ago. So you never have to *remember* to upgrade, only to do it.

zmodload zsh/datetime 2>/dev/null   # provides $EPOCHSECONDS

# Epoch seconds of the last successful `brewup`. State (not cache): a lost stamp
# should surface the reminder, not be silently treated as "just upgraded".
BREW_STAMP="${XDG_STATE_HOME:-$HOME/.local/state}/brew-lastupgrade"
# Nudge once the last upgrade is older than this. Override in 10-env.zsh (must be
# set before this module is sourced, so .zshrc.local is too late for the nudge).
: "${BREW_STALE_DAYS:=14}"

# update + upgrade + cleanup, then stamp the time so the nudge resets. Casks that
# self-update (auto_updates true) are skipped by `brew upgrade` by design — add
# --greedy manually if you ever want them too.
brewup() {
  local step rc
  for step in update upgrade cleanup; do
    brew "$step" || {
      rc=$?
      print -P "%F{red}brewup: 'brew ${step}' fehlgeschlagen (rc=${rc}) — Stempel nicht gesetzt.%f" >&2
      return $rc
    }
  done
  mkdir -p "${BREW_STAMP:h}"
  print -r -- "$EPOCHSECONDS" >| "$BREW_STAMP"
}

# Interactive nudge. Deliberately cheap: reads the stamp file only, never shells
# out to brew (which is slow), so it adds nothing measurable to shell startup.
_brew_staleness_nudge() {
  command -v brew >/dev/null 2>&1 || return
  local last age
  if [[ -r "$BREW_STAMP" ]] && last=$(<"$BREW_STAMP") && [[ "$last" == <-> ]]; then
    age=$(( (EPOCHSECONDS - last) / 86400 ))
    (( age >= BREW_STALE_DAYS )) && \
      print -P "%F{yellow}Homebrew: letztes Upgrade vor ${age} Tagen — 'brewup' ausführen.%f"
  else
    print -P "%F{yellow}Homebrew: Upgrade-Alter unbekannt — einmal 'brewup' ausführen.%f"
  fi
}
_brew_staleness_nudge

#!/usr/bin/env bash
# run_after_90-verify.sh — post-apply verification seam (ADR-0008).
#
# Asserts the invariants `chezmoi apply` should guarantee but otherwise never
# checks, so a broken Bridge (ADR-0007) or a moved Herd integration path fails
# LOUD here instead of silently on next use. Runs on-machine only — a headless
# CI runner has no real $HOME to inspect and --dry-run skips run_ scripts, so
# there is deliberately no CI adapter (ADR-0008).

set -u

defaults_file="$HOME/.config/agents/defaults.md"
fail=0

# check "<name>" <command...> — run the command, print PASS/FAIL, tally failures.
check() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf '  \033[32mPASS\033[0m  %s\n' "$name"
  else
    printf '  \033[31mFAIL\033[0m  %s\n' "$name"
    fail=1
  fi
}

# symlink_targets <link> <expected> — link exists and resolves to expected.
symlink_targets() {
  [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]
}

# file_contains <file> <fixed-string> — file exists and contains the string.
file_contains() {
  [ -f "$1" ] && grep -qF "$2" "$1"
}

# no_shadow <label> <managed> <competing>... — a tool with several config search
# paths silently loads the highest-priority one. If a competing path exists beside
# the managed config, `apply` reports success while the tool may use a different
# file — a silent failure mode. Guard against it loud here. Skips when the managed
# config is absent on this machine (never false-positives).
no_shadow() {
  local label="$1" managed="$2"
  shift 2
  if [ ! -e "$managed" ] && [ ! -L "$managed" ]; then
    return 0
  fi
  local p
  for p in "$@"; do
    if [ -e "$p" ] || [ -L "$p" ]; then
      printf '  \033[31mFAIL\033[0m  %s: %s exists beside managed %s\n' "$label" "$p" "$managed"
      fail=1
      return 0
    fi
  done
  printf '  \033[32mPASS\033[0m  %s: no competing config beside %s\n' "$label" "$managed"
}

printf 'verify: agent Bridges resolve to the canonical Defaults (ADR-0007)\n'
check "Defaults file exists"           test -f "$defaults_file"
check "Codex bridge -> Defaults"       symlink_targets "$HOME/.codex/AGENTS.md" "$defaults_file"
check "Claude bridge imports Defaults" file_contains "$HOME/.claude/CLAUDE.md" "@~/.config/agents/defaults.md"
check "opencode bridge -> Defaults"    file_contains "$HOME/.config/opencode/opencode.json" "$defaults_file"

# Herd check is conditional: only when Herd is actually installed, so it never
# false-positives on a non-Herd machine (ADR-0008).
herd_app="/Applications/Herd.app"
herd_integration="$herd_app/Contents/Resources/config/shell/zshrc.zsh"
if [ -d "$herd_app" ]; then
  printf 'verify: Herd shell integration (ADR-0003)\n'
  check "Herd integration path present" test -f "$herd_integration"
fi

# Shadow-config guard (ADR-0008): finicky reads the FIRST of six search paths, so a
# stray ~/.config/finicky/* would be silently ignored in favour of our ~/.finicky.js;
# git reads ~/.config/git/config in addition to the managed ~/.gitconfig.
printf 'verify: no shadow configs on other search paths (ADR-0008)\n'
no_shadow "finicky" "$HOME/.finicky.js" \
  "$HOME/.finicky.ts" \
  "$HOME/.config/finicky.js" "$HOME/.config/finicky.ts" \
  "$HOME/.config/finicky/finicky.js" "$HOME/.config/finicky/finicky.ts"
no_shadow "git" "$HOME/.gitconfig" "$HOME/.config/git/config"

if [ "$fail" -ne 0 ]; then
  printf '\n\033[31mverify: one or more checks failed — fix before relying on this machine\033[0m\n' >&2
  exit 1
fi
printf '\nverify: all checks passed\n'

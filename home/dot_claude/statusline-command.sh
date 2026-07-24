#!/usr/bin/env bash
# Claude Code status line — robbyrussell style
# Archetype: situational awareness — dir / git+dirty / model / ctx%
# Robustness (R2): jq guard, git calls time-boxed, all errors silenced,
#                  empty segments dropped.

input=$(cat)

# --- ANSI colors -------------------------------------------------------------
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
RESET='\033[0m'

# --- jq guard ----------------------------------------------------------------
# Without jq we cannot parse the JSON payload; degrade to a minimal marker
# instead of emitting a broken line.
if ! command -v jq >/dev/null 2>&1; then
  printf "${GREEN}➜${RESET}  ${CYAN}%s${RESET}  ${DIM}(jq missing)${RESET}" "$(basename "$PWD")"
  exit 0
fi

cwd=$(printf '%s' "$input" | jq -r '.cwd // .workspace.current_dir // ""')
[ -n "$cwd" ] || cwd="$PWD"

model=$(printf '%s' "$input" | jq -r '.model.display_name // ""')

# --- portable, time-boxed git ------------------------------------------------
# No `timeout` on stock macOS; fall back through gtimeout -> timeout -> perl
# alarm -> direct. Keeps a wedged git (network FS, huge repo) from hanging
# the whole status line.
if command -v gtimeout >/dev/null 2>&1; then
  _tmo() { gtimeout "$@"; }
elif command -v timeout >/dev/null 2>&1; then
  _tmo() { timeout "$@"; }
elif command -v perl >/dev/null 2>&1; then
  _tmo() { local s="$1"; shift; perl -e 'alarm shift; exec @ARGV' "$s" "$@"; }
else
  _tmo() { shift; "$@"; }
fi

_git() { _tmo 1 git -C "$cwd" -c core.hooksPath=/dev/null "$@" 2>/dev/null; }

# --- git segment (G2): branch + dirty marker ---------------------------------
branch=""
dirty=""
if _git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(_git symbolic-ref --short HEAD 2>/dev/null || _git rev-parse --short HEAD 2>/dev/null)
  # Dirty check via porcelain: catches staged, unstaged AND untracked files
  # (e.g. files Claude created but hasn't `git add`-ed yet).
  if [ -n "$(_git status --porcelain 2>/dev/null)" ]; then
    dirty=" ✗"
  fi
fi

# --- path segment (P2): repo-relative, else basename -------------------------
# Let git compute the in-repo prefix (--show-prefix); this is symlink-agnostic,
# unlike stripping the toplevel path by hand (breaks on /tmp -> /private/tmp).
root=""
[ -n "$branch" ] && root=$(_git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$root" ]; then
  repo=$(basename "$root")
  rel=$(_git rev-parse --show-prefix 2>/dev/null)
  rel="${rel%/}"
  if [ -n "$rel" ]; then
    dir="$repo/$rel"
  else
    dir="$repo"
  fi
else
  dir=$(basename "$cwd")
fi

# --- context segment (C2): threshold colors, 20/50 ---------------------------
ctx_str=""
used=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  # <20 green · 20-50 yellow · >50 red
  ctx_color=$(awk -v u="$used" 'BEGIN{ if (u<20) print "g"; else if (u<=50) print "y"; else print "r" }')
  case "$ctx_color" in
    g) CTX="$GREEN" ;;
    y) CTX="$YELLOW" ;;
    r) CTX="$RED" ;;
  esac
  ctx_str=$(printf "${CTX} ctx:%.0f%%${RESET}" "$used")
fi

# --- render (V1: robbyrussell plaintext) -------------------------------------
line="${GREEN}➜${RESET}  ${CYAN}${dir}${RESET}"
[ -n "$branch" ] && line="${line}  ${DIM}git:(${RESET}${branch}${RED}${dirty}${RESET}${DIM})${RESET}"
[ -n "$model" ]  && line="${line}  ${YELLOW}${model}${RESET}"
line="${line}${ctx_str}"

printf "%b" "$line"

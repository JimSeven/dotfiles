#!/usr/bin/env bash
# Claude Code status line — robbyrussell style

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
dir=$(basename "$cwd")

model=$(echo "$input" | jq -r '.model.display_name // ""')

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  ctx_str=$(printf " ctx:%.0f%%" "$used")
else
  ctx_str=""
fi

# Git branch (skip optional locks)
branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null \
            || git -C "$cwd" -c core.hooksPath=/dev/null rev-parse --short HEAD 2>/dev/null)
fi

# Build prompt segments using ANSI colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
DIM='\033[2m'
RESET='\033[0m'

if [ -n "$branch" ]; then
  printf "${GREEN}➜${RESET}  ${CYAN}%s${RESET}  ${DIM}git:(%s)${RESET}  ${YELLOW}%s${RESET}${DIM}%s${RESET}" \
    "$dir" "$branch" "$model" "$ctx_str"
else
  printf "${GREEN}➜${RESET}  ${CYAN}%s${RESET}  ${YELLOW}%s${RESET}${DIM}%s${RESET}" \
    "$dir" "$model" "$ctx_str"
fi

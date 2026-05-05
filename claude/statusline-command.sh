#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# PS1-style: \u@\h:\w  (green user@host, blue path — matching ~/.bashrc PS1)
user=$(whoami)
host=$(hostname -s)
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd' 2>/dev/null)
# Collapse $HOME to ~
current_dir_display="${current_dir/#$HOME/~}"

# ANSI colors (bold green / bold blue / reset)
GREEN='\033[01;32m'
BLUE='\033[01;34m'
RESET='\033[00m'

# Extract model display name (short version)
model_full=$(echo "$input" | jq -r '.model.display_name // .model.id' 2>/dev/null || echo "Unknown")
if [[ "$model_full" =~ Opus ]]; then
    model="Opus"
elif [[ "$model_full" =~ Sonnet ]]; then
    model="Sonnet"
elif [[ "$model_full" =~ Haiku ]]; then
    model="Haiku"
else
    model="$model_full"
fi

# Get model version number from id (e.g., claude-sonnet-4-6 -> 4.6)
model_id=$(echo "$input" | jq -r '.model.id // ""' 2>/dev/null)
version=$(echo "$model_id" | grep -oP '\d+-\d+$' | tr '-' '.')
[ -n "$version" ] && model="$model $version"

# Get git branch if in a git repository (skip optional locks)
branch=""
if git -C "$current_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$current_dir" -c core.fsmonitor=false branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        branch=" ($branch)"
    fi
fi

# Format: user@host:~/path (branch) • Model version
printf "${GREEN}%s@%s${RESET}:${BLUE}%s${RESET}%s • %s" \
    "$user" "$host" "$current_dir_display" "$branch" "$model"

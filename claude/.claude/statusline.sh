#!/usr/bin/env bash
# Claude Code statusline (Catppuccin Mocha): branch  ....  model · ctx · cost · 5h · 7d
input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(printf '%s'  "$input" | jq -r '.workspace.current_dir // .cwd // empty')
fast=$(printf '%s' "$input" | jq -r '.fast_mode // false')
h5=$(printf '%s'   "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
d7=$(printf '%s'   "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
h5r=$(printf '%s'  "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
d7r=$(printf '%s'  "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
ctx_pct=$(printf '%s'  "$input" | jq -r '.context_window.used_percentage // empty')
ctx_used=$(printf '%s' "$input" | jq -r '((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0))')
ctx_size=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // empty')
add=$(printf '%s'  "$input" | jq -r '.cost.total_lines_added // 0')
del=$(printf '%s'  "$input" | jq -r '.cost.total_lines_removed // 0')

# Catppuccin Mocha palette (truecolor; literal escapes resolved once via printf %b)
DIM='\033[38;2;127;132;156m'      # Overlay1  — labels / separators
MODEL='\033[38;2;180;190;254m'    # Catppuccin Lavender (#b4befe)
DIR='\033[38;2;137;180;250m'      # Blue      — current directory
BRANCH='\033[38;2;166;227;161m'   # Green     — git branch
GREEN='\033[38;2;166;227;161m'    # Green
AMBER='\033[38;2;249;226;175m'    # Yellow
RED='\033[38;2;243;139;168m'      # Red
SURF='\033[38;2;88;91;112m'       # Surface2 — empty track
RESET='\033[0m'
SEP=" ${DIM}·${RESET} "
# ctx heat gradient (Catppuccin pastels), green→yellow→peach→red, one "R;G;B" per cell
GRAD=(166\;227\;161 194\;226\;166 222\;226\;170 249\;226\;175 250\;210\;162 \
      250\;194\;148 250\;179\;135 247\;166\;146 245\;152\;157 243\;139\;168)

# git branch (only if cwd is inside a work tree)
branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# fmt_eta: compact "time until reset" from a unix timestamp (2d 4h / 3h 20m / 45m)
fmt_eta() {
  local reset=$1 now=$2 diff d h m
  diff=$(( reset - now )); [ "$diff" -lt 0 ] && diff=0
  d=$(( diff / 86400 )); h=$(( (diff % 86400) / 3600 )); m=$(( (diff % 3600) / 60 ))
  if   [ "$d" -gt 0 ]; then printf '%dd %dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}

# usage: "<label> <pct>% ↻ in <eta>", pct colored by level; dim placeholder if absent
usage() {
  local label=$1 raw=$2 reset=$3 pct color out
  if [ -z "$raw" ]; then
    printf '%s%s %s—%s' "$DIM" "$label" "$DIM" "$RESET"; return
  fi
  pct=${raw%.*}; [ -z "$pct" ] && pct=0
  if   [ "$pct" -ge 80 ]; then color=$RED
  elif [ "$pct" -ge 50 ]; then color=$AMBER
  else color=$GREEN; fi
  out="${DIM}${label}${RESET} ${color}${pct}%${RESET}"
  [ -n "$reset" ] && out+=" ${DIM}↻ in $(fmt_eta "$reset" "$NOW")${RESET}"
  printf '%s' "$out"
}

# ctxbar: solid track with per-cell heat gradient (filled), Surface for empty
ctxbar() {
  local pct=$1 width=${#GRAD[@]} i filled out=""
  filled=$(( (pct * width + 50) / 100 ))
  [ "$filled" -gt "$width" ] && filled=$width
  [ "$filled" -lt 0 ] && filled=0
  for ((i=0;i<width;i++)); do
    if [ "$i" -lt "$filled" ]; then out+="\033[38;2;${GRAD[i]}m█"; else out+="${SURF}█"; fi
  done
  printf '%s%s' "$out" "$RESET"
}

# LEFT group: current directory (home shortened to ~) · branch (if a repo)
dir="$cwd"
case "$dir" in
  "$HOME")   dir="~" ;;
  "$HOME"/*) dir="~/${dir#"$HOME"/}" ;;
esac
left=""
[ -n "$dir" ] && left+="${DIR}${dir}${RESET}"
if [ -n "$branch" ]; then
  [ -n "$left" ] && left+="$SEP"
  left+="${BRANCH}⎇ ${branch}${RESET}"
fi

# model (+ ⚡) joins dir · branch on the first (right-aligned) line
modelseg="${MODEL}✳ ${model}${RESET}"
[ "$fast" = "true" ] && modelseg+=" ${AMBER}⚡${RESET}"
[ -n "$left" ] && left+="$SEP"
left+="$modelseg"

# RIGHT group (line 2): context · usage meters · diff
right=""

warn=""
if [ -n "$ctx_pct" ] || [ -n "$ctx_size" ]; then
  cpct=${ctx_pct%.*}
  if [ -z "$cpct" ] && [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ]; then
    cpct=$(( ctx_used * 100 / ctx_size ))
  fi
  [ -z "$cpct" ] && cpct=0
  if   [ "$cpct" -ge 80 ]; then cc=$RED
  elif [ "$cpct" -ge 50 ]; then cc=$AMBER
  else cc=$GREEN; fi
  [ "$cpct" -ge 80 ] && warn=" ${RED}▲${RESET}"
  right+="${SEP}${DIM}ctx${RESET} $(ctxbar "$cpct") ${cc}${cpct}%${RESET}${warn}"
fi

NOW=$(date +%s)
# show each meter only when the window is present (7d is often absent — it
# populates later in a session, or not at all if there's no active weekly limit)
[ -n "$h5" ] && right+="${SEP}$(usage 5h "$h5" "$h5r")"
[ -n "$d7" ] && right+="${SEP}$(usage 7d "$d7" "$d7r")"

# diff stats last (session lines added/removed)
if [ "$add" -gt 0 ] || [ "$del" -gt 0 ]; then
  right+="${SEP}${GREEN}+${add}${RESET} ${RED}-${del}${RESET}"
fi

# two lines: dir · branch (right-aligned)  /  model · ctx · usage · diff (left)
# Claude Code sets $COLUMNS to the terminal width before running us (tput can't
# see it — output is captured, not a tty). Right-align by padding to that width;
# visible length ignores ANSI color codes, so strip them before measuring.
if [ -n "$left" ]; then
  rendered=$(printf '%b' "$left")
  plain=$(printf '%s' "$rendered" | sed $'s/\033\[[0-9;]*m//g')
  cols=${COLUMNS:-0}
  if [ "$cols" -gt 0 ] && [ "${#plain}" -lt "$cols" ]; then
    printf '%*s%b\n' "$(( cols - ${#plain} ))" '' "$left"
  else
    printf '%b\n' "$left"
  fi
fi
printf '%b\n' "${right#"$SEP"}"

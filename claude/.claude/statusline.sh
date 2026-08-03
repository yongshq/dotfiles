#!/usr/bin/env bash
# Claude Code statusline (Catppuccin Mocha):
#   line 1: session name · +add -del      (random placeholder title if invalid)
#   line 2: model · effort · ctx% · 5h
#   line 3: dir · branch
input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(printf '%s'  "$input" | jq -r '.workspace.current_dir // .cwd // empty')
fast=$(printf '%s' "$input" | jq -r '.fast_mode // false')
h5=$(printf '%s'   "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
h5r=$(printf '%s'  "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
ctx_pct=$(printf '%s'  "$input" | jq -r '.context_window.used_percentage // empty')
ctx_used=$(printf '%s' "$input" | jq -r '((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0))')
ctx_size=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // empty')
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
session=$(printf '%s' "$input" | jq -r '.session_name // empty')
add=$(printf '%s'  "$input" | jq -r '.cost.total_lines_added // 0')
del=$(printf '%s'  "$input" | jq -r '.cost.total_lines_removed // 0')
dur_ms=$(printf '%s' "$input" | jq -r '.cost.total_duration_ms // empty')

# Catppuccin Mocha palette (truecolor; literal escapes resolved once via printf %b)
DIM='\033[38;2;127;132;156m'      # Overlay1  — labels / separators
MODEL='\033[38;2;180;190;254m'    # Catppuccin Lavender (#b4befe) — model name
SESSION='\033[38;2;203;166;247m'  # Catppuccin Mauve (#cba6f7) — session name
DIR='\033[38;2;108;112;134m'      # Catppuccin Overlay0 (#6c7086) — dark gray directory
BRANCH='\033[38;2;148;176;136m'   # muted sage green (#94b088) — git branch
GREEN='\033[38;2;166;227;161m'    # Green
AMBER='\033[38;2;249;226;175m'    # Yellow
RED='\033[38;2;243;139;168m'      # Red
DIFF_ADD='\033[38;2;148;176;136m' # muted sage green (#94b088) — diff added lines
DIFF_DEL='\033[38;2;196;144;152m' # muted rose (#c49098)      — diff removed lines
SURF='\033[38;2;88;91;112m'       # Surface2 — empty track
ITALIC='\033[3m'                  # placeholder session titles wear italic
RESET='\033[0m'
SEP=" ${DIM}·${RESET} "
# heat: echo an SGR truecolor escape (as literal \033…, resolved later via %b)
# fading greyish (Overlay1 127;132;156) → red (243;139;168) across a 0..100 level
heat() {
  local p=$1 r g b
  [ "$p" -lt 0 ] && p=0; [ "$p" -gt 100 ] && p=100
  r=$(( 127 + (243 - 127) * p / 100 ))
  g=$(( 132 + (139 - 132) * p / 100 ))
  b=$(( 156 + (168 - 156) * p / 100 ))
  printf '%s' "\033[38;2;${r};${g};${b}m"
}

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

# fmt_dur: compact elapsed time from milliseconds (2h 4m / 5m / 45s)
fmt_dur() {
  local ms=$1 s h m
  s=$(( ms / 1000 ))
  h=$(( s / 3600 )); m=$(( (s % 3600) / 60 ))
  if   [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
  elif [ "$m" -gt 0 ]; then printf '%dm' "$m"
  else printf '%ds' "$(( s % 60 ))"; fi
}

# usage: "<label> <pct>% ↻ in <eta>", pct faded grey→red; dim placeholder if absent
usage() {
  local label=$1 raw=$2 reset=$3 pct out
  if [ -z "$raw" ]; then
    printf '%s%s %s—%s' "$DIM" "$label" "$DIM" "$RESET"; return
  fi
  pct=${raw%.*}; [ -z "$pct" ] && pct=0
  out="${DIM}${label}${RESET} $(heat "$pct")${pct}%${RESET}"
  [ -n "$reset" ] && out+=" ${DIM}↻ in $(fmt_eta "$reset" "$NOW")${RESET}"
  printf '%s' "$out"
}

# ctxbar: solid track with a grey→red heat gradient across cells (filled),
# Surface for the empty tail — same colour progression as the usage percentages
ctxbar() {
  local pct=$1 width=10 i filled out=""
  filled=$(( (pct * width + 50) / 100 ))
  [ "$filled" -gt "$width" ] && filled=$width
  [ "$filled" -lt 0 ] && filled=0
  for ((i=0;i<width;i++)); do
    if [ "$i" -lt "$filled" ]; then out+="$(heat $(( i * 100 / (width - 1) )))█"; else out+="${SURF}█"; fi
  done
  printf '%s%s' "$out" "$RESET"
}

# join existing line ($1) with a new segment ($2) via SEP; echoes the result.
# (nameref-free so it works on macOS's stock bash 3.2)
join() { if [ -n "$1" ]; then printf '%s%s%s' "$1" "$SEP" "$2"; else printf '%s' "$2"; fi; }

NOW=$(date +%s)

# --- individual segments -------------------------------------------------

# directory (home shortened to ~)
dir="$cwd"
case "$dir" in
  "$HOME")   dir="~" ;;
  "$HOME"/*) dir="~/${dir#"$HOME"/}" ;;
esac
dirseg=""
# Nerd Font opened-folder glyph (nf-cod-folder_opened, U+F4D4) via its UTF-8
# bytes, so the private-use codepoint survives editors that would mangle it
FOLDER=$(printf '\357\223\224')
[ -n "$dir" ] && dirseg="${DIR}${FOLDER} ${dir}${RESET}"
branchseg=""
# fa-code-fork glyph (U+F126) via UTF-8 bytes, so it survives editors
BRANCH_ICON=$(printf '\357\204\246')
[ -n "$branch" ] && branchseg="${BRANCH}${BRANCH_ICON} ${branch}${RESET}"

# model (+ effort + ⚡)
MODEL_ICON=$(printf '\357\213\233')   # nf-fa-microchip (U+F2DB) via UTF-8 bytes
modelseg="${MODEL}${MODEL_ICON} ${model}${RESET}"
[ -n "$effort" ] && modelseg+=" ${DIM}${effort}${RESET}"
[ "$fast" = "true" ] && modelseg+=" ${AMBER}⚡${RESET}"

# ctx meter — bar + %, omitted entirely while still 0% (nothing to show yet)
ctxseg=""
if [ -n "$ctx_pct" ] || [ -n "$ctx_size" ]; then
  cpct=${ctx_pct%.*}
  if [ -z "$cpct" ] && [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ]; then
    cpct=$(( ctx_used * 100 / ctx_size ))
  fi
  [ -z "$cpct" ] && cpct=0
  cc=$(heat "$cpct")   # grey→red, same progression as the usage percentages
  warn=""; [ "$cpct" -ge 80 ] && warn=" ${RED}▲${RESET}"
  [ "$cpct" -gt 0 ] && ctxseg="${DIM}ctx${RESET} $(ctxbar "$cpct") ${cc}${cpct}%${RESET}${warn}"
fi

# 5h rate-limit window (shown only when present)
h5seg=""; [ -n "$h5" ] && h5seg="$(usage 5h "$h5" "$h5r")"

# session wall-clock duration (clock glyph + elapsed), shown when available
durseg=""
if [ -n "$dur_ms" ] && [ "$dur_ms" -gt 0 ] 2>/dev/null; then
  CLOCK=$(printf '\357\200\227')   # nf-fa-clock_o (U+F017) via its UTF-8 bytes
  durseg="${DIM}${CLOCK} $(fmt_dur "$dur_ms")${RESET}"
fi

# diff stats (session lines added/removed) in muted tones
diffseg=""
{ [ "$add" -gt 0 ] || [ "$del" -gt 0 ]; } && diffseg="${DIFF_ADD}+${add}${RESET} ${DIFF_DEL}-${del}${RESET}"

# --- compose the three lines ---------------------------------------------
# line 1:  session name · ⏱ dur · +add -del  — when the session name is invalid
#          or absent, a random nonsensical placeholder title stands in (italic)
sname=$(printf '%s' "$session" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
# leading hashtag glyph marks the session name, with the duration alongside it
SESSION_ICON=$(printf '\357\212\222')  # nf-fa-hashtag (U+F292) via UTF-8 bytes
if [ -n "$sname" ] && [ "$sname" != "null" ]; then
  line1="${SESSION}${SESSION_ICON} ${sname}${RESET}"
else
  # nonsensical-but-appropriate stand-ins, wry/self-aware & mock-epic in flavour
  placeholders=(
    "Untitled Shenanigans"
    "Mystery Session"
    "The Nameless Endeavor"
    "A Series of Keystrokes"
    "Definitely Doing Things"
    "Some Assembly Required"
    "Adventures in Terminal"
    "Work in Progress-ish"
    "The Unlabeled Expedition"
    "Session Under Construction"
    "Anonymous Tinkering"
    "A Wild Session Appears"
    "Chaos, Neatly Arranged"
    "Placeholder McPlaceface"
    "Just Vibing in the Shell"
    "Probably Fine"
    "Winging It Professionally"
    "Overthinking Something Small"
    "Ctrl+Z Standing By"
    "Mostly Intentional"
    "Aggressively Average Progress"
    "Load-Bearing Confidence"
    "This Is Going Great, Actually"
    "The Quest for a Working Build"
    "Saga of the Unsaved Buffer"
    "Chronicles of the Blinking Cursor"
    "The Long March to Green Tests"
    "Odyssey of a Thousand Tabs"
    "The Reckoning of the Merge Conflict"
    "Ballad of the Forgotten Semicolon"
  )
  ph="${placeholders[RANDOM % ${#placeholders[@]}]}"
  line1="${SESSION}${SESSION_ICON} ${ITALIC}${ph}${RESET}"
fi
[ -n "$durseg" ]  && line1=$(join "$line1" "$durseg")
[ -n "$diffseg" ] && line1=$(join "$line1" "$diffseg")

# line 2: model · effort · ctx% · 5h
line2="$modelseg"
[ -n "$ctxseg" ] && line2=$(join "$line2" "$ctxseg")
[ -n "$h5seg" ]  && line2=$(join "$line2" "$h5seg")

# line 3: dir · branch
line3=""
[ -n "$dirseg" ]    && line3=$(join "$line3" "$dirseg")
[ -n "$branchseg" ] && line3=$(join "$line3" "$branchseg")

# each line self-suppresses when empty
[ -n "$line1" ] && printf '%b\n' "$line1"
[ -n "$line2" ] && printf '%b\n' "$line2"
[ -n "$line3" ] && printf '%b\n' "$line3"

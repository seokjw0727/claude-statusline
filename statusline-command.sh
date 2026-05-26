#!/usr/bin/env bash
# Claude Code status line — minimal Unicode style (2-line layout)
# Line 1: ◆ model (effort)  │  ▶ dir  │  ■ ctx usage
# Line 2: Claude 5h · 7d     │  Codex 5h · 7d

if ! command -v jq >/dev/null 2>&1; then
  printf '\033[31m■\033[0m \033[37m[jq missing — install: https://jqlang.org]\033[0m\n'
  exit 0
fi

input=$(cat)

model=$(echo "$input"      | jq -r '.model.display_name // empty' | sed 's/ (.*//')
cwd=$(echo "$input"        | jq -r '.cwd // empty')
ctx_size=$(echo "$input"   | jq -r '.context_window.context_window_size // empty')
remaining=$(echo "$input"  | jq -r '.context_window.remaining_percentage // empty')
rl_5h=$(echo "$input"     | jq -r '.rate_limits.five_hour.used_percentage  // empty')
rl_7d=$(echo "$input"     | jq -r '.rate_limits.seven_day.used_percentage   // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

# ── context bar helper (variable width) ─────────────────────────
# Shows used percentage as filled blocks, e.g. ██░░░░░░░░
# Usage: ctx_bar <pct> [width=10]
ctx_bar() {
  local pct="${1:-0}"
  local width="${2:-10}"
  local int_pct
  int_pct=$(printf '%.0f' "$pct" 2>/dev/null || echo 0)
  local filled=$(( (int_pct * width + 50) / 100 ))
  (( filled > width )) && filled=$width
  (( filled < 0 ))     && filled=0
  local empty=$(( width - filled ))
  local bar=""
  for (( i=0; i<filled; i++ )); do bar="${bar}█"; done
  for (( i=0; i<empty;  i++ )); do bar="${bar}░"; done
  echo "$bar"
}

# ── ANSI colour helpers ─────────────────────────────────────────
SEP="\033[2m│\033[0m"      # dimmed vertical bar
DIM="\033[2m"
RST="\033[0m"
ACC="\033[38;5;173m"       # Claude brand orange (#D7875F ≈ #D97757)
COD="\033[38;5;117m"       # Codex label colour (light blue)

# colour_pct <int_pct> → emits the ANSI colour code for that usage level
colour_pct() {
  local p="$1"
  if   (( p >= 99 )); then printf '\033[31m'          # red
  elif (( p >= 83 )); then printf '\033[38;5;208m'     # orange
  elif (( p >= 66 )); then printf '\033[33m'           # yellow
  else                     printf '\033[37m'           # white
  fi
}

# rl_seg <label> <raw_pct> → "label <bar> pct%" coloured by usage (10-wide bar)
rl_seg() {
  local label="$1" raw="$2"
  local p; p=$(printf '%.0f' "$raw" 2>/dev/null || echo 0)
  local col; col=$(colour_pct "$p")
  local bar; bar=$(ctx_bar "$p")
  echo "${col}${label}${RST} ${bar} ${col}${p}%${RST}"
}

# join_segs <seg...> → segments joined with "  │  "
join_segs() {
  local out="" seg
  for seg in "$@"; do
    if [ -z "$out" ]; then out="$seg"; else out="${out}  ${SEP}  ${seg}"; fi
  done
  printf '%s' "$out"
}

# ── Line 1: model · effort · directory · context ────────────────
line1=()

# Model + effort, e.g.  ◆ Opus 4.6 ( Medium ◐ )
if [ -n "$model" ]; then
  seg="${ACC}◆${RST}  \033[37m${model}\033[0m"
  if [ -n "$effort" ]; then
    case "$effort" in
      low)    sym="○"; effort_label="Low"    ;;
      medium) sym="◐"; effort_label="Medium" ;;
      high)   sym="◉"; effort_label="High"   ;;
      xhigh)  sym="●"; effort_label="XHigh"  ;;
      *)      sym="◈"; effort_label="Max"    ;;
    esac
    seg="${seg} ${DIM}( ${effort_label} ${sym} )${RST}"
  fi
  line1+=("$seg")
fi

# Working directory (last two path components)
if [ -n "$cwd" ]; then
  short_cwd=$(echo "$cwd" | sed 's|\\|/|g' | awk -F'/' '{if(NF>2) print $(NF-1)"/"$NF; else print $0}')
  line1+=("\033[38;5;117m▶\033[0m  \033[37m${short_cwd}\033[0m")
fi

# Context usage (10-wide bar, plain white)
if [ -n "$remaining" ]; then
  used_int=$(printf '%.0f' "$remaining" 2>/dev/null || echo 0)
  used_int=$(( 100 - used_int ))
  bar=$(ctx_bar "$used_int")
  line1+=("\033[37m■\033[0m  \033[37mctx\033[0m ${bar} \033[37m${used_int}%\033[0m")
fi

# ── Line 2: Claude / Codex rate limits ──────────────────────────
# Claude group (5h · 7d)
claude_inner=""
if [ -n "$rl_5h" ]; then
  claude_inner="$(rl_seg 5h "$rl_5h")"
fi
if [ -n "$rl_7d" ]; then
  s="$(rl_seg 7d "$rl_7d")"
  if [ -n "$claude_inner" ]; then
    claude_inner="${claude_inner}  ${DIM}·${RST}  ${s}"
  else
    claude_inner="$s"
  fi
fi

# Codex group (5h · 7d) — parsed from ~/.codex latest rollout
codex_inner=""
if command -v python >/dev/null 2>&1; then
  cx_raw=$(python "$HOME/.claude/codex-limits.py" 2>/dev/null)
  if [ -n "$cx_raw" ]; then
    cx_5h=${cx_raw%%|*}
    cx_7d=${cx_raw##*|}
    if [ -n "$cx_5h" ]; then
      codex_inner="$(rl_seg 5h "$cx_5h")"
    fi
    if [ -n "$cx_7d" ]; then
      s="$(rl_seg 7d "$cx_7d")"
      if [ -n "$codex_inner" ]; then
        codex_inner="${codex_inner}  ${DIM}·${RST}  ${s}"
      else
        codex_inner="$s"
      fi
    fi
  fi
fi

line2=()
[ -n "$claude_inner" ] && line2+=("${ACC}Claude${RST} ${claude_inner}")
[ -n "$codex_inner" ]  && line2+=("${COD}Codex${RST} ${codex_inner}")

# ── Emit ────────────────────────────────────────────────────────
out1=$(join_segs "${line1[@]}")
out2=$(join_segs "${line2[@]}")

printf "%b\n" "$out1"
[ -n "$out2" ] && printf "%b\n" "$out2"

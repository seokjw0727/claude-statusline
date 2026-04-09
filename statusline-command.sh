#!/usr/bin/env bash
# Claude Code status line — minimal Unicode style

export PATH="/c/Users/seokj/AppData/Local/Microsoft/WinGet/Packages/jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe:$PATH"

input=$(cat)

model=$(echo "$input"      | jq -r '.model.display_name // empty' | sed 's/ (.*//')
cwd=$(echo "$input"        | jq -r '.cwd // empty')
ctx_size=$(echo "$input"   | jq -r '.context_window.context_window_size // empty')
remaining=$(echo "$input"  | jq -r '.context_window.remaining_percentage // empty')
rl_5h=$(echo "$input"     | jq -r '.rate_limits.five_hour.used_percentage  // empty')
# effortLevel is not in statusline JSON — read from settings.json
effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)

# Format context window size as human-readable label (e.g. 200000 → "200K", 1000000 → "1M")
fmt_ctx_size() {
  local n="$1"
  if [ -z "$n" ] || [ "$n" = "null" ]; then echo ""; return; fi
  local int_n
  int_n=$(printf '%.0f' "$n" 2>/dev/null || echo 0)
  if   (( int_n >= 1000000 )); then printf '%sM' "$(echo "scale=0; $int_n / 1000000" | bc)"
  elif (( int_n >= 1000 ));    then printf '%sK' "$(echo "scale=0; $int_n / 1000"    | bc)"
  else echo "$int_n"
  fi
}

# ── context bar helper (10-char wide) ──────────────────────────
# Shows used context as filled blocks, e.g. ██░░░░░░░░
ctx_bar() {
  local pct="${1:-0}"
  # Round float to int using printf, then compute bar via pure bash
  local int_pct
  int_pct=$(printf '%.0f' "$pct" 2>/dev/null || echo 0)
  local filled=$(( (int_pct + 5) / 10 ))
  (( filled > 10 )) && filled=10
  (( filled < 0 ))  && filled=0
  local empty=$(( 10 - filled ))
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

# ── Build segments ──────────────────────────────────────────────
parts=()

# Model + effort in one segment
# e.g.  ◆ Opus 4.6 (● High)
if [ -n "$model" ]; then
  seg="${ACC}◆${RST}  \033[37m${model}\033[0m"
  if [ -n "$effort" ]; then
    case "$effort" in
      high)   sym="●"; effort_label="High"   ;;
      medium) sym="◉"; effort_label="Medium" ;;
      low)    sym="○"; effort_label="Low"    ;;
      *)      sym="▪"; effort_label="$effort" ;;
    esac
    seg="${seg} ${DIM}( ${effort_label} ${sym} )${RST}"
  fi
  parts+=("$seg")
fi

# Working directory (show only last two path components)
if [ -n "$cwd" ]; then
  short_cwd=$(echo "$cwd" | sed 's|\\|/|g' | awk -F'/' '{if(NF>2) print $(NF-1)"/"$NF; else print $0}')
  parts+=("\033[38;5;117m▶\033[0m  \033[37m${short_cwd}\033[0m")
fi

# colour_pct <int_pct> → emits the ANSI colour code for that usage level
colour_pct() {
  local p="$1"
  if   (( p >= 90 )); then printf '\033[31m'          # red
  elif (( p >= 75 )); then printf '\033[38;5;208m'     # orange
  elif (( p >= 50 )); then printf '\033[33m'           # yellow
  else                     printf '\033[37m'           # white
  fi
}

# Context + 5h usage — combined in one segment with ■ icon
usage_seg="\033[37m■\033[0m "
has_usage=false
if [ -n "$remaining" ]; then
  used_int=$(printf '%.0f' "$remaining" 2>/dev/null || echo 0)
  used_int=$(( 100 - used_int ))
  bar=$(ctx_bar "$used_int")
  usage_seg="${usage_seg} \033[37mctx\033[0m ${bar} \033[37m${used_int}%\033[0m"
  has_usage=true
fi
if [ -n "$rl_5h" ]; then
  p5=$(printf '%.0f' "$rl_5h" 2>/dev/null || echo 0)
  col=$(colour_pct "$p5")
  bar_5h=$(ctx_bar "$p5")
  if [ "$has_usage" = true ]; then
    usage_seg="${usage_seg}  ${DIM}·${RST}  "
  fi
  usage_seg="${usage_seg}${col}5h${RST} ${bar_5h} ${col}${p5}%${RST}"
  has_usage=true
fi
if [ "$has_usage" = true ]; then
  parts+=("$usage_seg")
fi

# ── Join with separator ─────────────────────────────────────────
out=""
for seg in "${parts[@]}"; do
  if [ -z "$out" ]; then
    out="$seg"
  else
    out="${out}  ${SEP}  ${seg}"
  fi
done

printf "%b\n" "$out"

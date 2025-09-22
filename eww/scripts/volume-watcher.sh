#!/usr/bin/env bash
set -euo pipefail
update() {
  local v pct muted
  v="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print $2}')" || v="0"
  [[ -z "$v" ]] && v="0"
  pct="$(awk -v x="$v" 'BEGIN{printf "%d\n", x*100}')"
  if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED; then muted=true; else muted=false; fi
  eww update volume="$pct"
  eww update is_muted="$muted"
}
update
pactl subscribe | grep --line-buffered "sink" | while read -r _; do update; done


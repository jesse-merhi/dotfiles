#!/usr/bin/env bash
set -euo pipefail
while :; do
  eww update wifi_menu_json="$(~/.config/eww/scripts/nm-list-json.sh)"
  sleep 15
done


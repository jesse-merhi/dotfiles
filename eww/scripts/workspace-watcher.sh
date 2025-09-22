#!/usr/bin/env bash
set -euo pipefail

# Initial update
hyprctl activeworkspace -j | jq -r '.id' | xargs -I{} eww update cwwks={}

# Listen for events
socat - "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    if [[ ${line:0:9} == "workspace" ]]; then
        ws_id=$(echo "$line" | sed -n 's/>>\(.*\)/\1/p')
        eww update cwwks="$ws_id"
    fi
done

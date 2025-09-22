#!/usr/bin/env bash
# connect-wifi.sh
# Usage: connect-wifi.sh --ssid "MyWifi" [--password "supersecret"] [--timeout 25]

set -u  # keep "nounset", but NOT `-e` (we want to catch failures ourselves)

EWW_BIN="${EWW_BIN:-eww}"
EWW_CFG="${EWW_CFG:-$HOME/.config/eww}"
SSID=""
PASSWORD=""
TIMEOUT=20

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssid)      SSID="${2-}"; shift 2 ;;
    --password)  PASSWORD="${2-}"; shift 2 ;;
    --timeout)   TIMEOUT="${2-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$SSID" ]]; then
  echo "connect-wifi.sh: --ssid is required" >&2
  exit 2
fi

eww_update() { "$EWW_BIN" --config "$EWW_CFG" update "$@"; }

# Always clear state when exiting
cleanup() {
  if [[ -n "${FAIL_MSG:-}" ]]; then
    eww_update "wifi_connecting=$FAIL_MSG"
    sleep 2
  fi
  eww_update "wifi_connecting="
}
trap cleanup EXIT

# Ensure Wi-Fi is on
nmcli radio wifi on || true

# Show "connecting"
eww_update "wifi_connecting=Connecting to $SSID…"

# Run nmcli with timeout, but don't auto-exit on failure
if [[ -n "$PASSWORD" ]]; then
  timeout "$TIMEOUT" nmcli -w "$TIMEOUT" dev wifi connect "$SSID" password "$PASSWORD"
else
  timeout "$TIMEOUT" nmcli -w "$TIMEOUT" dev wifi connect "$SSID"
fi
nm_status=$?

# Check if connected
current="$(nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1=="yes"{print $2; exit}')"

if [[ $nm_status -eq 0 && "$current" == "$SSID" ]]; then
  # Success — clear message and close menu
  FAIL_MSG=""
  eww_update "wifi_connecting="
  "$EWW_BIN" --config "$EWW_CFG" close wifi_menu || true
  eww_update "wifi_open=false"
  exit 0
else
  # Failure — set FAIL_MSG so trap shows error
  FAIL_MSG="❌ Failed to connect to $SSID"
  exit 1
fi


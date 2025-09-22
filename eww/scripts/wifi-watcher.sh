#!/usr/bin/env bash
set -euo pipefail

# Requires: nmcli, jq, awk
radio_state="$(nmcli radio wifi | tr '[:upper:]' '[:lower:]')"             # enabled|disabled
active_ssid="$(nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1=="yes"{print $2; exit}')"
active_sig="$(nmcli -t -f ACTIVE,SIGNAL dev wifi | awk -F: '$1=="yes"{print $2; exit}')" || true
: "${active_sig:=0}"

# All saved Wi-Fi connections (aka "known" SSIDs)
known_json="$(
  nmcli -t -f NAME,TYPE connection show \
  | awk -F: '$2=="802-11-wireless"{print $1}' \
  | sort -u \
  | jq -R . | jq -s .
)"

# Scan, turn into JSON lines, then dedupe per SSID by strongest signal
scan_json="$(
  nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE dev wifi \
  | awk -F: '{
      ssid=$1; sig=$2; sec=$3; inuse=$4;
      gsub(/"/,"\\\"",ssid);
      if (ssid=="") ssid="";
      if (!(ssid in best) || (sig+0) > (sbest[ssid]+0)) {
        best[ssid]=sprintf("{\"ssid\":\"%s\",\"signal\":%d,\"security\":\"%s\",\"in_use\":%s}",
                           ssid, (sig==""?0:sig)+0, sec, (inuse=="*"?"true":"false"));
        sbest[ssid]=sig;
      }
    }
    END{
      first=1; printf("[");
      for (k in best) { if(!first) printf(","); first=0; printf("%s", best[k]); }
      print "]";
    }'
)"

# Partition into known / unknown and add counts

jq -n \
  --arg radio   "$radio_state" \
  --arg ssid    "$active_ssid" \
  --argjson list "$scan_json" \
  --argjson known "$known_json" '
  def is_known($k; $s): any($k[]; . == $s);

  {
    radio: $radio,
    ssid:  $ssid,
    strength: ( ($list[] | select(.ssid==$ssid) | .signal) // 0 ),
    known:   ( [ $list[] | select((.ssid|length)>0 and is_known($known; .ssid)) ] | sort_by(-.signal) ),
    unknown: ( [ $list[] | select((.ssid|length)>0 and (is_known($known; .ssid) | not)) ] | sort_by(-.signal) )
  }
  | .known_count   = (.known   | length)
  | .unknown_count = (.unknown | length)
'


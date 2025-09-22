#!/usr/bin/env bash
set -euo pipefail

nmcli -t -f ssid,signal,security dev wifi \
| awk -F: 'BEGIN{print "["} 
  !/^:/{ 
    ssid=$1; sig=$2; sec=$3; 
    # First, escape backslashes
    gsub(/\\/, "\\\\", ssid);
    # Then, escape double quotes
    gsub(/"/, "\\\"", ssid);
    if(NR>1) printf(","); 
    printf("{\"ssid\":\"%s\",\"signal\":\"%s\",\"security\":\"%s\"}", ssid, sig, sec) 
  } 
  END{print "]"}'

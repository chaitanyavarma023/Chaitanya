#!/bin/sh

input_ssid="$1"
binding_ssid="`uci -q get addon.wianchor.bindingSsid`"

[ -z "$input_ssid" -o -z "$binding_ssid" ] && exit 1

for _ssid in $(echo $binding_ssid | sed 's/,/ /g'); do
  if [ "$input_ssid" == "$_ssid" ]; then
    exit 0
  fi
done

exit 1

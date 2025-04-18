#!/bin/sh

wianchor_status="`uci -q get addon.wianchor.enabled`"

[ "$wianchor_status" == "1" ] && {
  uci_rssiThreshold=`uci -q get addon.wianchor.rssiThreshold`
  wianchor_proximityUrl="`uci -q get addon.wianchor.proximityUrl`"
}

debug() {
  [ -n "$DEBUG" ] && echo "$1"
}

error() {
  echo "$@" >&2
}

prc_url() {
  read_line=$@

  phytype="$(echo $read_line | grep -oE '\"type\":\W\"\w+' | sed 's:.*\: \"::')"

  [ -z "$phytype" ] && error "Device type missing" && return

  if [ "$phytype" == "wifi" ]; then
    phyradio="$(echo $read_line | grep -oE '\"dev_name\":\W\"\w+' | sed 's:.*\: \"::')"
    [ -n "$wianchor_proximityUrl" ] && {
      prcurl="$wianchor_proximityUrl" 
    } || {
      prcurl="$(uci get wireless.${phyradio}.prc_remote_url 2>/dev/null)"
    }
    [ -z "$prcurl" ] && {
      # rtk uci and phy name does not match
      [ "$(uci get wireless.radio0 2>/dev/null)" == "wifi-device" ] && radio_prefix="radio"
      phyradio=${phyradio//${phyradio%?}/$radio_prefix}
      prcurl="$(uci get wireless.${phyradio}.prc_remote_url 2>/dev/null)"
    }
  fi
  echo $prcurl
}

DIRECTORY=/var/run/prc_files
FILE_IN=/var/run/prc_files/prc_file_input
LOCK_FILE=/var/run/prc_files/prc_lock_file

if ! [ -d "$DIRECTORY" ];
then
  debug "Folder does not exist!"
  exit
fi

flock -x $LOCK_FILE rm -f "${FILE_IN}"*

while true; do
  sleep 10
  if [ -f "$FILE_IN" ]; then
    flock -x $LOCK_FILE mv -f "${FILE_IN}" "${FILE_IN}.1"
  fi

  try=
  for idx in 3 2 1; do
    [ -f "${FILE_IN}.$idx" ] || { try=$idx; continue; }

    while read -r line; do
      url="$(prc_url ${line})"
      client_rssi=0
      is_send_data=true
      status=""
      errcode=""

      if [ -n "$url" ]; then
        [ -n "$uci_rssiThreshold" ] && {
          client_rssi=`echo $line | jsonfilter -e "@.rssi" | awk '{print $1}'`
          [ $client_rssi -lt $uci_rssiThreshold ] && {
            is_send_data=false
          }
        }

        debug "uci_rssiThreshold:$uci_rssiThreshold, client_rssi:$client_rssi, is_send_data:$is_send_data"
        if [ $is_send_data == true ]; then
          debug "Sending $line. - $url -"
          status=$(curl -k -s -o /dev/null -XPOST -H 'Content-Type:application/json' -H 'Accept: application/json' --connect-timeout 5 -m 5 --data-binary "${line}" -w "%{http_code}" $url)

          errcode=$(echo "$?")
          debug "errcode = $errcode"
        fi

        if [ "$status" == "200" -o "$errcode" == "52" ]; then
          debug "$line send complete."
        else
          if [ "$status" == "429" -o "$errcode" == "56" ]; then
            [ -n "$idx" ] && echo "$line" >> ${FILE_IN}.$try
            sleep 5
          else
            debug "$line send failed."
          fi
        fi
      else
        debug "$line shouldn't be sent."
      fi
    done < "${FILE_IN}.$idx"
    try=$idx
    rm -f "${FILE_IN}.$idx"
  done
done

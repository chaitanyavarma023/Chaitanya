#!/bin/sh

. /lib/functions.sh

SCRIPT=$0
LOGFILE="/tmp/log/send_clientinfo_period.log"
LOGGING=0 #default is off
WIRELESSJSON="/tmp/wifi_clients.json"
period="1" #minutes

_log() {
    if [ ${LOGGING} -eq 1 ]; then
        local ts=$(date)
        echo "$ts $@" >> ${LOGFILE}
    fi
}

_add_cron_script() {
    (crontab -l ; echo "$1") | sort | uniq | crontab -
}

_rm_cron_script() {
    crontab  -l | grep -v "$1" |  sort | uniq | crontab -
}

add_cron_entries() {
  cmd="*/"${period}" * * * * "${SCRIPT}" start"
  _log "[Add] add cron rule: ${cmd}"
  _add_cron_script "$cmd"
}

start_send_info() {
  wi_anchor_enabled="`uci -q get addon.wianchor.enabled`"
  if [ "$wi_anchor_enabled" == "1" ]; then
    url="`uci -q get addon.wianchor.clientDataUrl`"

    . /sbin/generate_wifi_client_info.sh
    sleep 3

    _log "[Send] sending ${WIRELESSJSON} to : ${url}..."

    [ -f "$WIRELESSJSON" ] && {
      curl -k --connect-timeout 5 -m 5 -X POST -H "Content-Type: application/json" -d @$WIRELESSJSON ${url}
      _log "[Send] Done"
      exit 0
    }

    _log "[Send] ${WIRELESSJSON} does not exist."
  else
    _log "[Send] Smart Indoor Location Solution function is disabled."
  fi
}

clean_cron_entries() {
  _log "[Exit] clear cron rule: send wifi clientinfo"
  _rm_cron_script ${SCRIPT}
}

###############################################################################
# MAIN
###############################################################################

sleep 3

case "$1" in
  boot) 
    add_cron_entries
  ;;
  start) 
    start_send_info
  ;;
  stop) 
    clean_cron_entries
  ;;
esac

exit 0

#!/bin/sh

. /lib/functions.sh

#===========crontab part===========
SCRIPT=$0
LOGFILE="/tmp/log/logrotate_cron.log"
LOGGING=0 #default is off

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
	#every minute
  cmd="* * * * * "${SCRIPT}" start"
  _log "[Add] add cron rule: ${cmd}"
  _add_cron_script "$cmd"
}

clean_cron_entries() {
  _log "[Exit] clear cron rule: channel balance"
  _rm_cron_script ${SCRIPT}
}

start_logrotate(){
	logrotate -v /etc/logrotate.d/syslog -s /var/run/logrotate.status
}

stop_logrotate() {
    pid="$(ps ww | grep logrotate_cron.sh | grep -v grep | awk '{print $1}')"
    [ -n "$pid" ] && kill -9 $pid
}



case "$1" in
  boot)
    add_cron_entries
  ;;
  start)
    start_logrotate
  ;;
  stop)
    clean_cron_entries
    stop_logrotate
  ;;
esac

exit 0
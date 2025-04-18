#!/bin/sh
. /lib/functions.sh

wmi_fail1="ce desc not available for wmi command"
wmi_fail2="attach ack fail"
fail_limit="5"

#===========crontab part===========
SCRIPT=$0

LOGFILE="/tmp/log/wmi_monitor.log"
LOGGING=0 #default is off
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

#================================

start_wmi_check() {

	wmi_flag1=$(logread -e "${wmi_fail1}" | wc -l)
	wmi_flag2=$(logread -e "${wmi_fail2}" | wc -l)

	if [ ${wmi_flag1} -ge ${fail_limit} ] || [ ${wmi_flag2} -ge ${fail_limit} ]; then
		#kernel 4.4.6 doesn't support wifi FW restart
		#all we can do is reboot device to resrat wifi FW
		reboot
	fi
}

clean_cron_entries() {
  _log "[Exit] clear cron rule: wmi monitor"
  _rm_cron_script ${SCRIPT}
}

case "$1" in
  boot)
    add_cron_entries
  ;;
  start)
    start_wmi_check
  ;;
  stop)
    clean_cron_entries
  ;;
esac

exit 0

#!/bin/sh
. /lib/functions.sh

SCRIPT=$0
need_restart=0
period=2

_wait_cac() {
	local config="$1"
	local disabled ifname
	config_get disabled ${config} disabled
	config_get ifname ${config} ifname

	[ "${ifname:0:4}" != "wlan" ] && continue

	if [ "${disabled}" = "0" ]; then
		local ret=$(hostapd_cli -i $ifname status | grep state)
		local state=${ret/state=/}
		if [ "$state" = "DFS" ]; then
			logger "wifi_monitor: DFS state, wait for CAC..."
			exit 0
		else
			return
		fi
	fi
}

_check_channel() {
	local ret=$(iwinfo $1 info | grep "Channel: unknown")
	if [ -n "$ret" ]; then
		logger "wifi_monitor: $1 channel is unknown"
		need_restart=1
	fi
}

_check_interface_exist() {
	local ret=$(iwinfo | grep "$1")
	if [ -z "$ret" ]; then
		logger "wifi_monitor: $1 is enabled but no interface is found"
		need_restart=1
	fi
}

_check_wlan() {
	local config="$1"
	local rf0_disabled="$2"
	local rf1_disabled="$3"
	local disabled ifname device rfid
	config_get disabled ${config} disabled
	config_get ifname ${config} ifname
	config_get device ${config} device

	[ "${ifname:0:4}" != "wlan" ] && continue
	rfid=${device: -1}

	[ "$rfid" = "0" -a "$rf0_disabled" = "1" ] && continue
	[ "$rfid" = "1" -a "$rf1_disabled" = "1" ] && continue

	if [ "${disabled}" = "0" ]; then
		_check_interface_exist $ifname
		_check_channel $ifname
	fi
}

check_wlan() {
	rf0_disabled=$(uci get wireless.radio0.disabled)
	rf1_disabled=$(uci get wireless.radio1.disabled)
	config_load wireless
	[ "$rf0_disabled" = "0" ] && config_foreach _wait_cac wifi-iface
	config_foreach _check_wlan wifi-iface ${rf0_disabled} ${rf1_disabled}
}

wait_network_ready() {
	if [ -f "/tmp/wifi_flag" ]; then
		rm /tmp/wifi_flag
		exit 0
	fi
}

detect_wifi() {
	wait_network_ready
	check_wlan

	if [ "$need_restart" = "1" ]; then
		logger "wifi_monitor: restart hostapd"
		pid="$(ps ww | grep hostapd | grep -v grep | awk '{print $1}')"
		[ -n "$pid" ] && kill -9 $pid
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
	_add_cron_script "$cmd"
}

clean_cron_entries() {
  _rm_cron_script ${SCRIPT}
}

case "$1" in
	boot)
		add_cron_entries
		;;
	start)
		detect_wifi
		;;
	stop)
		clean_cron_entries
		;;
esac

exit 0

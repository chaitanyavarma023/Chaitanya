#!/bin/sh
UAMD="/ramfs/uamd"
proxy_server_list="/tmp/status/proxy_server_list"
proxy_server_dir="/tmp/status/proxy"
PID_DIR="/var/run/"
FILE="${UAMD}/cfg.proxy"
WIZARD_IFNAME="wlan0-1 wlan0-2 wlan1-1 wlan1-2"
#LAN=br-lan

. /lib/functions/network.sh

stop_proxy() {
    local interface=$1

    logger -s "Stop UAMD: ${interface}"
    pids=$(ps | grep ${UAMD}/cfg.proxy.${interface}$ | grep -v grep)
    kill -9 ${pids} >/dev/null 2>&1
}

start_proxy()
{
    local ifname=$1
    local vif=$2
    local type=$3
    local vap_id w_id s_id ssl_id port ssl_port
    mkdir -p /tmp/status
    if [ ! -f ${proxy_server_list} ]; then
	touch ${proxy_server_list}
	chmod 666 ${proxy_server_list}
    fi

    local wan_dev
    local lan_dev
    network_get_physdev wan_dev "wan"
    network_get_physdev lan_dev "lan"
    [ -z "${wan_dev}" ] && wan_dev="br-wan"
    [ -z "${lan_dev}" ] && lan_dev="br-lan"

    [ -z "$(ifconfig ${wan_dev} 2>/dev/null)" ] && wan_dev="eth0"
    WAN_IP=$(ifconfig ${wan_dev} | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
    #if [ -z "${WAN_IP}" ] && [ "${type}" = "WIZARD" ]; then
    if [ "${type}" = "WIZARD" ]; then
        WAN_IP=$(ifconfig ${lan_dev} | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
    fi

    logger -s "Start UAMD: ${interface}"
    w_id=$(( ${ifname:4:1} + 1 ))
    if [ -z "$(echo ${ifname} | grep '-')" ]; then
        vap_id=0
    else
        vap_id=${ifname#*-}
    fi
    s_id=$(printf %02d ${vap_id})
    ssl_id=$(( ${w_id} + 7 ))
    port="8${w_id}${s_id}"
    ssl_port="8${ssl_id}${s_id}"
    ${UAMD}/rep_uamd_tmpl ${FILE} ${ifname} ${port} ${WAN_IP} ${vif}
    ${UAMD}/proxy ${FILE}.${ifname}
}

if_file=$1
interface=$2
vif=$3

if [ -n "${if_file}" ]; then
    if [ "$(uci -q get acn.wizard.ez_setup)" != "0" ]; then
        for interface in $WIZARD_IFNAME
        do
            start_proxy ${interface} "" "WIZARD"
            hostapd_cli -i ${interface} -a /ramfs/bin/handle_wizard.sh -B
        done
    fi

    while read item;
    do
        interface=$(echo $item | cut -d "=" -f1)
        vif=$(echo $item | cut -d "=" -f2)
        cnt=0
        while [ $cnt -lt 30 ];
        do
            ip link set ${interface} group 1
            echo 1 > /sys/class/net/${interface}/brport/macauth
            ret=$(ip link | grep ${interface}: | grep "group 1")
            [ -n "${ret}" ] && break
            sleep 2
            cnt=$((cnt+1))
        done
        start_proxy ${interface} ${vif}
        (
            flock -n 200 || exit
            /ramfs/bin/auth_customize_page.sh ${interface} ${vif} >/dev/null 2>/dev/null
        ) 200>/var/lock/qcawifi.flock
    done < $if_file
elif [ -n "${interface}" ] && [ -n "${vif}" ]; then
    stop_proxy $interface
    start_proxy ${interface} ${vif}
    (
        flock -n 200 || exit
        /ramfs/bin/auth_customize_page.sh ${interface} ${vif} >/dev/null 2>/dev/null
    ) 200>/var/lock/qcawifi.flock
fi

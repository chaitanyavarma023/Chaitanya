#!/bin/sh

if [ $2 == "AP-STA-DISCONNECTED" ];then
    mac=$3
    ip=$(arp -n | grep "${mac}" | awk '{print $2}' | sed 's/[()]//g')
    [ -n "${ip}" ] && ipset del open_ip $ip
fi


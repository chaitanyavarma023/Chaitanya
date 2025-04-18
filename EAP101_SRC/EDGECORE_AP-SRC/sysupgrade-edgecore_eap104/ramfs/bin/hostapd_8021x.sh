#!/bin/sh

if [ "$2" = "AP-STA-CONNECTED" ]; then
    mac_f1=$(echo "$3" | tr [a-z] [A-Z])
    mac_f2=$(echo "$3" | tr [a-z] [A-Z] | sed 's/:/-/g')
    interface=$1    
    id=${interface:3:1}
    file="/tmp/hostapd_data_${mac_f1}"
    calling_file="/tmp/radius_exec/${mac_f1}"

    hostapd_cli -p /var/run/hostapd-wifi${id} -i $interface sta $mac_f1 > $file
    uname=$(cat ${file} | grep dot1xAuthSessionUserName | cut -d "=" -f2)
    echo -e "user_name=${uname}">> ${calling_file} 
    rm -f ${file}
    /ramfs/bin/cipgwcli newmac "${mac_f2}" "600"
fi


#!/bin/sh

. /lib/functions.sh

get_vlan_ifname(){
	local config="$1"
	config_get disabled ${config} disabled
	[ "${disabled}" != "0" ] && continue
	config_get tun ${config} tun
	config_get split_tun ${config} split_tun
	if [ "${tun}" = "1" -a "${split_tun}" = "1" ]; then
		config_get split_sz ${config} split_sz
		config_get ifname ${config} ifname
		echo "$ifname" >> /tmp/walled_garden_if${split_sz}
	fi
}

set_8021x_ipset() {
    local config="$1"; shift
    local name="$1"; shift
    local act="$1"; shift
    local mac="$1"

    config_get ifname ${config} ifname

    if [ "${ifname}" = "${name}" ]; then
        config_get encryption ${config} encryption
        wpa=$(echo "${encryption}" | cut -c1-3)

        if [ "${wpa}" = "wpa" ]; then
            ipset ${act} 8021x_split_tunnel ${mac} > /dev/null 2>&1
        fi
        break
    fi
}

act=$1
logout_ip_tmp_file=/tmp/add_logout_ip
logout_ip_list_file=/tmp/logout_ip_list
walled_garden_tmp_file=/tmp/add_walled_garden
walled_garden_list_file=/tmp/walled_garden_list

if [ "${act}" = "login"  ]; then
    mac=$2
    cui=$3
    idle=$4

    bridge=$(arp -an | grep ${mac} -i | awk '{ print $NF }')
    iface=$(/etc/capwap/split_tun_action.script get_iface_by_mac ${mac})
    ipset add online_user ${mac} > /dev/null 2>&1
    brctl setmacage ${bridge} ${mac} ${idle}
    hostapd_cli -i ${iface} sta_uam_acct_start ${mac} ${cui}
    config_load wireless
    config_foreach set_8021x_ipset wifi-iface ${iface} "add" ${mac}
    logger "Split tunnel open user ${mac}"
elif [ "${act}" = "logout"  ]; then
    mac=$2
    kick=$3
    mac_list="0x$(echo $mac | sed 's/:/ 0x/g')"
    iface=$(/etc/capwap/split_tun_action.script get_iface_by_mac ${mac})

    config_load wireless
    config_foreach set_8021x_ipset wifi-iface ${iface} "del" ${mac}
    if [ -n "${iface}" ]; then
        hostapd_cli -i ${iface} sta_uam_acct_stop ${mac}
#workaround now, always deauth, modify controller split_tunnel.inc.sh for is_1x=1
#if [ ${kick} = "0" ]; then
            hostapd_cli -i ${iface} deauthenticate ${mac}
#        fi
    fi
    ipset del online_user ${mac} > /dev/null 2>&1
elif [ "${act}" = "logout_ip_list"  ]; then
	ipset flush logout_ip_list
	if [ -f $logout_ip_tmp_file ]; then
		rm -f $logout_ip_list_file
		
		while read line;
		do
			for ip in $(echo $line | sed 's/,/ /g')
			do
				echo "add logout_ip_list ${ip}" >> $logout_ip_list_file
			done
		done < ${logout_ip_tmp_file}
		ipset restore -f $logout_ip_list_file
		rm -f $logout_ip_tmp_file
	fi
elif [ "${act}" = "walled_garden"  ]; then
	ipset flush WALL_IF

	if [ -f $walled_garden_tmp_file ]; then
		config_load wireless
		config_foreach get_vlan_ifname wifi-iface
		rm -f $walled_garden_list_file
		while read line;
		do
			for item in $(echo $line | sed 's/+/ /g')
			do
				ip=$(echo $item | cut -d ',' -f1)
				vlan_id=$(echo $item | cut -d ',' -f2)
				if [ -f /tmp/walled_garden_if${vlan_id} ]; then
					while read wifi_name; do
						echo "add WALL_IF ${ip},${wifi_name}" >> $walled_garden_list_file
					done < /tmp/walled_garden_if${vlan_id}
				fi
			done
		done < ${walled_garden_tmp_file}
		ipset restore -f $walled_garden_list_file
		rm -f $walled_garden_tmp_file
		rm -f /tmp/walled_garden_if*
	fi
fi

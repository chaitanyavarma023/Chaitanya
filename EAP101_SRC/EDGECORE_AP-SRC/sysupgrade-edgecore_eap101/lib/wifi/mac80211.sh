#!/bin/sh

append DRIVERS "mac80211"

lookup_phy() {
	[ -n "$phy" ] && {
		[ -d /sys/class/ieee80211/$phy ] && return
	}

	local devpath
	config_get devpath "$device" path
	[ -n "$devpath" ] && {
		phy="$(iwinfo nl80211 phyname "path=$devpath")"
		[ -n "$phy" ] && return
	}

	local macaddr="$(config_get "$device" macaddr | tr 'A-Z' 'a-z')"
	[ -n "$macaddr" ] && {
		for _phy in /sys/class/ieee80211/*; do
			[ -e "$_phy" ] || continue

			[ "$macaddr" = "$(cat ${_phy}/macaddress)" ] || continue
			phy="${_phy##*/}"
			return
		done
	}
	phy=
	return
}

find_mac80211_phy() {
	local device="$1"

	config_get phy "$device" phy
	lookup_phy
	[ -n "$phy" -a -d "/sys/class/ieee80211/$phy" ] || {
		echo "PHY for wifi device $1 not found"
		return 1
	}
	config_set "$device" phy "$phy"

	config_get macaddr "$device" macaddr
	[ -z "$macaddr" ] && {
		config_set "$device" macaddr "$(cat /sys/class/ieee80211/${phy}/macaddress)"
	}

	return 0
}

check_mac80211_device() {
	config_get phy "$1" phy
	[ -z "$phy" ] && {
		find_mac80211_phy "$1" >/dev/null || return 0
		config_get phy "$1" phy
	}
	[ "$phy" = "$dev" ] && found=1
}


__get_band_defaults() {
	local phy="$1"

	( iw phy "$phy" info; echo ) | awk '
BEGIN {
        bands = ""
}

($1 == "Band" || $1 == "") && band {
        if (channel) {
		mode="NOHT"
		if (ht) mode="HT20"
		if (vht && band != "1:") mode="VHT80"
		if (he) mode="HE80"
		if (he && band == "1:") mode="HE20"
                sub("\\[", "", channel)
                sub("\\]", "", channel)
                bands = bands band channel ":" mode " "
        }
        band=""
}

$1 == "Band" {
        band = $2
        channel = ""
	vht = ""
	ht = ""
	he = ""
}

$0 ~ "Capabilities:" {
	ht=1
}

$0 ~ "VHT Capabilities" {
	vht=1
}

$0 ~ "HE Iftypes" {
	he=1
}

$1 == "*" && $3 == "MHz" && $0 !~ /disabled/ && band && !channel {
        channel = $4
}

END {
        print bands
}'
}

get_band_defaults() {
	local phy="$1"

	for c in $(__get_band_defaults "$phy"); do
		local band="${c%%:*}"
		c="${c#*:}"
		local chan="${c%%:*}"
		c="${c#*:}"
		local mode="${c%%:*}"

		case "$band" in
			1) band=2g;;
			2) band=5g;;
			3) band=60g;;
			4) band=6g;;
			*) band="";;
		esac

		[ -n "$band" ] || continue
		[ -n "$mode_band" -a "$band" = "6g" ] && return

		mode_band="$band"
		channel="$chan"
		htmode="$mode"
	done
}

detect_mac80211() {
	devidx=0
	config_load wireless
	while :; do
		config_get type "radio$devidx" type
		[ -n "$type" ] || break
		devidx=$(($devidx + 1))
	done

	for _dev in /sys/class/ieee80211/*; do
		[ -e "$_dev" ] || continue

		dev="${_dev##*/}"

		found=0
		config_foreach check_mac80211_device wifi-device
		[ "$found" -gt 0 ] && continue

		mode_band=""
		channel=""
		htmode=""
		ht_capab=""
		scanning=""

		get_band_defaults "$dev"

		path="$(iwinfo nl80211 path "$dev")"
		if [ -n "$path" ]; then
			dev_id="set wireless.radio${devidx}.path='$path'"
			if [ "$(cat /etc/board.json | jsonfilter -e "@.wifi['$path'].scanning")" == "true" ]; then
				scanning="set wireless.radio${devidx}.scanning=1"
			fi
		else
			dev_id="set wireless.radio${devidx}.macaddr=$(cat /sys/class/ieee80211/${dev}/macaddress)"
		fi

		if [ "$mode_band" = '5g' ]; then
			hwmode_band="axa"
			ssid_subs="5G"
		else
			hwmode_band="axg"
			ssid_subs="2.4G"
		fi
		uci -q batch <<-EOF
			set wireless.radio${devidx}=wifi-device
			set wireless.radio${devidx}.mode=ap
			set wireless.radio${devidx}.type=mac80211
			${dev_id}
			set wireless.radio${devidx}.channel=auto
			set wireless.radio${devidx}.hwmode=11${hwmode_band}
			set wireless.radio${devidx}.band=${mode_band}
			set wireless.radio${devidx}.htmode=$htmode
			set wireless.radio${devidx}.num_global_macaddr=8
			set wireless.radio${devidx}.beacon_int=100
			${scanning}
			set wireless.radio${devidx}.disabled=0

			set wireless.radio${devidx}_1=wifi-iface
			set wireless.radio${devidx}_1.device=radio${devidx}
			set wireless.radio${devidx}_1.ifname=wlan${devidx}
			set wireless.radio${devidx}_1.disabled=0
			set wireless.radio${devidx}_1.created=1
			set wireless.radio${devidx}_1.network=lan
			set wireless.radio${devidx}_1.mode=ap
			set wireless.radio${devidx}_1.ssid=Edgecore${ssid_subs}-1
			set wireless.radio${devidx}_1.encryption=none
			set wireless.radio${devidx}_1.maxassoc=127
			set wireless.radio${devidx}_1.wds=1
			set wireless.radio${devidx}_1.wmm=1
			set wireless.radio${devidx}_1.radius_mac_acl=0
			set wireless.radio${devidx}_1.macfilter_enable=0
			set wireless.radio${devidx}_1.max_inactivity=300
			set wireless.radio${devidx}_1.local_configurable=0
			set wireless.radio${devidx}_1.uapsd=1

			set wireless.radio${devidx}_2=wifi-iface
			set wireless.radio${devidx}_2.device=radio${devidx}
			set wireless.radio${devidx}_2.ifname=wlan${devidx}-1
			set wireless.radio${devidx}_2.disabled=0
			set wireless.radio${devidx}_2.created=1
			set wireless.radio${devidx}_2.network=lan
			set wireless.radio${devidx}_2.mode=ap
			set wireless.radio${devidx}_2.encryption='psk2+ccmp'
			set wireless.radio${devidx}_2.maxassoc=127
			set wireless.radio${devidx}_2.wds=1
			set wireless.radio${devidx}_2.wmm=1
			set wireless.radio${devidx}_2.radius_mac_acl=0
			set wireless.radio${devidx}_2.macfilter_enable=0
			set wireless.radio${devidx}_2.max_inactivity=300
			#set wireless.radio${devidx}_2.hidden=1
			set wireless.radio${devidx}_2.local_configurable=0
			set wireless.radio${devidx}_2.wpa_group_rekey=86400
			set wireless.radio${devidx}_2.wpa_strict_rekey=0
			set wireless.radio${devidx}_2.eap_reauth_period=0
			set wireless.radio${devidx}_2.uapsd=1

			set wireless.radio${devidx}_3=wifi-iface
			set wireless.radio${devidx}_3.device=radio${devidx}
			set wireless.radio${devidx}_3.ifname=wlan${devidx}-2
			set wireless.radio${devidx}_3.disabled=0
			set wireless.radio${devidx}_3.created=1
			set wireless.radio${devidx}_3.network=lan
			set wireless.radio${devidx}_3.mode=ap
			set wireless.radio${devidx}_3.encryption='psk2+ccmp'
			set wireless.radio${devidx}_3.maxassoc=127
			set wireless.radio${devidx}_3.wds=1
			set wireless.radio${devidx}_3.wmm=1
			set wireless.radio${devidx}_3.radius_mac_acl=0
			set wireless.radio${devidx}_3.macfilter_enable=0
			set wireless.radio${devidx}_3.max_inactivity=300
			set wireless.radio${devidx}_3.hidden=1
			set wireless.radio${devidx}_3.local_configurable=0
			set wireless.radio${devidx}_3.wpa_group_rekey=86400
			set wireless.radio${devidx}_3.wpa_strict_rekey=0
			set wireless.radio${devidx}_3.eap_reauth_period=0
			set wireless.radio${devidx}_3.uapsd=1

EOF
		uci -q commit wireless

		devidx=$(($devidx + 1))
	done

	config_foreach setup_aaa wifi-device
}

scan_mac80211() {
	local device="$1"
	local wds
	local adhoc sta ap monitor ap_monitor ap_smart_monitor mesh ap_lp_iot disabled

	[ ${device%[0-9]} = "wifi" ] && config_set "$device" phy "$device"

	local ifidx=0
	local radioidx=${device#wifi}

	config_get vifs "$device" vifs
	for vif in $vifs; do
		config_get_bool disabled "$vif" disabled 0
		[ $disabled = 0 ] || continue

		local vifname
		[ $ifidx -gt 0 ] && vifname="ath${radioidx}$ifidx" || vifname="ath${radioidx}"

		config_set "$vif" ifname $vifname

		config_get mode "$vif" mode
		case "$mode" in
			adhoc|sta|ap|monitor|wrap|ap_monitor|ap_smart_monitor|mesh|ap_lp_iot)
				append "$mode" "$vif"
			;;
			wds)
				config_get ssid "$vif" ssid
				[ -z "$ssid" ] && continue

				config_set "$vif" wds 1
				config_set "$vif" mode sta
				mode="sta"
				addr="$ssid"
				${addr:+append "$mode" "$vif"}
			;;
			*) echo "$device($vif): Invalid mode, ignored."; continue;;
		esac

		ifidx=$(($ifidx + 1))
	done

	case "${adhoc:+1}:${sta:+1}:${ap:+1}" in
		# valid mode combinations
		1::) wds="";;
		1::1);;
		:1:1)config_set "$device" nosbeacon 1;; # AP+STA, can't use beacon timers for STA
		:1:);;
		::1);;
		::);;
		*) echo "$device: Invalid mode combination in config"; return 1;;
	esac

	config_set "$device" vifs "${ap:+$ap }${ap_monitor:+$ap_monitor }${mesh:+$mesh }${ap_smart_monitor:+$ap_smart_monitor }${wrap:+$wrap }${sta:+$sta }${adhoc:+$adhoc }${wds:+$wds }${monitor:+$monitor}${ap_lp_iot:+$ap_lp_iot}"
}

setup_aaa()
{
	config_load wireless
	local device="$1"
	local ifidx=0
	local network=""
	local radioidx=${device#radio}
	config_get vifs $device vifs
	for vif in $vifs; do
		network=""
		config_get disabled $vif disabled 1
		config_get ifname $vif ifname

		[ $ifidx -gt 0 ] && vifname="wlan${radioidx}$ifidx" || vifname="wlan${radioidx}"

		if [ $disabled -eq 0 ]; then
			config_get cloud_aaa $vif cloud_aaa
			local macaddr="$(config_get "$device" macaddr)"

			if [ $cloud_aaa -eq 1 ]; then
				ip link set $ifname group 1
				/ramfs/bin/run_uamd.sh "" $ifname $vif >/dev/null 2>&1
				echo 1 > /sys/class/net/$ifname/brport/macauth

				config_get network $vif network
			else
				echo 0 > /sys/class/net/$ifname/brport/macauth
			fi
			# AAA and 802.1X
			config_get encryption $vif encryption
			config_get auth_server $vif auth_server
			config_get  $vif auth_port

			if [ "${cloud_aaa}" = "1" -a "${encryption}" = "ap-wpa2+ccmp" -a "${auth_server}" != "" -a "${auth_port}" != "" ]; then
				pid=$(ps | grep hostapd_cli | grep -w $vifname | grep hostapd_8021x | grep -v grep | awk '{print $1}')
				if [ "${pid}" = "" ]; then
					hostapd_cli -i $vifname -a /ramfs/bin/hostapd_8021x.sh -p /var/run/hostapd-$device -B
				fi
			else
				pid=$(ps | grep hostapd_cli | grep -w $vifname | grep hostapd_8021x | grep -v grep | awk '{print $1}')
				[ -n "$pid" ] && kill ${pid}
			fi

			if [ "${network:0:4}" = "vlan" ]; then
				local network_dev
				if [ -n "$(uci -q get network.bridge.type)" ]; then
					network_dev=$(uci -q get network.${network}.device)
				else
					network_dev=br-${network}
				fi
				if [ -z $(ps | grep udhcpc-${network_dev} | grep -v grep | awk -F' ' '{print $1}' | head -1) ]; then
					udhcpc -f -p /var/run/udhcpc-${network_dev}.pid -i ${network_dev} -s /ramfs/bin/dhcpc.sh >/dev/null 2>&1 &
				fi
			fi
		else
			pid=$(ps | grep hostapd_cli | grep -w $vifname | grep -v grep | awk '{print $1}')
			[ -n "$pid" ] && kill ${pid}
			continue
		fi
		ifidx=$(($ifidx + 1))
	done
}

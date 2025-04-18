#!/bin/sh
. /lib/functions.sh

. /lib/wifi/mac80211.sh

scan_wifi() {
	local cfgfile="$1"
	DEVICES=
	config_cb() {
		local type="$1"
		local section="$2"

		# section start
		case "$type" in
			wifi-device)
				append DEVICES "$section"
				config_set "$section" vifs ""
				config_set "$section" ht_capab ""
			;;
		esac

		# section end
		config_get TYPE "$CONFIG_SECTION" TYPE

		case "$TYPE" in
			wifi-iface)
				config_get device "$CONFIG_SECTION" device
				config_get vifs "$device" vifs

				append vifs "$CONFIG_SECTION"
				config_set "$device" vifs "$vifs"
				config_get vapnetwork "$CONFIG_SECTION" network

				if [ "$vapnetwork" = "hotspot" ]; then
					local vap_ifname_no="$(echo "$CONFIG_SECTION" | sed s/^wifi/ath/ | awk -F_ {'print $2'})"
					vap_ifname_no=$((vap_ifname_no-1))

					if [ "$vap_ifname_no" = "0" ]; then
						local vap_ifname="$(echo "$CONFIG_SECTION" | sed s/^wifi/ath/ | awk -F_ {'print $1'})"
					else
						local vap_ifname="$(echo "$CONFIG_SECTION" | sed s/^wifi/ath/ | awk -F_ {'print $1'})"${vap_ifname_no}
					fi

					local vap_number="$(echo "$CONFIG_SECTION" | awk -F_ {'print $2'})"
					local radio_number="$(echo "$CONFIG_SECTION" | awk -F_ {'print $1'} | sed 's/wifi//')"
					local idx=$((radio_number*8+vap_number-1))

					append WLAN_HOTSPOT "${idx}:${vap_ifname}"
				fi
			;;
		esac
	}
	config_load wireless
}

scan_wifi

config_load wireless

config_foreach scan_mac80211 wifi-device
#scan_mac80211 wifi0
#scan_mac80211 wifi1

config_foreach setup_aaa wifi-device

# keep wait there is no auth_customize_page.sh running , then exist
retry_count=0

ps | grep 'auth_customiz[e]_page' >/dev/null
while [ "$?" = "0" ];
do
	retry_count=$((retry_count+1))
	[ "$retry_count" = "120" ] && break
	sleep 1
	ps | grep 'auth_customiz[e]_page'>/dev/null
done

[ "$retry_count" = "120" ] && exit 1 || exit 0

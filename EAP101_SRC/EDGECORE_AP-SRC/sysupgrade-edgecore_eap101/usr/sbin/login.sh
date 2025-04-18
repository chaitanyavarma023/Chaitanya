#!/bin/sh

TYPE=$1
MAC=$2
IP=$3
INTERFACE="eth0"
bindng_error_code=""

if [ $TYPE = "check" ]; then
	wi_anchor_enabled="$(uci get addon.wianchor.enabled)"
	authport_enabled="$(uci show wireless | grep cloud_aaa | grep "='1'")"
	if [ "$wi_anchor_enabled" = "1" ]; then
		verify_url="`uci -q get addon.wianchor.bindingStatusUrl`"
		ap_mac="$(ifconfig $INTERFACE | awk '/HWaddr/ {print $NF}' | sed 's/://g' | awk '{print tolower($0)}')"
		client_mac="$(echo $MAC | sed 's/-//g' | awk '{print tolower($0)}')"
		_hash_val="$(echo -n $ap_mac$client_mac | md5sum | awk  '{print $1}')"
		hash_val_1=$(expr substr "$_hash_val" 1 4)
		hash_val_2=$(echo "$_hash_val" | grep -o '....$')
		hash_val="${hash_val_1}${hash_val_2}"

		bindng_error_code=$(curl -k -X POST -H 'Content-Type: application/json' -d '{"ap_mac":"'$ap_mac'","client_mac":"'$client_mac'","hash":"'$hash_val'"}' $verify_url --connect-timeout 5 -m 5 | jsonfilter -e "@.error_code")
		if [ "$bindng_error_code" = "1" ]; then
			MAC_addr="$(echo $MAC | sed 's/-/:/g')"
			# Check ${MAC} in /proc
			# Check "${MAC_addr}" in cipgwsrv

			cipnam="$(cat /proc/net/xt_cipnam/users | grep -i ${MAC})"
			cipgwsrv="$(/ramfs/bin/cipgwcli list | grep -i ${MAC_addr})"
			if [ "${cipnam}" = "" -a "${cipgwsrv}" != "" ]; then
				/ramfs/bin/cipgwcli kick "${MAC_addr}"
			elif [ "${cipnam}" != "" -a "${cipgwsrv}" = "" ]; then
                                MAC_tmp=$(echo $MAC| tr [a-z] [A-Z])
                                echo -${MAC_tmp} > /proc/net/xt_cipnam/users
			fi

			if [ "${cipnam}" = "" -o "${cipgwsrv}" = "" ]; then
				/ramfs/bin/cipgwcli newmac "${MAC_addr}" ""
			fi
		fi
	elif [ -z "$authport_enabled" ]; then
		echo "User-Name=\"$MAC\", User-Password=\"$MAC\", Calling-Station-Id=\"$MAC\", ZVendor-Auth-Method=\"roam\"" | radclient 127.0.0.1:1812 auth 12345678 >/dev/null 2>&1 &
	fi
elif [ $TYPE = "login" ]; then
	MAC_addr="${MAC:0:2}:${MAC:2:2}:${MAC:4:2}:${MAC:6:2}:${MAC:8:2}:${MAC:10:2}"
	if [ "${IP}" != "" ]; then
		/ramfs/bin/cipgwcli login "${MAC_addr}" "${MAC}" "${IP}" "" 0 0 0 0 0 0 0 0 0
	else
		/ramfs/bin/cipgwcli newmac "${MAC_addr}" ""
	fi
fi


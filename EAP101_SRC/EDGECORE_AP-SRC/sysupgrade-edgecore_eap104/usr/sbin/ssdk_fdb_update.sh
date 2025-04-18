#!/bin/sh

IFNAME=$1
CMDSTR=$2
STAMAC=$3

if [ "$CMDSTR" = "AP-STA-CONNECTED" ];then
	macstr=`echo $STAMAC|sed 's/:/-/g'`
	fdbent=`ssdk_sh fdb entry show | grep $macstr`
	wi_anchor_enabled="$(uci get addon.wianchor.enabled)"
	[ "$wi_anchor_enabled" = "1" ] && /usr/sbin/login.sh check "$macstr" &
	capwap_enabled="$(uci get acn.capwap.state)"
	[ "$capwap_enabled" = "1" ] && /usr/sbin/external_radius_login.sh $IFNAME $STAMAC &
	if [ -z "$fdbent" ]; then
		echo "entry not found" >/dev/null
	else
		#echo "New connection of $STAMAC, update FDB entry" >/dev/console
		logger -t hostapd_cli "New connection of $STAMAC, update FDB entry"

		fid=`echo "$fdbent"|awk '{print $2}'|sed 's/\[fid\]://g'`
		port=`echo "$fdbent"|awk '{print $4}'|sed 's/\[dest_port\]://g'`

		# remove fdb entry
		ssdk_sh fdb entry del $macstr $fid forward forward $port no no no no no no no no >/dev/null
	fi
fi

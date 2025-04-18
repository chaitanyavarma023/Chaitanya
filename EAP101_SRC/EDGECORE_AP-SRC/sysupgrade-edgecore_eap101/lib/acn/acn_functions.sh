#!/bin/sh

. /lib/functions/system.sh

tip_services="ucentral-event onlinecheck qosify udevmand ucentral-wdt ucentral-wifi maverick fbwifi dnssnoop ustats dhcpsnoop ieee8021x rtty ustpd dynamic-vlan igmpproxy radsecproxy opennds"
ec_services="ulog-listener cipgwsrv discovery mgmt QosUserSrv cipuamd ibeacon tisbl cipfwd check_data_channel capwap mac-auth cipgwnlsrv dhcp_helper prc telnet ser2net snmpd radiusd conntrackd wifischedule"
tip_uci_files="99-tip-certificates.sh 99-ucentral-hostname 99-ucentral-lldp 99-ucentral-network 99-ucentral-opennds 99-ucentral-qos 99-ucentral-rtty 99-ucentral-uhttpd 99-ucentral-umdns 99-ucentral-wifi zzz-ucentral"

ec_srvs_action() {
	for srv in $ec_services; do
		/etc/init.d/$srv $1
	done
}

tip_srvs_action() {
	for srv in $tip_services; do
		/etc/init.d/$srv $1
	done
}

switch_services() {
	local is_ucentral_mode=$(uci -q get acn.mgmt.management)

	if [ ! -z "$is_ucentral_mode" ] && [ "$is_ucentral_mode" -eq 3 ]; then
		# ucentral mode
		# stop ec_serices, start tip_services
		ec_srvs_action disable

		tip_srvs_action enable

		# clean wifi schedule
		/usr/bin/wifi_schedule.sh clean
	else
		# not ucentral mode
		# stop tip_serices, start ec_services
		tip_srvs_action disable

		ec_srvs_action enable
	fi
}

run_tip_uci_files() {
	local is_ucentral_mode=$(uci -q get acn.mgmt.management)
	if [ -z "$is_ucentral_mode" ] || [ "$is_ucentral_mode" -ne 3 ]; then
		return
	fi

	/etc/init.d/send_clientinfo boot

	for file in $tip_uci_files; do
		/bin/sh /rom/etc/uci-defaults/${file}
	done
}

copy_tip_uci_files() {
	local is_ucentral_mode=$(uci -q get acn.mgmt.management)
	if [ -z "$is_ucentral_mode" ] || [ "$is_ucentral_mode" -ne 3 ]; then
		return
	fi

	for file in $tip_uci_files; do
		cp -f /rom/etc/uci-defaults/${file} /etc/uci-defaults
	done

	sync
}

ec_macaddr_to_binary() {
	if [ -z "$1" -o -z "$2" ]; then
		return
	fi

	rm -f $1

	a1=$(echo $2 | cut -d':' -f1)
	a2=$(echo $2 | cut -d':' -f2)
	a3=$(echo $2 | cut -d':' -f3)
	a4=$(echo $2 | cut -d':' -f4)
	a5=$(echo $2 | cut -d':' -f5)
	a6=$(echo $2 | cut -d':' -f6)
	printf "%b" '\x'$a1'\x'$a2'\x'$a3'\x'$a4'\x'$a5'\x'$a6 > $1
}

get_acc_info() {
	local cmd="$1"
	local part cnt offset

	if [ -z "$1" ]; then
		echo ""
	fi

	part=$(find_mtd_chardev "0:ART")
	if [ -z "$part" ]; then
		echo ""
	fi

	case "$cmd" in
		eth0|\
		wan)
			offset=0
			get_mac_binary $part $offset
			;;
		eth1|\
		lan1|\
		lan)
			offset=6
			get_mac_binary $part $offset
			;;
		eth2|\
		lan2)
			offset=12
			get_mac_binary $part $offset
			;;
		eth3|\
		lan3)
			offset=18
			get_mac_binary $part $offset
			;;
		eth4|\
		lan4)
			offset=24
			get_mac_binary $part $offset
			;;
		wifi0)
			offset=30
			get_mac_binary $part $offset
			;;
		wifi1)
			offset=36
			get_mac_binary $part $offset
			;;
		esn)
			cnt=16
			offset=44
			hexdump -v -n ${cnt} -s ${offset} -e '"%c"' $part 2>/dev/null
			;;
		msn)
			cnt=16
			offset=60
			hexdump -v -n ${cnt} -s ${offset} -e '"%c"' $part 2>/dev/null
			;;
	esac
}

set_acc_info() {
	local cmd="$1"
	local out_fn="/tmp/"$cmd
	local val="$2"
	local part cnt offset

	if [ -z "$1" -o -z "$2" ]; then
		echo "set_acc_info: invalid argument" >&2
		return
	fi

	part=$(find_mtd_chardev "0:ART")
	if [ -z "$part" ]; then
		echo "set_acc_info: partition not found!" >&2
		return
	fi

	local partimg="/tmp/"${part##*/}".img"

	case "$cmd" in
		eth0|\
		wan)
			cnt=6
			offset=0
			ec_macaddr_to_binary $out_fn $val
			;;
		eth1|\
		lan1)
			cnt=6
			offset=6
			ec_macaddr_to_binary $out_fn $val
			;;
		eth2|\
		lan2)
			cnt=6
			offset=12
			ec_macaddr_to_binary $out_fn $val
			;;
		eth3|\
		lan3)
			cnt=6
			offset=18
			ec_macaddr_to_binary $out_fn $val
			;;
		eth4|\
		lan4)
			cnt=6
			offset=24
			ec_macaddr_to_binary $out_fn $val
			;;
		wifi0)
			cnt=6
			offset=30
			ec_macaddr_to_binary $out_fn $val
			;;
		wifi1)
			cnt=6
			offset=36
			ec_macaddr_to_binary $out_fn $val
			;;
		esn)
			cnt=16
			offset=44
			rm -f $out_fn
			echo -n $val > $out_fn
			;;
		msn)
			cnt=16
			offset=60
			rm -f $out_fn
			echo -n $val > $out_fn
			;;
	esac

	if [ -f "${out_fn}" ]; then
		dd if=${part} of=${partimg}
		dd if=/dev/zero ibs=1 count=${cnt} > /tmp/erase.img
		dd if=/tmp/erase.img of=${partimg} seek=${offset} obs=1 conv=notrunc
		dd if=${out_fn} of=${partimg} seek=${offset} obs=1 conv=notrunc
		mtd erase ${part}
		dd if=${partimg} of=${part}
		rm -f /tmp/erase.img ${partimg} ${out_fn}
	fi
}

check_internet_connection() {
	local max_seconds=3
	local default_gw=$(ip route show default | awk 'NR==1 { print $3 }')

	#echo $(ping -c 2 $default_gw 2>&1 | grep ttl)
	#local servers="cloud.ignitenet.com staging.ignitenet.com"
	local servers="130.211.9.21 8.8.8.8"
	local p=""
	local cnt=1

	while [ $cnt -lt $max_seconds ]; do
		if [ ! -z "${default_gw}" ]; then
			for s in $servers; do
				p=$(ping -c 2 $s -W 3 2>&1 | grep ttl)
				if [ ! -z "$p" ]; then
					break
				fi
			done
		fi
		if [ ! -z "$p" ]; then
			break #break while
		fi
		sleep 1
		let cnt+=1
	done

	echo $p
}

get_CNAME() {
	local CNAME=$(acc hw get Model | cut -d'=' -f2)

	case "$CNAME" in
		"OAP101-6E"*)
			CNAME=${CNAME##"OAP101-6E"}

			[ -n "$CNAME" ] && {
				CNAME=$(echo $CNAME | awk -F '-' '{print toupper($2)}')
			}
			;;
		"EAP104-L"*)
			CNAME=${CNAME##"EAP104-L"}

			[ -n "$CNAME" ] && {
				CNAME=$(echo $CNAME | awk -F '-' '{print toupper($2)}')
			}
			;;
		*)
			CNAME=$(echo $CNAME | awk -F '-' '{print toupper($2)}')
			;;
	esac

	echo $CNAME
}

get_MID() {
	local MID=$(acc hw get product_name | cut -d'=' -f2)

	local mid
	case "$MID" in
		"OAP101-6E"*)
			mid=${MID##"OAP101-6E"}

			[ -n "$mid" ] && {
				mid=${MID%%"$mid"}
			} || {
				mid=$MID
			}
			;;
		*)
			mid=$(echo $MID | cut -d'-' -f1)
			;;
	esac

	echo $mid
}

get_TxPowerCert_info() {
	cert="FCC"
	country="$(uci -q get wireless.radio0.country)"

	case $country in
	"JP")
		cert="JP"
		;;
	"KR")
		cert="KR"
		;;
	"CA")
		cert="IC"
		;;
	"AU"|"NZ")
		cert="CTICK"
		;;
	"TW")
		cert="NCC"
		;;
	"IN")
		cert="IN"
		;;
	"PH")
		cert="PH"
		;;
	"TH")
		cert="TH"
		;;
	"BR")
		cert="BR"
		;;
	"VN")
		cert="VN"
		;;
	"ID")
		cert="ID"
		;;
	"AT"|"BE"|"BG"|"HR"|"CZ"|"CY"|"DK"|"EE"|"FI"|"FR"|"DE"|"GR"|"HU"|"IS"|"IE"|"IT"|"LV"|"LT"|"LI"|"LU"|"MT"|"NO"|"NL"|"PL"|"PT"|"RO"|"SK"|"SI"|"ES"|"SE"|"CH"|"TR"|"GB")
		cert="ETSI"
		;;

	*)
		#others use US/FCC setting
		cert="FCC"
		;;
	esac

	echo $cert
}
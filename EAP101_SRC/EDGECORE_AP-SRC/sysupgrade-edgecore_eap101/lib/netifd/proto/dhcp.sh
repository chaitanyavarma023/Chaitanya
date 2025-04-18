#!/bin/sh

[ -L /sbin/udhcpc ] || exit 0

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

wait_inet_src() {
	local config="$1"
	local iface="$2"

	# Nothing to wait on when interface is not a bridge.
	if [ ! -d "/sys/class/net/$iface/bridge" ]; then
		return;
	fi

	# Nothing to wait if zone has no internet source set.
	local inet_src="$(uci get network.$config.inet_src)"
	if [ -z "$inet_src" ]; then
		return;
	fi

	local count=0
	local delay=2
	while [ "$count" -le "5" ]
	do
		brctl show | grep -q $inet_src && break
		sleep $delay
		count=$((count + 1))
	done
	echo "Internet source found in $iface after $(($count * $delay)) seconds"
}

proto_dhcp_init_config() {
	renew_handler=1

	proto_config_add_string 'ipaddr:ipaddr'
	proto_config_add_string 'hostname:hostname'
	proto_config_add_string clientid
	proto_config_add_string vendorid
	proto_config_add_boolean 'broadcast:bool'
	proto_config_add_boolean 'norelease:bool'
	proto_config_add_string 'reqopts:list(string)'
	proto_config_add_boolean 'defaultreqopts:bool'
	proto_config_add_string iface6rd
	proto_config_add_array 'sendopts:list(string)'
	proto_config_add_boolean delegate
	proto_config_add_string zone6rd
	proto_config_add_string zone
	proto_config_add_string mtu6rd
	proto_config_add_string customroutes
	proto_config_add_boolean classlessroute
}

proto_dhcp_add_sendopts() {
	[ -n "$1" ] && append "$3" "-x $1"
}

proto_dhcp_setup() {
	local config="$1"
	local iface="$2"

	local ipaddr hostname clientid vendorid broadcast norelease reqopts defaultreqopts iface6rd sendopts delegate zone6rd zone mtu6rd customroutes classlessroute
	json_get_vars ipaddr hostname clientid vendorid broadcast norelease reqopts defaultreqopts iface6rd delegate zone6rd zone mtu6rd customroutes classlessroute

	wait_inet_src $config $iface

	local opt dhcpopts
	for opt in $reqopts; do
		append dhcpopts "-O $opt"
	done

	json_for_each_item proto_dhcp_add_sendopts sendopts dhcpopts

	[ -z "$hostname" ] && hostname="$(cat /proc/sys/kernel/hostname)"
	[ "$hostname" = "*" ] && hostname=

	[ "$defaultreqopts" = 0 ] && defaultreqopts="-o" || defaultreqopts=
	[ "$broadcast" = 1 ] && broadcast="-B" || broadcast=
	[ "$norelease" = 1 ] && norelease="" || norelease="-R"
	[ -n "$clientid" ] && clientid="-x 0x3d:${clientid//:/}" || clientid="-C"
	[ -n "$iface6rd" ] && proto_export "IFACE6RD=$iface6rd"
	[ "$iface6rd" != 0 -a -f /lib/netifd/proto/6rd.sh ] && append dhcpopts "-O 212"
	[ -n "$zone6rd" ] && proto_export "ZONE6RD=$zone6rd"
	[ -n "$zone" ] && proto_export "ZONE=$zone"
	[ -n "$mtu6rd" ] && proto_export "MTU6RD=$mtu6rd"
	[ -n "$customroutes" ] && proto_export "CUSTOMROUTES=$customroutes"
	[ "$delegate" = "0" ] && proto_export "IFACE6RD_DELEGATE=0"
	# Request classless route option (see RFC 3442) by default
	[ "$classlessroute" = "0" ] || append dhcpopts "-O 121"
	[ "$(uci -q get acn.capwap.state)" = "1" -a "$(uci -q get acn.capwap.dhcp_opt)" = "1" ] && append dhcpopts "-O capwap"

	local fallback_ip fallback_nm
	config_load network
	config_get fallback_ip $config fallback_ip
	config_get fallback_nm $config fallback_nm

	json_init
	json_add_string config_section $config
	json_add_string fallback_ip $fallback_ip
	json_add_string fallback_nm $fallback_nm
	json_dump > /var/run/dhcpc-$iface.json

	local arping_opt=
	udhcpc --help 2>&1 | grep -w -- -a >/dev/null && arping_opt=-a
	proto_export "INTERFACE=$config"
	proto_run_command "$config" udhcpc \
		${arping_opt} \
		-p /var/run/udhcpc-$iface.pid \
		-s /lib/netifd/dhcp.script \
		-f -t 4 -i "$iface" \
		${ipaddr:+-r $ipaddr} \
		${hostname:+-x "hostname:$hostname"} \
		${vendorid:+-V "$vendorid"} \
		$clientid $defaultreqopts $broadcast $norelease $dhcpopts
}

proto_dhcp_renew() {
	local interface="$1"
	# SIGUSR1 forces udhcpc to renew its lease
	local sigusr1="$(kill -l SIGUSR1)"
	[ -n "$sigusr1" ] && proto_kill_command "$interface" $sigusr1
}

proto_dhcp_teardown() {
	local interface="$1"
	proto_kill_command "$interface"
}

add_protocol dhcp

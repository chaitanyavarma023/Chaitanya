#!/bin/sh
[ -z "$1" ] && echo "Error: should be run by udhcpc" && exit 1

setup_interface() {
	echo "udhcpc: ifconfig $interface $ip netmask ${subnet:-255.255.255.0} broadcast ${broadcast:-+}"
	ifconfig $interface $ip netmask ${subnet:-255.255.255.0} broadcast ${broadcast:-+}
	ipset list wan_ip >/dev/null 2>&1 || ipset create wan_ip hash:ip
	iptables -t nat -D PROXIED -i $interface -m set --match-set wan_ip dst -p tcp --dport 80 -j DNAT --to-destination ${ip}:80
	iptables -t nat -I PROXIED -i $interface -m set --match-set wan_ip dst -p tcp --dport 80 -j DNAT --to-destination ${ip}:80
	iptables -t nat -D PROXIED -i $interface -m set --match-set wan_ip dst -p tcp --dport 443 -j DNAT --to-destination ${ip}:443
	iptables -t nat -I PROXIED -i $interface -m set --match-set wan_ip dst -p tcp --dport 443 -j DNAT --to-destination ${ip}:443
	echo -n 1 > /sys/class/net/${interface}/bridge/nf_call_iptables
}


applied=
case "$1" in
	deconfig)
		ifconfig "$interface" 0.0.0.0
	;;
	renew)
		setup_interface update
	;;
	bound)
		setup_interface ifup
	;;
esac

# user rules
[ -f /etc/udhcpc.user ] && . /etc/udhcpc.user

exit 0

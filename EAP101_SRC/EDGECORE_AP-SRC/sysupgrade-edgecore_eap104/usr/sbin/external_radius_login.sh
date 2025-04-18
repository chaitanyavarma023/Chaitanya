#!/bin/sh

ifname=$1
mac=$2 

[ ! -f /tmp/split_tunnel_external_radius ] && exit
[ -z "$ifname" -o -z "$mac" ] && exit
ex_radius=$(grep "$ifname " /tmp/split_tunnel_external_radius)

if [ -n "$ex_radius" ]; then
	ac_ip=$(cat /tmp/capwap/mgmt_ip)
	umac=$(echo $mac | tr a-f A-F)
	vid=$(echo $ex_radius | awk '{print $2}')
	sleep 0.5
	uip=$(grep "$mac" /var/dhcp.leases | awk '{printf $3}')
	curl -k -s -d uip=${uip} -d umac=${umac} -d vid=${vid} https://${ac_ip}/external_radius_login.shtml
fi


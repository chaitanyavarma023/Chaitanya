#!/bin/sh

case $2 in
AP-STA-CONNECTED)
	[ $4 = 0 -a $5 = 0 ] && return

	ingress_rate=$4
	egress_rate=$5

	[ "$ingress_rate" = 0 ] && ingress_rate=1000000
	[ "$egress_rate" = 0 ] && egress_rate=1000000

	ubus call client-limit client_set '{"device": "'$1'", "address": "'$3'", "rate_ingress": "'$ingress_rate'kbit", "rate_egress": "'$egress_rate'kbit" }'
	;;
AP-STA-DISCONNECTED)
	ubus call client-limit client_delete '{ "address": "'$3'" }'
	;;
esac

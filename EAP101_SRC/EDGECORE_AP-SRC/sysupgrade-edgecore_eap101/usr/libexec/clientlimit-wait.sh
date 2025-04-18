#!/bin/sh
[ -f /tmp/run/client-limit-$1.pid ] && kill "$(cat /tmp/run/client-limit-$1.pid)"
ubus -t 120 wait_for hostapd.$1
[ $? = 0 ] && hostapd_cli -a /usr/libexec/clientlimit.sh -i $1 -P /tmp/run/client-limit-$1.pid -B

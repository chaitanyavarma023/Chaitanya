#!/bin/sh

BWMONITORNOW="/tmp/bwmonitor_now.json"
BWMONITOROLD="/tmp/bwmonitor_old.json"

while true
do
	if [ -e $BWMONITORNOW ]; then
		mv $BWMONITORNOW $BWMONITOROLD
	fi

	uptime=`cat /proc/uptime | awk '{printf "%0.f", $1}'`
	#result=
	#sub_result=

	echo "{\"period\": 5,\"uptime\": ${uptime},\"interfaces\": {" > $BWMONITORNOW

	for ifname in `ls /sys/class/net/`
	do
		tx_bytes=`cat /sys/class/net/${ifname}/statistics/tx_bytes`
		rx_bytes=`cat /sys/class/net/${ifname}/statistics/rx_bytes`

	    echo "\"${ifname}\":{\"rxBytes\":${rx_bytes}, \"txBytes\":${tx_bytes}}," >> $BWMONITORNOW
	done

	sed -i '$ s/.$//' $BWMONITORNOW

	echo "}}" >> $BWMONITORNOW

	sleep 5
done


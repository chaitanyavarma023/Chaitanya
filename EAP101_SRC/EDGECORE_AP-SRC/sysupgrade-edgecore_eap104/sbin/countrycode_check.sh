#!/bin/sh

log_msg=/tmp/log/country_chk.log

# delay the check
while [ $(cat /proc/uptime | awk '{print $1}'|sed 's/\..*//g') -le 30 ]; do sleep 1; done

for chknum in 1 2 3; do
	need_to_restart=0
	all_pass=1

	echo "Country code check #${chknum}..." >>$log_msg
	for devidx in 0 1; do
		iw_country_code=
		uci_country_code=

		#echo "phy$devidx..." >>$log_msg
		found=`iw reg get|grep -v "([0-9]"|xargs echo|grep "phy#${devidx}"`

		if [ "$found" != "" ]; then
			iw_country_code=`iw reg get|grep -v "([0-9]"|xargs echo|sed 's/.*phy#${devidx}//g' |sed 's/.*country //g'|sed 's/:.*//g'`
		fi

		uci_country_code=`uci get wireless.radio${devidx}.country 2>/dev/null`
		disabled=`uci get wireless.radio${devidx}.disabled 2>/dev/null`

		if [ "$disabled" != "1" -a "$uci_country_code" != "" ]; then
			if [ "$uci_country_code" != "$iw_country_code" ]; then
				all_pass=0
				echo "  Country code setting is incorrect of phy$devidx, check driver message!!" >>$log_msg
				i=0
				while [ $i -le 30 ]; do
					drv_rpt=`logread |grep "bring down to set country code"`
					if [ "$drv_rpt" != "" ]; then
						echo "  Got driver reported, will restart wifi" >>$log_msg
						need_to_restart=1
						break
					fi
					sleep 1
					i=$((i + 1))
				done
				if [ $need_to_restart = 0 ]; then
					echo "  Failed to check driver error" >>$log_msg
				fi
			else
				echo "  Country code check pass of phy${devidx}" >>$log_msg
			fi
		else
			echo "  phy$devidx is disabled or no country code setting" >>$log_msg
		fi
		[ $need_to_restart = 1 ] && break
	done
	if [ $need_to_restart = 1 ]; then
		sleep 1
		echo "Wifi is starting..." >>$log_msg
		/sbin/wifi down
		sleep 2
		/sbin/wifi up
		echo "Restart wifi done" >>$log_msg
	fi
	if [ $all_pass = 1 ]; then
		echo "Country check all pass" >>$log_msg
		break
	fi
	sleep 3
done

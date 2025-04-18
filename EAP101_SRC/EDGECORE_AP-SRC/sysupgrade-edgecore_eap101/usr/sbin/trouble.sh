#!/bin/sh

TROUBLE_VERSION=1

MAC_ADDR=`sed s/://g /sys/class/net/eth0/address`
DATE=`date -I | sed s/-//g`
MID=`acc hw get product_name |cut -d'=' -f2`
TROUBLE_NAME=diagnostics_${MID}_${DATE}_${MAC_ADDR}
TROUBLE_DIR=/tmp/${TROUBLE_NAME}
TROUBLE_FILE=$1
TMP_CONFIG_DIR="$TROUBLE_DIR/config"
TMP_SET_PWD_FILE="$TMP_CONFIG_DIR/set_pwd.sh"

replace_pwd() {
    section=$1
    replace_item=$2
    uci show $section -c $TMP_CONFIG_DIR | grep -E "\.($replace_item)=" | awk -F"=" '{print "uci set "$1"=* -c '$TMP_CONFIG_DIR'"}' >> $TMP_SET_PWD_FILE
    echo "uci commit $section -c $TMP_CONFIG_DIR" >> $TMP_SET_PWD_FILE
}

mask_pwd()
{
	key=$1
	val=$(uci get -c $TMP_CONFIG_DIR $1 2> /dev/null)
	[ -z "$val" ] && return

	# Number of characters to be visible / leftover is stripped/masked
	len=$((`echo $val | wc -m` / 4))
	new=$(echo $val | cut -c -$len)$(printf "%"$len"s" | tr \  \*)
	uci -c $TMP_CONFIG_DIR set $1=$new 2> /dev/null
	uci -c $TMP_CONFIG_DIR commit `echo $key | cut -f 1 -d "."`
}

backup_chilli()
{
    file_name="config local.conf main.conf localusers defaults hs.conf"
    for _name in $file_name; do
        file="/etc/chilli/${_name}"
        [ -f "$file" ] && cp -af ${file} $TROUBLE_DIR/chilli/${_name}
    done
}

rm $TROUBLE_FILE 2> /dev/null
[ -d $TROUBLE_DIR ] && rm -rf $TROUBLE_DIR

mkdir $TROUBLE_DIR
mkdir -p $TROUBLE_DIR/state
mkdir -p $TROUBLE_DIR/log
mkdir -p $TMP_CONFIG_DIR
mkdir -p $TROUBLE_DIR/wireless
mkdir -p $TROUBLE_DIR/chilli

echo $TROUBLE_VERSION > $TROUBLE_DIR/diagnostics_version

logread > $TROUBLE_DIR/logread
for i in wlan0 wlan1; do
       iw dev $i station dump >> $TROUBLE_DIR/iw_dev_station_dump
done

cp -a /etc/config/* $TMP_CONFIG_DIR/
cp -a /var/state/* $TROUBLE_DIR/state/
cp -a /var/log/* $TROUBLE_DIR/log/
#cp /etc/ping_watchdog_debug_log.txt $TROUBLE_DIR/ping_watchdog_debug_log.txt

# ----

dmesg > $TROUBLE_DIR/dmesg

# -- Summary.txt --
summary_file=$TROUBLE_DIR/Summary.txt
echo "============= Product info =============" >> $summary_file
acc hw all >> $summary_file
echo "============= Firmware version =============" >> $summary_file
cat /etc/edgecore_version >> $summary_file
echo "============= Load average =============" >> $summary_file
cat /proc/loadavg >> $summary_file
echo "============= System uptime =============" >> $summary_file
cat /proc/uptime| awk -F. '{run_days=$1 / 86400;run_hour=($1 % 86400)/3600;run_minute=($1 % 3600)/60;run_second=$1 % 60;printf("%dday %dh %dmin %dsec\n",run_days,run_hour,run_minute,run_second)}' >> $summary_file
echo "============= Model name =============" >> $summary_file
cat /var/run/modelname >> $summary_file
# ----

# -- iptables --
echo "============= iptables --list-rules =============" > $TROUBLE_DIR/iptables
iptables --list-rules >> $TROUBLE_DIR/iptables
echo -e "\n============= iptables -L -nv =============" >> $TROUBLE_DIR/iptables
iptables -L -nv >> $TROUBLE_DIR/iptables
echo -e "\n============= iptables -t nat -L -nv =============" >> $TROUBLE_DIR/iptables
iptables -t nat -L -nv >> $TROUBLE_DIR/iptables
echo -e "\n============= iptables -t mangle -L -nv =============" >> $TROUBLE_DIR/iptables
iptables -t mangle -L -nv >> $TROUBLE_DIR/iptables
# ----

# -- network statistics --
case "$MID" in
	EAP101)	port_num=2 ;;
	EAP102)	port_num=1 ;;
	EAP104)	port_num=0 ;;
	*)	port_num=1 ;;
esac

for eth_port in $(seq 0 $port_num); do
	# get ethernet port stats from ethtool
	echo -n "Ethernet Port #$eth_port: " >> $TROUBLE_DIR/port_status
	status=$(ethtool eth$eth_port | grep "Link detected" | awk -F':' '{ print $2 }')
	if [ $status == 'yes' ]; then
		echo "ENABLE" | tr -d '\n' >> $TROUBLE_DIR/port_status
	else
		echo "DISABLE" | tr -d '\n' >> $TROUBLE_DIR/port_status
	fi
	ethtool eth$eth_port | grep "Speed" | awk -F':' '{ print $2 }' | tr -d '\n' >> $TROUBLE_DIR/port_status
	ethtool eth$eth_port | grep "Duplex" | awk -F':' '{ print $2 }' | tr -d '\n' >> $TROUBLE_DIR/port_status
	echo "" >> $TROUBLE_DIR/port_status
done

case "$MID" in
	EAP104)
		for switch_port in $(seq 1 4); do
			echo -n "Ethernet Port #$switch_port: " >> $TROUBLE_DIR/port_status
			swconfig dev switch1 port $switch_port get link | cut -d" " -f2- >> $TROUBLE_DIR/port_status
		done
		;;
esac

route -n > $TROUBLE_DIR/route

ip addr > $TROUBLE_DIR/ip_addr

ifconfig -a > $TROUBLE_DIR/ifconfig

iwinfo > $TROUBLE_DIR/iwinfo

brctl show > $TROUBLE_DIR/brctl

cat /proc/net/vlan/config >> $TROUBLE_DIR/vlan_config

cat /tmp/dhcp.leases >> $TROUBLE_DIR/dhcp.leases
# ----

# -- usbwatchd --
which usbwatchd >/dev/null && {
	cat /etc/usbwatchd_log.txt > $TROUBLE_DIR/usbwatchd_log.txt
	cat /etc/usbwatchd_dongle_status.log > $TROUBLE_DIR/usbwatchd_dongle_status.log
}
# ----

[ -f /etc/migrate/migratever ] && cat /etc/migrate/migratever >> $TROUBLE_DIR/migratever

cat /etc/rc.local >> $TROUBLE_DIR/rc.local

ls -l /etc/rc.d/ >> $TROUBLE_DIR/rc.d

cat /proc/meminfo > $TROUBLE_DIR/meminfo

cat /proc/cmdline > $TROUBLE_DIR/cmdline

cat /etc/openwrt_release > $TROUBLE_DIR/openwrt_release
[ -f "/etc/edgecore_release" ] && cp /etc/edgecore_release $TROUBLE_DIR/
[ -f "/etc/edgecore_version" ] && cp /etc/edgecore_version $TROUBLE_DIR/

# -- ramoops --
[ -d "/sys/fs/pstore" ] && cp -a /sys/fs/pstore $TROUBLE_DIR/ramoops
# ----

ps -wwww > $TROUBLE_DIR/ps

[ -f "/tmp/mgmtd_statu" ] && cp -a /tmp/mgmtd_status $TROUBLE_DIR/mgmtd_status

cat /proc/mounts > $TROUBLE_DIR/mounts

if [ -d /mnt/media ]; then
    ls -laR /mnt/media > $TROUBLE_DIR/media_info
    if [ -f /mnt/media/schedule.json ]; then
        cat "/mnt/media/schedule.json" > $TROUBLE_DIR/media_schedule.json
    fi
else
    echo "There is no media folder." > $TROUBLE_DIR/media_info
fi

[ -f "/usr/bin/lsusb" ] && /usr/bin/lsusb > $TROUBLE_DIR/lsusb

cp -a /tmp/state $TROUBLE_DIR/

# Replace passwords with * in the configuation files
mask_pwd "acn.register.pass"
replace_pwd "users"    "passwd"             2> /dev/null
replace_pwd "radius_auth" "secret"          2> /dev/null
replace_pwd "network"  "password"           2> /dev/null
replace_pwd "hotspot"  "hs_shared|hs_portal_secret" 2> /dev/null
replace_pwd "wireless" "key|auth_secret|acct_secret|password|encryption_60g_key" 2> /dev/null
[ -f $TMP_SET_PWD_FILE ] && {
    chmod 777 $TMP_SET_PWD_FILE 2> /dev/null
    $TMP_SET_PWD_FILE 2> /dev/null
}

# resolve.conf
[ -f "/tmp/resolv.conf" ] && cat /tmp/resolv.conf > $TROUBLE_DIR/resolv.conf
[ -f "/tmp/resolv.conf.auto" ] && cat /tmp/resolv.conf.auto > $TROUBLE_DIR/resolv.conf.auto

# take first default GW address -- it should have highest metric.
default_gateway=`route | grep default | awk 'NR==1 { print $2 }'`
if [ -z "$default_gateway" ]; then
	echo "Default gateway missing" > $TROUBLE_DIR/ping-gw
else
	ping -q -c 1 -W 5 $default_gateway > $TROUBLE_DIR/ping-gw
fi

if [ -f "/tmp/resolv.conf.auto" ]; then
for nameserv in $(cat /tmp/resolv.conf.auto | grep nameserver | cut -f2 -d' '); do
	ping -q -c 1 -W 5 $nameserv >> $TROUBLE_DIR/ping-dns
done
else
	echo "File /tmp/resolv.conf.auto not found" >> $TROUBLE_DIR/ping-dns
fi

# -- Wireless --
# for every vap list connected clients and querie txrx stats
for vap in $(iw dev|grep Interface|sed 's/.*Interface //g'); do
	echo "======= $vap =======" >> $TROUBLE_DIR/client_list
	iwinfo $vap assoc >> $TROUBLE_DIR/client_list
done

#echo "======= apstats wifi0  =======" >> $TROUBLE_DIR/apstats
#apstats -r -i wifi0 >> $TROUBLE_DIR/apstats
#echo "======= apstats wifi1  =======" >> $TROUBLE_DIR/apstats
#apstats -r -i wifi1 >> $TROUBLE_DIR/apstats


# populate dmesg with some vap stats
#echo "===================================" > /dev/kmsg
#echo "======= VAP DMESG STATS ===========" > /dev/kmsg
#for vap in $(iwconfig 2>/dev/null | grep ath | awk '{print $1}'); do
#        echo "========== $vap ============" > /dev/ksmg
#	iwpriv $vap txrx_fw_mstats 0xf 
#	iwpriv $vap txrx_fw_mstats 0x13 
#	echo "===================================" > /dev/ksmg
#done
#sleep 1; # without sleep we can dump the dmesg buffer before printing is finished
#dmesg > $TROUBLE_DIR/stats_dmesg



[ -f "/var/run/stats/wireless.json" ] && cp /var/run/stats/wireless.json $TROUBLE_DIR
[ -f "/var/run/stats/statistics.json" ] && cp /var/run/stats/statistics.json $TROUBLE_DIR
[ -f "/var/run/stats/system.json" ] && cp /var/run/stats/system.json $TROUBLE_DIR
[ -f "/var/run/stats/bwmonitor.json" ] && cp /var/run/stats/bwmonitor.json $TROUBLE_DIR
[ -f "/var/run/stats/bwprecise.json" ] && cp /var/run/stats/bwprecise.json $TROUBLE_DIR

#iwlist ath0 scan > $TROUBLE_DIR/wireless/ath0_scan 2> /dev/null
#iwlist ath1 scan > $TROUBLE_DIR/wireless/ath1_scan 2> /dev/null
for hconf in $(ls /var/run/ | grep 'hostapd.*conf'); do
	cat /var/run/$hconf > $TROUBLE_DIR/wireless/$hconf 2> /dev/null
done

#which prs_serial >/dev/null && {
#	for rad_id in $(seq 0 2); do
#		path=$(uci get wireless.radio$rad_id.path 2>/dev/null)
#		if [ ! -z $path ]; then
#			tty_idx=$(ls /sys/devices/$path/*/tty | sed -e 's,ttyACM,,g' | tr -d '\n')
#			prs_serial device$tty_idx status > $TROUBLE_DIR/wireless/prs_radio${rad_id}_serial_status 2> /dev/null
#			prs_serial device$tty_idx version > $TROUBLE_DIR/wireless/prs_radio${rad_id}_serial_version 2> /dev/null
#			trouble_rssi_60g_file=$TROUBLE_DIR/wireless/rssi_60g_radio$rad_id
#			rssi_file="/sys/devices/$path/prs_attrs/rx_rssi"
#			remote_rssi_file="/sys/devices/$path/mib/extMac/staInfo/1/LastRemoteRssi"
#			rm -f $trouble_rssi_60g_file
#			if [ -f $rssi_file ]; then
#				echo -n "rssi:" >> $trouble_rssi_60g_file
#				cat $rssi_file >> $trouble_rssi_60g_file 2> /dev/null
#			fi
#			if [ -f $remote_rssi_file ]; then
#				remote_rssi=`cat $remote_rssi_file 2>/dev/null`
#				remote_rssi=`expr $remote_rssi - 256`
#				echo "remote rssi:$remote_rssi" >> $trouble_rssi_60g_file
#			fi
#		fi
#	done
#}

backup_chilli

#tar file
tar -cz -C /tmp/ -f $TROUBLE_FILE $TROUBLE_NAME

rm -rf $TROUBLE_DIR

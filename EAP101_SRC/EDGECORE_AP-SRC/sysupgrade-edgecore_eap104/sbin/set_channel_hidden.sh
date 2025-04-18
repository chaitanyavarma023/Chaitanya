#!/bin/sh

TMP_REBOOT_AUTO_FLAG="/tmp/test_auto_reboot"
set_channel=$1
radio_id=$2
reboot_flag='0'
chk_channel_file="$TMP_REBOOT_AUTO_FLAG"
if [ -f $chk_channel_file ]; then
	reboot_flag='1'
fi

if [ "$set_channel" == "0" ]; then
#latest radio need to reboot
	if [ "$radio_id" == "0" ]; then
		reboot_flag='1'
	fi 
	set_channel="auto"
	if [ ! -f $chk_channel_file ]; then
		make_channel_cmd="touch $chk_channel_file"
		$make_channel_cmd
	fi
fi
# change wireless config
uci set wireless.radio$radio_id.channel=$set_channel
uci commit wireless

if [ "$radio_id" == '0' ]; then
	if [ -f $chk_channel_file ]; then
		make_channel_cmd="rm $chk_channel_file"
		$make_channel_cmd
	fi
	if [ "$reboot_flag" == "1" ]; then
		cmd="reboot"
		$cmd
	fi
fi

# apply channel update to all of the radio's interfaces using iw command
ubus call network.wireless status | jsonfilter -e "@.radio$2.interfaces" | jsonfilter -e "@[*].ifname" | while read LINE; do
    ifconfig $LINE down
    iw dev $LINE set channel $set_channel
    ifconfig $LINE up
done

exit 0

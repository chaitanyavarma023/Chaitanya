#!/bin/sh

tx_power=$1
radio_id=$2

uci set wireless.radio$radio_id.txpower=$tx_power
uci commit wireless

tx_power_tmp=`expr $tx_power \* 100`
iw phy phy$radio_id set txpower fixed $tx_power_tmp

exit 0

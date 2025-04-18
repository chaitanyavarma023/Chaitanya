#!/bin/sh

rx_tx="$1"
radio_val="$2"
interval="2"

total_bytes_before="0"
total_bytes_after="0"
final_bits_before="0"
final_bits_after="0"
bps="0"
final_bps="0"

get_stats() {
    local ifaces="$1"
    local get_bytes="$2"
    local data_bytes="0"
    local total_bytes="0"

    for iface in $ifaces; do
        data_bytes=$(cat /sys/class/net/$iface/statistics/$get_bytes)
        total_bytes=$(($total_bytes+$data_bytes))
    done
    echo "$total_bytes"
}

# check if download OR upload rate is required
if [ "$rx_tx" == "download" ]; then
    get_bytes="rx_bytes"
elif [ "$rx_tx" == "upload" ]; then
    get_bytes="tx_bytes"
fi

# get iface list and count from ubus
iface_list=$(ubus call network.wireless status | jsonfilter -e "@.radio$radio_val.interfaces" | jsonfilter -e "@[*].ifname")
iface_counter=$(echo "$iface_list" | wc -l)

# get byte stats before interval and convert to bits
total_bytes_before=$(get_stats "${iface_list}" "$get_bytes")
final_bits_before=$(($total_bytes_before*8))

sleep $interval

# get byte stats after after interval and convert to bits
total_bytes_after=$(get_stats "${iface_list}" "$get_bytes")
final_bits_after=$(($total_bytes_after*8))

# get rx rate rate per sec
bps=$((($final_bits_after-$final_bits_before) / $interval))
final_bps=$(($bps/$iface_counter))

echo "$final_bps"

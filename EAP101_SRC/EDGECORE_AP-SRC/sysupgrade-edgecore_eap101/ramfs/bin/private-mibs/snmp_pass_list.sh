#!/bin/sh

get_pass_list() {
    [ -f /tmp/pass_list ] && rm /tmp/pass_list
    product_name=$(cat /proc/device-tree/model | cut -d " " -f 2)
	edgecore=".1.3.6.1.4.1.259.10.3"
	path="/ramfs/bin/private-mibs"

    num="38"

    echo "pass $edgecore.$num.2.1 $path/system_info.sh" >> /tmp/pass_list
    echo "pass $edgecore.$num.6.1 $path/ap_system_info.sh" >> /tmp/pass_list
    echo "pass $edgecore.$num.6.2 $path/ap_rf_info.sh" >> /tmp/pass_list
    echo "pass $edgecore.$num.6.3 $path/ap_ssid_info.sh" >> /tmp/pass_list
    echo "pass_persist $edgecore.$num.6.5 $path/ap_sta_info.sh" >> /tmp/pass_list
}

get_pass_list

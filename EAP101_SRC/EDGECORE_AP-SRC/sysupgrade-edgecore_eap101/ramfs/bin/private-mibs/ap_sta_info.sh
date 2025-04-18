#!/bin/sh 
product_name=$(cat /proc/device-tree/model | cut -d " " -f 2)

PLACE=".1.3.6.1.4.1.259.10.3.38.6.5"

function mac_to_oid() {
    local mac=${1//:/ }
    local mac_oid=""

    for mac_num in $mac; do	
    mac_oid=$mac_oid"."$((0x$mac_num))
    done

    echo $mac_oid
}

function get_mibtree() {
    [ ! -f /tmp/last_time ] && echo 0 > /tmp/last_time
    local last_time=$(read last_time < /tmp/last_time; echo $last_time)
    local curr_time=$(read uptime < /proc/uptime; uptime=${uptime%%.*}; echo $uptime)
    local time_gap=$((curr_time-last_time))
    echo $curr_time > /tmp/last_time
    
    if [ "$time_gap" -gt 15 ]; then
    [ -f /tmp/mib_tree ] && rm /tmp/mib_tree
    local iface_list=$(iwinfo |grep ESSID | awk '{print $1}')

    for iface_in_list in $iface_list; do
        local mac_list=$(iw $iface_in_list station dump | grep Station | awk '{print $2}')

        if [ -n "$mac_list" ]; then
        for mac_in_list in $mac_list; do
            echo $mac_in_list"|"$iface_in_list >> /tmp/mac_list
        done
        fi
    done

    local num=1
    local sort_mac_list=$(sort /tmp/mac_list)

    while [ $num -le 18 ]; do
        for sort_mac_in_list in $sort_mac_list; do
        local mac=$(echo $sort_mac_in_list | cut -d "|" -f 1)
        local iface=$(echo $sort_mac_in_list | cut -d "|" -f 2)
        local mac_oid=$(mac_to_oid $mac)
        local oid=$PLACE".1.1."$num$mac_oid
        echo $mac $iface $oid >> /tmp/mib_tree
        done
        num=$((num+1))
    done
    rm /tmp/mac_list
    fi
}

function num_cnt() {
    local str=$1
    local cnt=0

    for i in $str; do
        cnt=$((cnt+1))
    done
    echo $cnt
}

function getnext_oid() {
    local REQ=$1
    local opt=$(echo $REQ | cut -d "." -f 16)

    case "$REQ" in
    $PLACE|$PLACE.1|$PLACE.1.1|$PLACE.1.1.1|$PLACE.1.1.1.0)
        RET=$(read a < /tmp/mib_tree;echo $a |awk '{print $3}')
        ;;
    $PLACE.1.1.$opt)
        local oid=$(grep -nw "$REQ" /tmp/mib_tree | cut -d ":" -f 1)
        local oid_line=$(echo $oid | awk '{print $1}')
        RET=$(sed -n $oid_line\p /tmp/mib_tree | awk '{print $3}')
        ;;
    *)
        local oid=$(grep -nw "$REQ" /tmp/mib_tree | cut -d ":" -f 1)
        local oid_line=$(echo $oid | awk '{print $1}')
        local oid_num_cnt=$(num_cnt "$oid")
        [ "$oid_num_cnt" -eq 1 ] && oid_line=$((oid_line+1))
        RET=$(sed -n $oid_line\p /tmp/mib_tree | awk '{print $3}')
        ;;
    esac
}

function get_oid() {
    local REQ=$1
    
    case "$REQ" in
    $PLACE)
        exit 0
        ;;
    *)
        RET=$REQ
        ;;
    esac
}

function err_not_writeable() {
    echo "not-writeable"
    exit
}

function output() {
    local OID_MAC=$1
    local iface=$(grep -w "$OID_MAC" /tmp/mib_tree | awk '{print $2}')
    local mac_addr=$(grep -w "$OID_MAC" /tmp/mib_tree | awk '{print $1}')
        
    # System Info
    case "$OID_MAC" in
    $PLACE.1.1.1.*) #APStaMACAddress
        value=$mac_addr
        echo "$OID_MAC"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.1.1.2.*) #APStaSSIDName
        iface=$(echo $iface | cut -d "." -f 1)
        value=$(iwinfo $iface info | grep ESSID | awk '{print $3}' | cut -d '"' -f 2)
        echo "$OID_MAC"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.1.1.3.*) #APStaVlanId
        value=""
        case "$iface" in
            wlan0|wlan1)
                local radio=${iface/wlan/radio}\_1
                ;;
            *.*)
                value=$(echo $iface | cut -d "." -f 2)
                ;;
            wlan0-*|wlan1-*)
                local num=$(echo $iface | cut -d "-" -f 2)
                local radio=$(echo ${iface/wlan/radio} | cut -d "-" -f 1)_$((num+1))
                ;;
        esac
        if [ -n "$radio" ]; then
            local vlan_chk=$(uci show wireless.$radio.network | grep vlan)
            if [ -n "$vlan_chk" ]; then
                local vlan=$(uci get wireless.$radio.network)
                local ifname=$(uci get network.$vlan.ifname)
                value=$(echo $ifname | awk '{print $1}' | cut -d "." -f 2)
            fi
        fi
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.4.*) #APStaTxBytes
        value=$(iw $iface station get $mac_addr | grep "tx bytes" | awk '{print $3}')
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.5.*) #APStaRxBytes
        value=$(iw $iface station get $mac_addr | grep "rx bytes" | awk '{print $3}')
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.6.*) #APStaRSSI (-dBm)
        value="$(iwinfo $iface assoclist | grep -i $mac_addr | grep dBm | awk '{print $2}')"
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.7.*) #APStaSNR
        value="$(iwinfo $iface assoclist | grep -i $mac_addr | grep dBm | awk '{print $8}' | cut -d ")" -f 1)"
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.8.*) #APStaBandCheck (GHz)
        [ "$iface" == "wlan0" ] &&  value="5"
        [ "$iface" == "wlan1" ] &&  value="2.4"
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.9.*) #APStaConnectionTime (s)
        value=$(iw $iface station get $mac_addr | grep "connected" | awk '{print $3}')
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.10.*) #APStaIdleTime (ms)
        value="$(iw $iface station get $mac_addr | grep inactive | cut -d ":" -f 2 | cut -d " " -f 1)"
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.11.*) #APStaTransmitRate (MBit/s)
        value=$(iw $iface station get $mac_addr | grep "tx bitrate" | awk '{print $3}')
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.12.*) #APStaTxPkts
        value=$(iw $iface station get $mac_addr | grep "tx packets" | awk '{print $3}')
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.13.*) #APStaRxPkts
        value=$(iw $iface station get $mac_addr | grep "rx packets" | awk '{print $3}')
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.14.*) #APStaSSIDmacAddress
        value=$(iwinfo $iface info | grep "Access Point" | awk '{print $3}')
        echo "$OID_MAC"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.1.1.15.*) #APStaRadioMode
        mode="$(iwinfo $iface info | grep 'HW Mode' | awk '{print $5}')"

        case "$mode" in
            802.11nacax)    value="802.11 ax/a" ;;
            802.11bgnax)    value="802.11 ax/g" ;;
        esac
        echo "$OID_MAC"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.1.1.16.*) #APStaRadioChannelWidth (MHz)
        value="$(iw $iface info | grep channel | awk '{print $6}')"
        echo "$OID_MAC"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.1.1.17.*) #APStaName
        get_mac_addr=$(echo $mac_addr | tr 'a-z' 'A-Z')
        value=$(ubus call luci "getECDhcpList" | jsonfilter -e "@['$get_mac_addr'].name")
        echo "$OID_MAC"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.1.1.18.*) #APStaIPAddress
        get_mac_addr=$(echo $mac_addr | tr 'a-z' 'A-Z')
        value=$(ubus call luci "getECDhcpList" | jsonfilter -e "@['$get_mac_addr'].ipv4")
        echo "$OID_MAC"
        echo "string"; echo $value; exit 0 ;;
    *) echo "string"; echo "ack... $OID_MAC"; exit 0 ;;
    esac
}

while read -r line; do
    case "$line" in
    PING)
        echo "PONG"
        ;;
    get)
        read -r oid
        get_mibtree
        get_oid $oid
        output $RET
        ;;
    getnext)
        read -r oid
        get_mibtree
        getnext_oid $oid
        output $RET
        ;;
    set)
        err_not_writeable
        ;;
    *)
        exit 1
        ;;
    esac
done

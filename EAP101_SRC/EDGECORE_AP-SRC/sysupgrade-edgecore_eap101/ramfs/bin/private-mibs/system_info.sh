#!/bin/sh
product_name=$(cat /proc/device-tree/model | cut -d " " -f 2)

PLACE=".1.3.6.1.4.1.259.10.3.38.2.1"

OP="$1"
REQ="$2"

if [ "$OP" = "-s" ]; then
    #get type
    WRITE_TYPE="$3"
    shift;
    shift;
    shift;
    #get value
    WRITE_VALUE="$@"
fi

mesh_btn=$(uci get wireless.wmesh.disabled)
[ "$mesh_btn" -eq 1 ] && vap=16 || vap=15
rf="$(echo $REQ | cut -d "." -f 18)"
num="$(echo $REQ | cut -d "." -f 19)"

if [ "$OP" = "-n" ]; then
    case "$REQ" in
    $PLACE|$PLACE.1)                                                            RET=$PLACE.1.0 ;;
    $PLACE.1.0|$PLACE.2)                                                        RET=$PLACE.2.0 ;;
    $PLACE.2.0|$PLACE.3)                                                        RET=$PLACE.3.0 ;;
    $PLACE.3.0|$PLACE.4)                                                        RET=$PLACE.4.0 ;;
    $PLACE.4.0|$PLACE.5)                                                        RET=$PLACE.5.0 ;;
    $PLACE.5.0|$PLACE.6)                                                        RET=$PLACE.6.0 ;;
    $PLACE.6.0|$PLACE.7)                                                        RET=$PLACE.7.0 ;;
    $PLACE.7.0|$PLACE.8)                                                        RET=$PLACE.8.0 ;;
    $PLACE.8.0|$PLACE.9)                                                        RET=$PLACE.9.0 ;;
    $PLACE.9.0|$PLACE.10|$PLACE.10.0|$PLACE.10.1)                               RET=$PLACE.10.1.0 ;;
    $PLACE.10.1.0|$PLACE.10.2)                                                  RET=$PLACE.10.2.0 ;;
    $PLACE.10.2.0|$PLACE.10.3)                                                  RET=$PLACE.10.3.0 ;;
    $PLACE.10.3.0|$PLACE.10.4)                                                  RET=$PLACE.10.4.0 ;;
    $PLACE.10.4.0|$PLACE.10.5)                                                  RET=$PLACE.10.5.0 ;;
    $PLACE.10.5.0|$PLACE.11)                                                    RET=$PLACE.11.0 ;;
    $PLACE.11.0|$PLACE.12)                                                      RET=$PLACE.12.0 ;;
    $PLACE.12.0|$PLACE.13)                                                      RET=$PLACE.13.0 ;;
    $PLACE.13.0|$PLACE.14)                                                      RET=$PLACE.14.0 ;;
    $PLACE.14.0|$PLACE.15)                                                      RET=$PLACE.15.0 ;;
    $PLACE.15.0|$PLACE.16)                                                      RET=$PLACE.16.0 ;;
    $PLACE.16.0|$PLACE.17)                                                      RET=$PLACE.17.0 ;;
    $PLACE.17.0|$PLACE.18|$PLACE.18.1\
        |$PLACE.18.1.1|$PLACE.18.1.1.1|$PLACE.18.1.1.1.1)                       RET=$PLACE.18.1.1.1.1.0 ;;
    $PLACE.18.1.1.1.1.0|$PLACE.18.1.1.1.2)                                      RET=$PLACE.18.1.1.1.2.0 ;;
    $PLACE.18.1.1.1.2.0|$PLACE.19|$PLACE.19.1\
        |$PLACE.19.1.1|$PLACE.19.1.1.1|$PLACE.19.1.1.1.1|$PLACE.19.1.1.1.1.1)   RET=$PLACE.19.1.1.1.1.1.0 ;;
    $PLACE.19.1.1.1.1.2)                                                        RET=$PLACE.19.1.1.1.1.2.0 ;;
    $PLACE.19.1.1.1.2|$PLACE.19.1.1.1.2.$num)                                   [ -z "$num" ] && RET=$PLACE.19.1.1.1.2.1.0 || RET=$PLACE.19.1.1.1.2.$num.0 ;;
    $PLACE.19.1.1.1.1.1.0|$PLACE.19.1.1.1.1.$num*)                              [ "$num" -lt "$vap" ] && RET=$PLACE.19.1.1.1.1.$((num+1)).0 || RET=$PLACE.19.1.1.1.2.1.0 ;;
    $PLACE.19.1.1.1.2.1.0|$PLACE.19.1.1.1.2.$num*)                              [ "$num" -lt "$vap" ] && RET=$PLACE.19.1.1.1.2.$((num+1)).0 || exit ;;
    *)                                                                          exit 0 ;;
    esac
else
    case "$REQ" in
    $PLACE)    exit 0 ;;
    *)         RET=$REQ ;;
    esac
fi

radio_num="$(($(echo $RET | cut -d "." -f 18)-1))"
vap_num="$(echo $RET | cut -d "." -f 19)"

function num_cnt() {
    local str=$1
    local cnt=0

    for i in $str; do
        cnt=$((cnt+1))
    done
    echo $cnt
}

function err_not_writeable() {
    echo "not-writeable"
    exit
}

function output() {
    local RET_OID="$1"

    case "$RET_OID" in
        # System Info
    $PLACE.1.0) #CpuFrequency
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(cat /proc/cpuinfo | grep Hardware | cut -d ':' -f 2)
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.2.0) #RamSize
        [ "$OP" == "-s" ] && err_not_writeable
        value="$(free | grep Mem | awk '{print $2}')"
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.3.0) #FlashSize
        [ "$OP" == "-s" ] && err_not_writeable
        value="$(dmesg | less | grep nand: | grep MiB | awk '{print $4 $5}' | cut -d "," -f 1)"
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.4.0) #VersionDescription
        [ "$OP" == "-s" ] && err_not_writeable
#	    value=$(cat /etc/os-release | grep VERSION_ | cut -d "\"" -f 2)
        value=$(cat /etc/edgecore_version | grep -)
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.5.0) #BuildNumber
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(cat /etc/edgecore_version | grep -v -)
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.6.0) #CountryCode
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(uci get wireless.radio0.country)
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.7.0) #MaxRfCard
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(uci show wireless | grep wifi-device | wc -l)
        echo "$RET_OID"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.8.0) #MaxVAP
        [ "$OP" == "-s" ] && err_not_writeable
        value="16"
        echo "$RET_OID"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.9.0) #OperationMode
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(uci get wireless.radio0.mode)
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.10.1.0) #TypeOfIpConfig
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(uci get network.wan.proto)
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.10.2.0) #MacOfDev
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(ifconfig br-wan | grep HWaddr | awk '{print $5}' | sed 's/:/ /g')
        echo "$RET_OID"
        echo "octetstring"; echo $value; exit 0 ;;
    $PLACE.10.3.0) #IpOfDev
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(ifconfig br-wan | grep "inet addr" | awk '{print $2}' | cut -d ':' -f 2)
        echo "$RET_OID"
        if [ "$value" == "" ]; then
            value="(null)"
            echo "string"; echo $value; exit 0
        else
            echo "string"; echo $value; exit 0
        fi
        ;;
    $PLACE.10.4.0) #NetmaskOfDev
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(ifconfig br-wan | grep "Mask" | awk '{print $4}' | cut -d ':' -f 2)
        echo "$RET_OID"
        if [ "$value" == "" ]; then
            value="(null)"
            echo "string"; echo $value; exit 0
        else
            echo "string"; echo $value; exit 0
        fi
        ;;
    $PLACE.10.5.0) #GatewayOfDev
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(ip r | grep default | awk '{print $3}')
        echo "$RET_OID"
        if [ "$value" == "" ]; then
            value="(null)"
            echo "string"; echo $value; exit 0
        else
            echo "string"; echo $value; exit 0
        fi
        ;;
    $PLACE.11.0) #Model
        [ "$OP" == "-s" ] && err_not_writeable
        value=$product_name
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.12.0) #Manufacture
        [ "$OP" == "-s" ] && err_not_writeable
        value="Edgecore"
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.13.0) #UpTime
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(uptime)
        value=${value#*up}
        value=${value%load*}
        value=${value//,/ }
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.14.0) #CPUAvgUsage (last 1-minute, 5-minute and 15-minute CPU load average.)
        [ "$OP" == "-s" ] && err_not_writeable
        value=$(uptime)
        value=${value##*load average:}
        echo "$RET_OID"
        echo "string"; echo $value; exit 0 ;;
    $PLACE.15.0) #MemRTUsage (%)
        [ "$OP" == "-s" ] && err_not_writeable
        MemTotal=$(cat proc/meminfo | grep MemTotal | awk '{print $2}')
        MemAvailable=$(cat proc/meminfo | grep MemAvailable | awk '{print $2}')
        value="$(((MemTotal - MemAvailable)*100/MemTotal))"
        echo "$RET_OID"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.16.0) #CPURTUsage (%)
        [ "$OP" == "-s" ] && err_not_writeable
        value=$((100-$(top -n 1 | grep "CPU\:" | awk '{print $8}' | cut -d '%' -f 1)))
        echo "$RET_OID"
        echo "integer"; echo $value; exit 0 ;;
    $PLACE.17.0) #TotalAssociatedClient
        [ "$OP" == "-s" ] && err_not_writeable
        local iface_list=$(iwinfo |grep ESSID | awk '{print $1}')
        local total_cnt=0

        for iface_in_list in $iface_list; do
            local mac_list=$(iw $iface_in_list station dump | grep Station | awk '{print $2}')

            if [ -n "$mac_list" ]; then
                total_cnt=$((total_cnt+$(num_cnt "$mac_list")))
            fi
        done
        echo "$RET_OID"
        echo "integer"; echo $total_cnt; exit 0 ;;
    $PLACE.18.1.1.1*) #TotalAssociatedClientPerRadio
        [ "$OP" == "-s" ] && err_not_writeable
        local iface_list=$(iwinfo |grep ESSID | awk '{print $1}' | grep wlan$radio_num)
        local total_cnt=0

        for iface_in_list in $iface_list; do
            local mac_list=$(iw $iface_in_list station dump | grep Station | awk '{print $2}')

            if [ -n "$mac_list" ]; then
                total_cnt=$((total_cnt+$(num_cnt "$mac_list")))
            fi
        done
        echo "$RET_OID"
        echo "integer"; echo $total_cnt; exit 0 ;;
    $PLACE.19.1.1.1*) #TotalAssociatedClientPerSSID
        [ "$OP" == "-s" ] && err_not_writeable
            [ "$vap_num" -eq 1 ] && iface="wlan$radio_num" || iface="wlan$radio_num-$((vap_num-1))"
            local mac_list=$(iw $iface station dump | grep Station | awk '{print $2}')

            if [ -n "$mac_list" ]; then
                total_cnt=$((total_cnt+$(num_cnt "$mac_list")))
            fi
        echo "$RET_OID"
        echo "integer"; echo $total_cnt; exit 0 ;;
    *)  echo "string"; echo "ack... $RET_OID $REQ"; exit 0 ;;
    esac
}
output $RET
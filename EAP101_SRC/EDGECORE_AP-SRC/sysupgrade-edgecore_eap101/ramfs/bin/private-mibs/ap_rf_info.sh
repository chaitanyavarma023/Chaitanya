#!/bin/sh
product_name=$(cat /proc/device-tree/model | cut -d " " -f 2)

PLACE=".1.3.6.1.4.1.259.10.3.38.6.2"

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

if [ "$OP" = "-n" ]; then
    user_num=$(echo $REQ | cut -d "." -f 18)
    case "$REQ" in
    #------------------------------PHYSICAL RADIO SETTINGS-------------------------------
        $PLACE|$PLACE.1|$PLACE.1.1|$PLACE.1.1.1\
            |$PLACE.1.1.1.1|$PLACE.1.1.1.1.1)                                                                       RET=$PLACE.1.1.1.1.1.0 ;;
        $PLACE.1.1.1.1.1.0|$PLACE.1.1.1.1.2)                                                                        RET=$PLACE.1.1.1.1.2.0 ;;
        $PLACE.1.1.1.1.2.0|$PLACE.1.1.1.2|$PLACE.1.1.1.2.1)                                                         RET=$PLACE.1.1.1.2.1.0 ;;
        $PLACE.1.1.1.2.1.0|$PLACE.1.1.1.2.2)                                                                        RET=$PLACE.1.1.1.2.2.0 ;;
        $PLACE.1.1.1.2.2.0|$PLACE.1.1.1.3|$PLACE.1.1.1.3.1)                                                         RET=$PLACE.1.1.1.3.1.0 ;;
        $PLACE.1.1.1.3.1.0|$PLACE.1.1.1.3.2)                                                                        RET=$PLACE.1.1.1.3.2.0 ;;
        $PLACE.1.1.1.3.2.0|$PLACE.1.1.1.4|$PLACE.1.1.1.4.1)                                                         RET=$PLACE.1.1.1.4.1.0 ;;
        $PLACE.1.1.1.4.1.0|$PLACE.1.1.1.4.2)                                                                        RET=$PLACE.1.1.1.4.2.0 ;;
        $PLACE.1.1.1.4.2.0|$PLACE.1.1.1.5|$PLACE.1.1.1.5.1)                                                         RET=$PLACE.1.1.1.5.1.0 ;;
        $PLACE.1.1.1.5.1.0|$PLACE.1.1.1.5.2)                                                                        RET=$PLACE.1.1.1.5.2.0 ;;
        $PLACE.1.1.1.5.2.0|$PLACE.1.1.1.6|$PLACE.1.1.1.6.1)                                                         RET=$PLACE.1.1.1.6.1.0 ;;
        $PLACE.1.1.1.6.1.0|$PLACE.1.1.1.6.2)                                                                        RET=$PLACE.1.1.1.6.2.0 ;;
        $PLACE.1.1.1.6.2.0|$PLACE.1.1.1.7|$PLACE.1.1.1.7.1)                                                         RET=$PLACE.1.1.1.7.1.0 ;;
        $PLACE.1.1.1.7.1.0|$PLACE.1.1.1.7.2)                                                                        RET=$PLACE.1.1.1.7.2.0 ;;
        $PLACE.1.1.1.7.2.0|$PLACE.1.1.1.8|$PLACE.1.1.1.8.1)                                                         RET=$PLACE.1.1.1.8.1.0 ;;
        $PLACE.1.1.1.8.1.0|$PLACE.1.1.1.8.2)                                                                        RET=$PLACE.1.1.1.8.2.0 ;;
        $PLACE.1.1.1.8.2.0|$PLACE.1.1.1.9|$PLACE.1.1.1.9.1)                                                         RET=$PLACE.1.1.1.9.1.0 ;;
        $PLACE.1.1.1.9.1.0|$PLACE.1.1.1.9.2)                                                                        RET=$PLACE.1.1.1.9.2.0 ;;
        $PLACE.1.1.1.9.2.0|$PLACE.1.1.1.10|$PLACE.1.1.1.10.1)                                                       RET=$PLACE.1.1.1.10.1.0 ;;
        $PLACE.1.1.1.10.1.0|$PLACE.1.1.1.10.2)                                                                      RET=$PLACE.1.1.1.10.2.0 ;;
        $PLACE.1.1.1.10.2.0|$PLACE.1.1.1.11|$PLACE.1.1.1.11.1)                                                      RET=$PLACE.1.1.1.11.1.0 ;;
        $PLACE.1.1.1.11.1.0|$PLACE.1.1.1.11.2)                                                                      RET=$PLACE.1.1.1.11.2.0 ;;
        $PLACE.1.1.1.11.2.0|$PLACE.1.1.1.12|$PLACE.1.1.1.12.1)                                                      RET=$PLACE.1.1.1.12.1.0 ;;
        $PLACE.1.1.1.12.1.0|$PLACE.1.1.1.12.2)                                                                      RET=$PLACE.1.1.1.12.2.0 ;;
        $PLACE.1.1.1.12.2.0|$PLACE.1.1.1.13|$PLACE.1.1.1.13.1)                                                      RET=$PLACE.1.1.1.13.1.0 ;;
        $PLACE.1.1.1.13.1.0|$PLACE.1.1.1.13.2)                                                                      RET=$PLACE.1.1.1.13.2.0 ;;
        $PLACE.1.1.1.13.2.0|$PLACE.1.1.1.14|$PLACE.1.1.1.14.1)                                                      RET=$PLACE.1.1.1.14.1.0 ;;
        $PLACE.1.1.1.14.1.0|$PLACE.1.1.1.14.2)                                                                      RET=$PLACE.1.1.1.14.2.0 ;;
        $PLACE.1.1.1.14.2.0|$PLACE.1.1.1.15|$PLACE.1.1.1.15.1)                                                      RET=$PLACE.1.1.1.15.1.0 ;;
        $PLACE.1.1.1.15.1.0|$PLACE.1.1.1.15.2)                                                                      RET=$PLACE.1.1.1.15.2.0 ;;
        $PLACE.1.1.1.15.2.0|$PLACE.1.1.1.16|$PLACE.1.1.1.16.1)                                                      RET=$PLACE.1.1.1.16.1.0 ;;
        $PLACE.1.1.1.16.1.0|$PLACE.1.1.1.16.2)                                                                      RET=$PLACE.1.1.1.16.2.0 ;;
        $PLACE.1.1.1.16.2.0|$PLACE.1.1.1.17|$PLACE.1.1.1.17.1)                                                      RET=$PLACE.1.1.1.17.1.0 ;;
        $PLACE.1.1.1.17.1.0|$PLACE.1.1.1.17.2)                                                                      RET=$PLACE.1.1.1.17.2.0 ;;
        $PLACE.1.1.1.17.2.0|$PLACE.1.1.1.18|$PLACE.1.1.1.18.1)                                                      RET=$PLACE.1.1.1.18.1.0 ;;
        $PLACE.1.1.1.18.1.0|$PLACE.1.1.1.18.2)                                                                      RET=$PLACE.1.1.1.18.2.0 ;;
        $PLACE.1.1.1.18.2.0|$PLACE.1.1.1.19|$PLACE.1.1.1.19.1)                                                      RET=$PLACE.1.1.1.19.1.0 ;;
        $PLACE.1.1.1.19.1.0|$PLACE.1.1.1.19.2)                                                                      RET=$PLACE.1.1.1.19.2.0 ;;
        $PLACE.1.1.1.19.2.0|$PLACE.1.1.1.20|$PLACE.1.1.1.20.1)                                                      RET=$PLACE.1.1.1.20.1.0 ;;
        $PLACE.1.1.1.20.1.0|$PLACE.1.1.1.20.2)                                                                      RET=$PLACE.1.1.1.20.2.0 ;;
        $PLACE.1.1.1.20.2.0|$PLACE.1.1.1.21|$PLACE.1.1.1.21.1)                                                      RET=$PLACE.1.1.1.21.1.0 ;;
        $PLACE.1.1.1.21.1.0|$PLACE.1.1.1.21.2)                                                                      RET=$PLACE.1.1.1.21.2.0 ;;
        $PLACE.1.1.1.21.2.0|$PLACE.1.1.1.22|$PLACE.1.1.1.22.1)                                                      RET=$PLACE.1.1.1.22.1.0 ;;
        $PLACE.1.1.1.22.1.0|$PLACE.1.1.1.22.2)                                                                      RET=$PLACE.1.1.1.22.2.0 ;;
        $PLACE.1.1.1.22.2.0|$PLACE.1.1.1.23|$PLACE.1.1.1.23.1)                                                      RET=$PLACE.1.1.1.23.1.0 ;;
        $PLACE.1.1.1.23.1.0|$PLACE.1.1.1.23.2)                                                                      RET=$PLACE.1.1.1.23.2.0 ;;
    #------------------------------ADVANCED RADIO SETTINGS--------------------------------
        $PLACE.1.1.1.15.2.0|$PLACE.2|$PLACE.2.1|$PLACE.2.1.1|$PLACE.2.1.1.1|$PLACE.2.1.1.1.1)                       RET=$PLACE.2.1.1.1.1.0 ;;
        $PLACE.2.1.1.1.1.0|$PLACE.2.1.1.1.2)                                                                        RET=$PLACE.2.1.1.1.2.0 ;;
        $PLACE.2.1.1.1.2.0|$PLACE.2.1.1.2|$PLACE.2.1.1.2.1)                                                         RET=$PLACE.2.1.1.2.1.0 ;;
        $PLACE.2.1.1.2.1.0|$PLACE.2.1.1.2.2)                                                                        RET=$PLACE.2.1.1.2.2.0 ;;
        $PLACE.2.1.1.2.2.0|$PLACE.3|$PLACE.3.1)                                                                     RET=$PLACE.3.1.0 ;;
    #--------------------------------OPEN MESH SETTINGS-----------------------------------
        $PLACE.3.1.0|$PLACE.3.2)                                                                                    RET=$PLACE.3.2.0 ;;
        $PLACE.3.2.0|$PLACE.3.3)                                                                                    RET=$PLACE.3.3.0 ;;
        $PLACE.3.3.0|$PLACE.3.4)                                                                                    RET=$PLACE.3.4.0 ;;
        $PLACE.3.4.0|$PLACE.3.5)                                                                                    RET=$PLACE.3.5.0 ;;
        $PLACE.3.5.0|$PLACE.3.6)                                                                                    RET=$PLACE.3.6.0 ;;
        $PLACE.3.6.0|$PLACE.3.7)                                                                                    RET=$PLACE.3.7.0 ;;
    #----------------------------------VLAN SETTINGS--------------------------------------
        $PLACE.3.7.0|$PLACE.4|$PLACE.4.1\
            |$PLACE.4.1.1|$PLACE.4.1.1.1|$PLACE.4.1.1.1.1)                                                          RET=$PLACE.4.1.1.1.1.0 ;;
        $PLACE.4.1.1.1.$user_num.0|$PLACE.4.1.1.1.$((user_num-1)))
            [ $user_num -lt 16 ] && RET=$PLACE.4.1.1.1.$((user_num+1)).0 || exit ;;
        *)                                                                          exit 0 ;;
    esac
else
    case "$REQ" in
    $PLACE)    exit 0 ;;
    *)         RET=$REQ ;;
    esac
fi

radio_num="$(($(echo $RET | cut -d "." -f 18)-1))"

 #Get or Set
function err_wrong_type() {
    echo "wrong-type"
    exit
}

function err_not_writeable() {
    echo "not-writeable"
    exit
}

function err_wrong_length() {
    echo "wrong-length"
    exit
}

function err_wrong_value() {
    echo "wrong-value"
    exit
}

function rename_rf() {
    local iface_cnt=$(uci show wireless | grep wifi-iface | grep $radio_num)

    for iface_in_cnt in $iface_cnt; do
        local cnt=${iface_in_cnt%=*}
        uci rename $cnt=${cnt#*.}
    done
}

function rename_usteer() {
    uci del usteer.@usteer[0].ssid_list
    local lists=$(uci show wireless | grep ssid | grep radio$radio_num | cut -d "=" -f 1)
    for list in $lists; do
        local name=$(uci get $list)
        uci add_list usteer.@usteer[0].ssid_list="$name"
    done
}
#------------------------------------RF Settings-------------------------------------
#------------------------------PHYSICAL RADIO SETTINGS-------------------------------
function write_APRFRadioStatus() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num.disabled="$((2-WRITE_VALUE))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFMode() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    case "$WRITE_VALUE" in
        1)
            uci set wireless.radio$radio_num.mode="ap"
            uci set wireless.radio$radio_num.wds="1"
            uci set wireless.radio$radio_num\_1.wds="1"
            uci set wireless.radio$radio_num\_1.mode="ap"
            ;;
        2)
            uci set network.wan.inet_src="wlan$radio_num"
            uci set wireless.radio$radio_num.mode="sta"
            uci del wireless.radio$radio_num.wds
            uci del wireless.radio$radio_num.channels
            local country=$(uci get wireless.radio$radio_num.country)
            local mode=$(uci get wireless.radio$radio_num.htmode 2>/dev/null | grep -o -E '[0-9]+')
            local hz=$(/sbin/dump_reg_chan.sh 5 US | grep mode | cut -d ":" -f 2 | cut -d "," -f 1 | sed 's/"//g')
            local chl=$(/sbin/dump_reg_chan.sh 5 US | grep chan | cut -d ":" -f 2 | cut -d "," -f 1)
            local cnt=0
            local value=""

            for i in $hz; do
                cnt=$((cnt+1))
                if [ "$i" -eq "$mode" ]; then
                    value=$value,$(echo $chl | cut -d " " -f $cnt)
                fi
            done

            uci set wireless.radio$radio_num.channels="$(echo $value | sed 's/,//1')"
            [ "$radio_num" -eq 1 ] && uci set wireless.radio1._ofdma="1"
            [ -n "$(uci show wireless.wmesh | grep mode)" ] && uci del wireless.wmesh.mode
            [ -n "$(uci show wireless.wmesh | grep mesh_id)" ] && uci del wireless.wmesh.mesh_id
            [ -n "$(uci show wireless.wmesh | grep network_name)" ] && uci set wireless.wmesh.network_name="lan"
            local ifaces=$(iwinfo |grep ESSID | awk '{print $1}'| grep wlan$radio_num)

            for iface in $ifaces; do
                if [ "$iface" == "wlan$radio_num" ]; then
                    uci set wireless.radio$radio_num\_1.mode="sta"
                    uci del wireless.radio$radio_num\_1.wds
                    uci set wireless.radio$radio_num\_1.wmm="1"
                else
                    local id=$(($(echo $i | cut -d "-" -f 2)+1))
                    uci set wireless.radio$radio_num\_$id.disabled="1"
                    uci set wireless.radio$radio_num\_$id.wmm="1"
                fi
            done
            ;;
        *)  err_wrong_value ;;
    esac
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRF80211Mode() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    
    case "$WRITE_VALUE" in
        1)      [ "$radio_num" -eq 0 ] && hwmode="11a" || err_wrong_value ;;
        2)      [ "$radio_num" -eq 0 ] && hwmode="11na" || err_wrong_value ;;
        3)      [ "$radio_num" -eq 0 ] && hwmode="11ac" || err_wrong_value ;;
        4)      [ "$radio_num" -eq 1 ] && hwmode="11ng" || err_wrong_value ;;
        5)      [ "$radio_num" -eq 0 ] && hwmode="11axa"
                [ "$radio_num" -eq 1 ] && hwmode="11axg" || err_wrong_value ;;
        *)      err_wrong_value ;;
    esac
    
    local htmode="$(uci get wireless.radio$radio_num.htmode)"
    
    if [ "$radio_num" -eq 0 ]; then
        [ "$WRITE_VALUE" -eq 1 ] && htmode="HT20"
        [ "$WRITE_VALUE" -eq 2 ] && [ "${htmode:0-2:2}" -eq 80 ]\
            && htmode="HT20" || htmode="HT${hwmode:0-2:2}"
        [ "$WRITE_VALUE" -eq 3 ] && htmode="VHT${htmode:0-2:2}"
        [ "$WRITE_VALUE" -eq 5 ] && htmode="HE${htmode:0-2:2}"
    elif [ "$radio_num" -eq 1 ]; then
        [ "$WRITE_VALUE" -eq 4 ] && htmode="HT${htmode:0-2:2}"
        [ "$WRITE_VALUE" -eq 5 ] && htmode="HE${htmode:0-2:2}"
    fi

    uci set wireless.radio$radio_num.hwmode="$hwmode"
    uci set wireless.radio$radio_num.htmode="$htmode"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFChannelBandwidth() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    local hwmode="$(uci get wireless.radio$radio_num.hwmode)"

    case "$hwmode" in
        11a|11na|11ng)      htmode="HT" ;;
        11ac)               htmode="VHT" ;;
        11axa|11axg)        htmode="HE" ;;
    esac

    case "$WRITE_VALUE" in
        1)     value=$htmode\20 ;;
        2)     value=$htmode\40 ;;
        3)     [ "$radio_num" -eq 0 ] && value=$htmode\80 || err_wrong_value ;;
        *)      err_wrong_value ;;
    esac

    uci set wireless.radio$radio_num.htmode="$value"
    [ "$radio_num" -eq 1 ] && [ "$WRITE_VALUE" -eq 20 ] && \
        uci set wireless.radio1.noscan="0" || wireless.radio1.noscan="1"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFChannel() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci set wireless.radio$radio_num.channel="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFWMEBestEffort() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci set wireless.radio$radio_num.wme_0="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFWMEBackground() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci set wireless.radio$radio_num.wme_1="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFWMEVoice() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci set wireless.radio$radio_num.wme_3="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFWMEVideo() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    uci set wireless.radio$radio_num.wme_2="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFBeaconInterval() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "100" ] || [ "$WRITE_VALUE" -gt "1024" ] && err_wrong_value
    uci set wireless.radio$radio_num.beacon_int="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFMinSignalAllowed() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "0" ] || [ "$WRITE_VALUE" -gt "99" ] && err_wrong_value
    local iface_cnt=$(uci show wireless | grep wifi-iface | grep $radio_num)

    for iface_in_cnt in $iface_cnt; do
        uci set wireless.radio$radio_num.min_signal_allowed="$WRITE_VALUE"
        local cnt=${iface_in_cnt%=*}

        if [ "$WRITE_VALUE" -eq 0 ]; then
            uci set $cnt.signal_stay="-128"
            uci set $cnt.signal_connect="-128"
        else
            uci set $cnt.signal_stay="$((WRITE_VALUE-100))"
            uci set $cnt.signal_connect="$((WRITE_VALUE-100))"
        fi
    done

    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APRFBSScoloring() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "0" ] || [ "$WRITE_VALUE" -gt "64" ] && err_wrong_value
    uci set wireless.radio$radio_num.he_bss_color="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APRFTargetWakeTime() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    uci set wireless.radio$radio_num.he_twt_required="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APSSIDMultiBroadcastRate() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "10" ] && err_wrong_value
    case "$WRITE_VALUE" in
        1)      value=6000 ;;
        2)      value=9000 ;;
        3)      value=12000 ;;
        4)      value=18000 ;;
        5)      value=24000 ;;
        6)      value=36000 ;;
        7)      value=48000 ;;
        8)      value=54000 ;;
        9)      [ "$radio_num" -eq 1 ] && value=5500 || err_wrong_value ;;
        10)      [ "$radio_num" -eq 1 ] && value=11000 || err_wrong_value ;;
    esac
    uci set wireless.radio$radio_num.basic_rate="$value"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APRFBandsteering() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    if [ "$WRITE_VALUE" -eq "2" ]; then
        uci set usteer.@usteer[0].enabled="1"
        uci set usteer.@usteer[0].network="wan"
        uci set usteer.@usteer[0].min_snr="-75"
        uci set usteer.@usteer[0].assoc_steering="1"
        uci set usteer.@usteer[0].min_connect_snr="-70"
        uci set usteer.@usteer[0].roam_scan_snr="-85"
        rename_usteer
    else
        uci set usteer.@usteer[0].enabled="0"
        uci del usteer.@usteer[0].network
        uci del usteer.@usteer[0].min_snr
        uci del usteer.@usteer[0].assoc_steering
        uci del usteer.@usteer[0].min_connect_snr
        uci del usteer.@usteer[0].roam_scan_snr
        uci del usteer.@usteer[0].ssid_list
    fi
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
write_APRFInterferenceDetection() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "0" ] || [ "$WRITE_VALUE" -gt "99" ] && err_wrong_value
    uci set wireless.radio$radio_num.chan_util_delta="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APRFAirtimeFairness() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    if [ "$WRITE_VALUE" -eq "2" ]; then
        uci set atfpolicy.@defaults[0].enabled="1"
        uci set atfpolicy.@defaults[0].vo_queue_weight="4"
        uci set atfpolicy.@defaults[0].update_pkt_threshold="100"
        uci set atfpolicy.@defaults[0].bulk_percent_thresh="50"
        uci set atfpolicy.@defaults[0].prio_percent_thresh="30"
        uci set atfpolicy.@defaults[0].weight_normal="256"
        uci set atfpolicy.@defaults[0].weight_bulk="128"
        uci set atfpolicy.@defaults[0].weight_prio="384"
    else
        uci set atfpolicy.@defaults[0].enabled="0"
        uci del atfpolicy.@defaults[0].vo_queue_weight
        uci del atfpolicy.@defaults[0].update_pkt_threshold
        uci del atfpolicy.@defaults[0].bulk_percent_thresh
        uci del atfpolicy.@defaults[0].prio_percent_thresh
        uci del atfpolicy.@defaults[0].weight_normal
        uci del atfpolicy.@defaults[0].weight_bulk
        uci del atfpolicy.@defaults[0].weight_prio
    fi
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
#------------------------------get info-----------------------------------------------
function get_rate() {
    local dir="$1"
    local final_bps="0"
    local result=""
    local unit=""

    local gb_mul=$((1000**3))
	local mb_mul=$((1000**2))
	local kb_mul=$((1000**1))

    local final_bps=$(/usr/sbin/snmp_download_rate.sh "$dir" "$radio_num")
    # assign appropriate unit
	if [ "$final_bps" -ge "$gb_mul" ]; then
		result="$(printf "%.2f\n" $((10**2 * final_bps/gb_mul))e-2)"
		unit="Gb/s"
	elif [ "$final_bps" -ge "$mb_mul" ]; then
		result="$(printf "%.2f\n" $((10**2 * final_bps/mb_mul))e-2)"
		unit="Mb/s"
	elif [ "$final_bps" -ge "$kb_mul" ]; then
		result="$(printf "%.2f\n" $((10**2 * final_bps/kb_mul))e-2)"
		unit="kb/s"
	else
		result="$final_bps"
		unit="b/s"
	fi

	value="$result $unit"
    echo "$value"
}
#------------------------------ADVANCED RADIO SETTINGS--------------------------------
function write_APRFTxPower() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    local cnt=0
    local hz=$(/sbin/dump_reg_chan.sh 5 US | grep mode | cut -d ":" -f 2 | cut -d "," -f 1 | sed 's/"//g')
    local channel=$(/sbin/dump_reg_chan.sh 5 US | grep chan | cut -d ":" -f 2 | cut -d "," -f 1)
    local max_tx=$(/sbin/dump_reg_chan.sh 5 US | grep max | cut -d ":" -f 2 | cut -d "," -f 1)
    local mode="$(uci get wireless.radio$radio_num.htmode)"
    mode="${mode:0-2:2}"
    local select_chnl=$(uci get wireless.radio$radio_num.channel)
    [ "$select_chnl" == "auto" ] && select_chnl=$(uci get wireless.radio$radio_num.channels | sed 's/,/ /g')

    for i in $hz; do
        cnt=$((cnt+1))

        if [ "$i" -eq "$mode" ]; then
            local chnl=$(echo $channel | cut -d " " -f $cnt)

            for j in $select_chnl; do
                if [ "$j" -eq "$chnl" ]; then
                    new_txpwr=$(echo $max_tx | cut -d " " -f $cnt)

                    if [ -n "$txpwr" ]; then
                        if [ "$new_txpwr" -lt "$txpwr" ]; then
                            txpwr=$new_txpwr
                        fi
                    else
                        txpwr="$new_txpwr"
                    fi
                fi
            done
        fi
    done

    [ "$WRITE_VALUE" -lt "3" ] || [ "$WRITE_VALUE" -gt "$txpwr" ] && err_wrong_value
    uci set wireless.radio$radio_num.txpower="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APRFSGI() {
    local hwmode=$(uci -q get wireless.radio$radio_num.hwmode)
    [ "$hwmode" != "11ac" ] && [ "$hwmode" != "11ng" ] && err_not_writeable
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "2" ] && err_wrong_value
    uci set wireless.radio$radio_num.sgi="$((WRITE_VALUE-1))"
    uci set wireless.radio$radio_num.short_gi_20="$((WRITE_VALUE-1))"
    uci set wireless.radio$radio_num.short_gi_40="$((WRITE_VALUE-1))"
    uci set wireless.radio$radio_num.short_gi_80="$((WRITE_VALUE-1))"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
#--------------------------------OPEN MESH SETTINGS-----------------------------------
function write_APRFMeshPoint() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    if [ "$WRITE_VALUE" -eq "1" ]; then
        uci set network.wan.ifname="eth0"
        uci set wireless.wmesh.disabled="1"
        uci del wireless.wmesh.mode
        uci set wireless.wmesh.device="nil"
        uci del wireless.wmesh.mesh_id
    else
        uci set network.wan.ifname="eth0 bat0"
        uci set wireless.wmesh.disabled="0"
        uci set wireless.wmesh.mode="mesh"
        uci set wireless.wmesh.device="radio$radio_num"
        uci set wireless.wmesh.mesh_id="openmesh"
    fi
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFMeshId() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    [ "${#WRITE_VALUE}" -lt "1" ] || [ "${#WRITE_VALUE}" -gt "200" ] && err_wrong_value
    uci set wireless.wmesh.mesh_id="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFMeshMethod() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    
    if [ "$WRITE_VALUE"-eq "1" ]; then
        uci set wireless.wmesh.encryption="none"
    else
        uci del wireless.wmesh.key
        uci set wireless.wmesh.encryption="sae"
        uci set wireless.wmesh.key="12345678"
    fi
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFMeshKey() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "8" ] || [ "$WRITE_VALUE" -gt "64" ] && err_wrong_value
    uci set wireless.wmesh.key="$WRITE_VALUE"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFNetworkBehavior() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] && err_wrong_value
	local wan_devs=$(uci -q get network.wan.ifname)
	local lan_devs=$(uci -q get network.lan.ifname)
    if [ "$WRITE_VALUE" -eq 1 ]; then
        if [ "$(echo $wan_devs | grep bat0)" == "" ]; then
            uci set network.wan.ifname="${wan_devs} bat0"
        fi

        if [ "$(echo $lan_devs | grep bat0)" != "" ]; then
            uci set network.lan.ifname="$(echo $lan_devs | sed -e 's/bat0//g')"
        fi
        uci set wireless.wmesh.network_behavior="bridge"
    elif [ "$WRITE_VALUE" -eq 2 ]; then
        if [ "$(echo $lan_devs | grep bat0)" == "" ]; then
            uci set network.lan.ifname="${lan_devs} bat0"
        fi

        if [ "$(echo $wan_devs | grep bat0)" != "" ]; then
            uci set network.wan.ifname="$(echo $wan_devs | sed -e 's/bat0//g')"
        fi
        uci set network.wan.ifname="eth0"
        uci set wireless.wmesh.encryption="none"
        uci set wireless.wmesh.network_behavior="route"
        uci set wireless.wmesh.network_name="lan"
    fi
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}

function write_APRFNetworkName() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -ne "1" ] && [ "$WRITE_VALUE" -ne "2" ] && err_wrong_value
    case "$WRITE_VALUE" in
        1)      value="lan" ;;
        *)      err_wrong_value ;;
    esac
    uci set wireless.wmesh.network_name="$value"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
function write_APRFMeshDevice() {
    [ "$WRITE_TYPE" != "integer" ] && err_wrong_type
    [ "$WRITE_VALUE" -lt "1" ] || [ "$WRITE_VALUE" -gt "2" ] && err_wrong_value
    case "$WRITE_VALUE" in
        1)      value="radio0" ;;
        2)      value="radio1" ;;
        *)      err_wrong_value ;;
    esac
    uci set wireless.wmesh.device="$value"
    rename_rf
    [ "$(uci get usteer.@usteer[0].enabled)" -eq 1 ] && rename_usteer
    exit
}
#-----------------------------------VLAN SETTINGS-------------------------------------
function write_APRFVlanSettings() {
    [ "$WRITE_TYPE" != "string" ] && err_wrong_type
    local id=$(echo $WRITE_VALUE | cut -d "," -f 1)
    local port=$(echo $WRITE_VALUE | awk '{print $2,$3,$4,$5,$6}')
    local chk=$(uci show network | grep "\.vlan" | grep ifname | cut -d "." -f 4 | awk '{print $1}' | grep -w $id)
    [ "$id" -lt "2" ] || [ "$id" -gt "4094" ] && err_wrong_value
    [ -n "$chk" ] && err_wrong_value

    for i in $port; do
        case "$i" in
            eth0)               ;;
            eth1|eth2)
                case "$product_name" in
                    EAP104) err_wrong_value ;;
                esac
                ;;
            lan1|lan2|lan3|lan4)
                case "$product_name" in
                    EAP104)     ;;
                    *) err_wrong_value ;;
                esac
                ;;
            *)  err_wrong_value ;;
        esac
    done

    local ifaces=$(uci show network| grep "\.vlan" | grep interface)
    for iface in $ifaces; do
        uci set $iface
    done
    case "$product_name" in
        EAP101) num_start=3 ;;
        EAP102) num_start=2 ;;
        EAP104) num_start=5 ;;
    esac

    local num=$(($(echo $RET_OID | cut -d "." -f 18)+$num_start))

    case "$product_name" in
        EAP104)
            local new_ports=""
            local lan_vids="6t"
            for i in $port; do
                if [ "${i:0:3}" = "eth" ]; then
                    new_ports="$i"
				elif [ "${i:0:3}" = "lan" ]; then
                    local lan_vid=$(uci -q get network.dev_${i}.vid)
                    local lan_ifname=$(uci -q get network.dev_${i}.ifname)
                    lan_vids="$lan_vids ${lan_vid}t"

                    if [ "$(echo $new_ports | grep $lan_ifname)" = "" ]; then
                        if [ ${#new_ports} -gt 0]; then
                            new_ports="$new_ports "
                        fi
                        new_ports="$new_ports $lan_ifname"
                    fi
                fi
            done
            port=$new_ports
            uci -q set network.svlan_vlan$num="switch_vlan"
            uci -q set network.svlan_vlan$num.device="switch1"
            uci -q set network.svlan_vlan$num.vlan="$id"
            uci -q set network.svlan_vlan$num.ports="$lan_vids"
            ;;
    esac

    local port_string=$(echo $(echo $port | sed 's/ /.'$id' /g').$id)
    port_string=$(echo $port_string | sed "s/$(echo $port_string | awk '{print $1}')/$(echo $port_string | awk '{print $1}') bat0.$id/1")

    uci set network.vlan$num=interface
    uci set network.vlan$num.vlan_net="1"
    uci set network.vlan$num.ifname="$port_string"
    uci set network.vlan$num.type="bridge"
    uci set network.vlan$num.proto="none"
    exit
}

function output() {
    local RET_OID="$1"
    case "$RET_OID" in
#------------------------------PHYSICAL RADIO SETTINGS-------------------------------
        $PLACE.1.1.1.1.*) #APRFRadioStatus
            [ "$OP" == "-s" ] && write_APRFRadioStatus
            value="$((2-$(uci get wireless.radio$radio_num.disabled)))"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.2.*) #APRFMode
            [ "$OP" == "-s" ] && write_APRFMode
            local mode="$(uci get wireless.radio$radio_num.mode)"
            case "$mode" in
                ap)             value=1 ;;
                sta)            value=2 ;;
            esac
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.3.*) #APRF80211Mode
            [ "$OP" == "-s" ] && write_APRF80211Mode
            local hwmode="$(uci get wireless.radio$radio_num.hwmode)"
            case "$hwmode" in
                11a)            value=1 ;;
                11na)           value=2 ;;
                11ac)           value=3 ;;
                11ng)           value=4 ;;
                11axa|11axg)    value=5 ;;
            esac
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.4.*) #APRFChannelBandwidth
            [ "$OP" == "-s" ] && write_APRFChannelBandwidth
            local htmode="$(uci get wireless.radio$radio_num.htmode)"
            local ht="${htmode:0-2:2}"
            case "$ht" in
                20)     value=1 ;;
                40)     value=2 ;;
                80)     value=3 ;;
            esac
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.5.*) #APRFChannel
            [ "$OP" == "-s" ] && write_APRFChannel
            value="$(uci get wireless.radio$radio_num.channel)"
            [ "$value" == "auto" ] && value="$(uci get wireless.radio$radio_num.channels)"
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.1.1.6.*) #APRFWMEBestEffort
            [ "$OP" == "-s" ] && write_APRFWMEBestEffort
            local chk=$(uci show wireless.radio$radio_num | grep wme_0)
            [ -n "$chk" ] && value="$(uci get wireless.radio$radio_num.wme_0)" || value="0"
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.1.1.7.*) #APRFWMEBackground
            [ "$OP" == "-s" ] && write_APRFWMEBackground
            local chk=$(uci show wireless.radio$radio_num | grep wme_1)
            [ -n "$chk" ] && value="$(uci get wireless.radio$radio_num.wme_1)" || value="0"
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.1.1.8.*) #APRFWMEVoice
            [ "$OP" == "-s" ] && write_APRFWMEVoice
            local chk=$(uci show wireless.radio$radio_num | grep wme_3)
            [ -n "$chk" ] && value="$(uci get wireless.radio$radio_num.wme_3)" || value="0"
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.1.1.9.*) #APRFWMEVideo
            [ "$OP" == "-s" ] && write_APRFWMEVideo
            local chk=$(uci show wireless.radio$radio_num | grep wme_2)
            [ -n "$chk" ] && value="$(uci get wireless.radio$radio_num.wme_2)" || value="0"
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.1.1.10.*) #APRFBeaconInterval
            [ "$OP" == "-s" ] && write_APRFBeaconInterval
            value="$(uci get wireless.radio$radio_num.beacon_int)"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.11.*) #APRFMinSignalAllowed
            [ "$OP" == "-s" ] && write_APRFMinSignalAllowed
            local chk=$(uci show wireless.radio$radio_num | grep min_signal_allowed)
            [ -n "$chk" ] && value="$(uci get wireless.radio$radio_num.min_signal_allowed)" || value="0"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.12.*) #APRFBSScoloring
            [ "$OP" == "-s" ] && write_APRFBSScoloring
            local chk=$(uci show wireless.radio$radio_num | grep he_bss_color)
            [ -n "$chk" ] && value="$(uci get wireless.radio$radio_num.he_bss_color)" || value="0"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.13.*) #APRFTargetWakeTime
            [ "$OP" == "-s" ] && write_APRFTargetWakeTime
            local chk=$(uci show wireless.radio$radio_num | grep he_twt_required)
            [ -n "$chk" ] && value="$(($(uci get wireless.radio$radio_num.he_twt_required)+1))" || value="0"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.14.*) #APRFBandsteering
            [ "$OP" == "-s" ] && write_APRFBandsteering
            local chk=$(uci show usteer.@usteer[0] | grep enabled)
            [ -n "$chk" ] && value="$(($(uci get usteer.@usteer[0].enabled)+1))" || value="0"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.15.*) #APSSIDMultiBroadcastRate
            [ "$OP" == "-s" ] && write_APSSIDMultiBroadcastRate
            value="$(uci -q get wireless.radio$radio_num.basic_rate)"
            case "$value" in
                6000)       value=1 ;;
                9000)       value=2 ;;
                12000)      value=3 ;;
                18000)      value=4 ;;
                24000)      value=5 ;;
                36000)      value=6 ;;
                48000)      value=7 ;;
                54000)      value=8 ;;
                5500)       value=9 ;; #only for 2.4G
                11000)      value=10 ;; #only for 2.4G
                *)
                    local band=$(uci -q get wireless.radio$radio_num.band)
                    [ "$band" == "5g" ] && value=1 || value=9 ;;
            esac
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.16.*) #APRFInterferenceDetection
            [ "$OP" == "-s" ] && write_APRFInterferenceDetection
            local chk=$(uci show wireless.radio$radio_num | grep chan_util_delta)
            [ -n "$chk" ] && value="$(uci get wireless.radio$radio_num.chan_util_delta)" || value="0"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.17.*) #APRFAirtimeFairness
            [ "$OP" == "-s" ] && write_APRFAirtimeFairness
            local chk=$(uci show atfpolicy.@defaults[0] | grep enabled)
            [ -n "$chk" ] && value="$(($(uci get atfpolicy.@defaults[0].enabled)+1))" || value="0"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.18.*) #APRFClientDownloadRate (in b/s)
            stat_file="/sys/class/net/wlan$radio_num/statistics/rx_bytes"
            if [ -f "${stat_file}" ]; then
                local chk=$(cat /sys/class/net/wlan$radio_num/statistics/rx_bytes)
                [ -n "$chk" ] && {
                    value=$(get_rate download)
                } || value="0 b/s"
            else
                value="0 b/s"
            fi
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.1.1.19.*) #APRFClientUploadRate (in b/s)
            stat_file="/sys/class/net/wlan$radio_num/statistics/tx_bytes"
            if [ -f "${stat_file}" ]; then
                local chk=$(cat /sys/class/net/wlan$radio_num/statistics/tx_bytes)
                [ -n "$chk" ] && {
                    value=$(get_rate upload)
                } || value="0 b/s"
            else
                value="0 b/s"
            fi
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.1.1.1.20.*) #APRFChannelUtilization (in %)
            local chk=/sys/class/net/wlan$radio_num
            [ -d "$chk" ] && {
                iface_survey=$(iw wlan$radio_num survey dump | grep 'in use' -A 5)
                channel_active=$(echo "$iface_survey" | grep "channel active time:" | awk '{print $4}')
                [ -z "$channel_active" ] && channel_active=1
                channel_busy=$(echo "$iface_survey" | grep "channel busy time:" | awk '{print $4}')
                value=$((100*$channel_busy/$channel_active))
            } || value="0"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.21.*) #APRFRadioUtilization (in %)
            local chk=/sys/class/net/wlan$radio_num
            [ -d "$chk" ] && {
                iface_survey=$(iw wlan$radio_num survey dump | grep 'in use' -A 5)
                channel_active=$(echo "$iface_survey" | grep "channel active time:" | awk '{print $4}')
                [ -z "$channel_active" ] && channel_active=1
                rx_busy=$(echo "$iface_survey" | grep "channel receive time:" | awk '{print $4}')
                tx_busy=$(echo "$iface_survey" | grep "channel transmit time:" | awk '{print $4}')
                rx_percent=$((100*$rx_busy/$channel_active))
                tx_percent=$((100*$tx_busy/$channel_active))
                value=$(($rx_percent+$tx_percent+1))
            } || value="0"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.22.*) #APRFNumberOfClients
            counter="0"
            for iface in $(ubus call network.wireless status | jsonfilter -e "@.radio$radio_num.interfaces" | jsonfilter -e "@[*].ifname"); do
                client_mac=$(ubus call iwinfo assoclist '{"device":"'$iface'"}' | jsonfilter -e "@.results" | jsonfilter -e "@[*].mac")
                if [ "$client_mac" == "" ]; then
                    client_count="0"
                else
                    client_count=$(echo "$client_mac" | wc -l)
                fi
                counter=$(($counter+$client_count))
            done
            value=$counter
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.1.1.1.23.*) #APRFCurrentChannel
            local chk=/sys/class/net/wlan$radio_num
            [ -d "$chk" ] && {
                current_channel=$(ubus call iwinfo info '{"device":"wlan'$radio_num'"}' | jsonfilter -e "@.channel")
                if [ "$current_channel" == "" ]; then
                    value="0"
                else
                    value="$current_channel"
                fi
            } || value="0"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
#------------------------------ADVANCED RADIO SETTINGS--------------------------------
        $PLACE.2.1.1.1.*) #APRFTxPower
            [ "$OP" == "-s" ] && write_APRFTxPower
            value="$(uci get wireless.radio$radio_num.txpower)"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.2.1.1.2.*) #APRFSGI
            [ "$OP" == "-s" ] && write_APRFSGI
            value="$(uci -q get wireless.radio$radio_num.sgi)"
            [ -n "$value" ] && value=$((value+1))
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
#--------------------------------OPEN MESH SETTINGS-----------------------------------
        $PLACE.3.1.0) #APRFMeshPoint
            [ "$OP" == "-s" ] && write_APRFMeshPoint
            value="$((2-$(uci get wireless.wmesh.disabled)))"
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.2.0) #APRFMeshId
            [ "$OP" == "-s" ] && write_APRFMeshId
            local mesh=$(uci get wireless.wmesh.disabled)
            [ "$mesh" -eq 0 ] && value="$(uci get wireless.wmesh.mesh_id)" || value=""
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.3.3.0) #APRFMeshMethod
            [ "$OP" == "-s" ] && write_APRFMeshMethod
            local chk=$(uci show wireless.wmesh | grep encryption)
            if [ -n "$chk" ]; then
                local method=$(uci get wireless.wmesh.encryption)
                case "$method" in
                    none)   value=1 ;;
                    sae)    value=2 ;;
                    *)      value="" ;;
                esac
            fi
            
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.4.0) #APRFMeshKey
            [ "$OP" == "-s" ] && write_APRFMeshKey
            local chk=$(uci show wireless.wmesh | grep key)
            [ -n "$chk" ] && value="$(uci get wireless.wmesh.key)" || value=""
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        $PLACE.3.5.0) #APRFNetworkBehavior
            [ "$OP" == "-s" ] && write_APRFNetworkBehavior
            local mesh=$(uci get wireless.wmesh.disabled)

            if [ "$mesh" -eq 0 ]; then
                local behavior_chk=$(uci show wireless | grep wmesh | grep network_behavior)
                if [ -n "$behavior_chk" ]; then
                    local behavior=$(uci get wireless.wmesh.network_behavior)
                    [ "$behavior" == "bridge" ] && value="1" || value="2"
                fi
            else
                value=""
            fi
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.6.0) #APRFNetworkName
            [ "$OP" == "-s" ] && write_APRFNetworkName
            local mesh=$(uci get wireless.wmesh.disabled)

            if [ "$mesh" -eq 0 ]; then
                local behavior_chk=$(uci show wireless | grep wmesh | grep network_behavior)
                if [ -n "$behavior_chk" ]; then
                    local behavior=$(uci get wireless.wmesh.network_behavior)
                    [ "$behavior" == "route" ] && value="$(uci get wireless.wmesh.network_name)" || value=""
                fi
            else
                value=""
            fi

            case "$value" in
                lan)    value=1 ;;
                *)      value="" ;;
            esac
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
        $PLACE.3.7.0) #APRFMeshDevice
            [ "$OP" == "-s" ] && write_APRFMeshDevice
            local chk=$(uci show wireless | grep wmesh | grep device)
            [ -n "$chk" ] && device="$(uci get wireless.wmesh.device)"
            
            case "$device" in
                radio0)     value=1 ;;
                radio1)     value=2 ;;
                *)          value="" ;;
            esac
            echo "$RET_OID"
            echo "integer"; echo $value; exit 0 ;;
#-----------------------------------VLAN SETTINGS-------------------------------------
        $PLACE.4*) #APRFVlanSettings
            [ "$OP" == "-s" ] && write_APRFVlanSettings
            case "$product_name" in
                EAP101) num_start=3 ;;
                EAP102) num_start=2 ;;
                EAP104) num_start=5 ;;
            esac
            num=$(($(echo $RET_OID | cut -d "." -f 18)+$num_start))
            chk=$(uci show network | grep vlan$num | grep ifname)
            value=""
            if [ -n "$chk" ]; then
                ports=$(uci get network.vlan$num.ifname)
                port=""
                for i in $ports; do
                    if [ "${i:0:3}" != "bat" ]; then
                        case "$product_name" in
                            EAP104)
                                local lan_ifname=$(uci -q get network.dev_lan1.ifname)
                                if [ "${i:0:4}" = "$lan_ifname" ]; then
                                    local lan_vlan_ports=$(uci -q get network.svlan_vlan$num.ports)
                                    for vlan_port in $lan_vlan_ports; do
                                        if [ "$vlan_port" != "6t" ]; then
                                            local lan_vid=$(echo $vlan_port | sed 's/.$//')

                                            for j in 1 2 3 4; do
                                                if [ "$(uci -q get network.dev_lan$j.vid)" = "$lan_vid" ]; then
                                                    port="$port $(uci get network.dev_lan$j.name)"
                                                    break;
                                                fi
                                            done
                                        fi
                                    done
                                else
                                    port="$port $(echo $i | cut -d "." -f 1)"
                                fi
                                ;;
                            *)
                                port="$port $(echo $i | cut -d "." -f 1)"
                                ;;
                        esac
                    fi
                done
                value="$(uci get network.vlan$num.ifname | awk '{print $2}' | cut -d "." -f 2), $port"
            fi
            echo "$RET_OID"
            echo "string"; echo $value; exit 0 ;;
        *) echo "string"; echo "ack... $RET_OID $REQ"; exit 0 ;;
    esac
}
output $RET

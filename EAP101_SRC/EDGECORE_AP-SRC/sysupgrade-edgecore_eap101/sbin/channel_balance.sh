#!/bin/sh

. /lib/functions.sh

DEVS="wlan0 wlan1"
chan_changeTS_file="tmp/chan_chang_TS_"
jump_cooldown="3600" #second
delay_interval="20" #second
Magic_num="23"

#CHANLIST_2G with no overlay
#CHANLIST_5G with no dfs
CHANLIST_2G="1 2 3 4 5 6 7 8 9 10 11 12 13"
CHANLIST_5G_bw20="36 40 44 48 149 153 157 161 165"
CHANLIST_5G_bw40="36 44 149 157"
CHANLIST_5G_bw80="36 149"

#===========crontab part===========
SCRIPT=$0
CHAN_UTILS=/tmp/chan_utils_
LOGFILE="/tmp/log/channel_balance.log"
LOGGING=0 #default is off
debug_flag=0
period="10" #minutes

_log() {
    if [ ${LOGGING} -eq 1 ]; then
        local ts=$(date)
        echo "$ts $@" >> ${LOGFILE}
    fi

    if [ ${debug_flag} -eq 1 ]; then
        logger -p debug -t daemon.debug "$@"
    fi
}

_add_cron_script() {
    (crontab -l ; echo "$1") | sort | uniq | crontab -
}

_rm_cron_script() {
    crontab  -l | grep -v "$1" |  sort | uniq | crontab -
}

add_cron_entries() {
  cmd="*/"${period}" * * * * "${SCRIPT}" start"
  _log "[Add] add cron rule: ${cmd}"
  _add_cron_script "$cmd"
}

start_get_chan_utils() {
    if [ -z "$(ps ww | grep get_chan_utils.sh | grep -v grep)" ]; then
        /sbin/get_chan_utils.sh
    fi
}

stop_get_chan_utils() {
    pid="$(ps ww | grep get_chan_utils.sh | grep -v grep | awk '{print $1}')"
    [ -n "$pid" ] && kill -9 $pid
}

#================================

change_channel() {
    wifi_iface="$1"
    radio="$2"
    chosen_chan="$3"
    GetTime="`date +%s`"
    chan_changeTS="${chan_changeTS_file}${radio}"
    wifi_device=

    if [ -n "$(echo $wifi_iface | grep wlan0)" ]; then
        freq=$(( ($chosen_chan * 5) + 5000 ))
        freq_center=$freq

        if [ "$bw" == "40" ]; then
            freq_center=$(($freq+10))
        elif [[ "$bw" == "80" ]]; then
            freq_center=$(($freq+30))
        elif [[ "$bw" == "160" ]]; then
            freq_center=$(($freq+70))
        fi

        wifi_device="wlan0"

    elif [[ -n "$(echo $wifi_iface | grep wlan1)" ]]; then
        freq=$(( (($chosen_chan - 1) * 5) + 2412 ))
        freq_center=$freq

        wifi_device="wlan1"
    fi

    echo "$GetTime" > $chan_changeTS
    _log "[Info] Changing channel occurs for $wifi_iface"
    cmd="{ \"freq\": $freq, \"center_freq1\": $freq_center, \"bcn_count\": 10, \"force\": \"true\" }"
    _log "[Info] ubus call hostapd.$wifi_iface switch_chan $cmd"
    #switch_chan can't jump to dfs channel
    status=$(ubus -S call hostapd.$wifi_iface switch_chan "$cmd")

    #set txpower by our own txpower table
    /sbin/set_ECtxpower.sh "$wifi_device" "$chosen_chan"
}

check_radio_channel() {
    ifname="$1"
    util_delta="$2"
    GetTime="`date +%s`"
    chan=$(iw $ifname info | grep "channel" | cut -d' ' -f2)
    current_chan="$chan"
    freq=
    chosen_chan=

    if [ -n "$(echo $ifname | grep wlan0)" ]; then
        radio_device="radio0"
    index=0
        freq=$(( ($chan * 5) + 5000 ))
    elif [[ -n "$(echo $ifname | grep wlan1)" ]]; then
        radio_device="radio1"
    index=1
        freq=$(( (($chan - 1) * 5) + 2412 ))
    fi

    chs=$(uci get wireless.$radio_device.channels 2>/dev/null)
    bw=$(iw $ifname info | grep "channel" | cut -d' ' -f6)
    chs_legal=
    chans_len=0

    #choose legal channel as channel pool
    if [ -n "$(echo $ifname | grep wlan0)" ]; then
        if [ "$bw" == "20" ]; then
          channel_list=$CHANLIST_5G_bw20
        elif [[ "$bw" == "40" ]]; then
          channel_list=$CHANLIST_5G_bw40
        else
          channel_list=$CHANLIST_5G_bw80
        fi
    elif [[ -n "$(echo $ifname | grep wlan1)" ]]; then
        channel_list=$CHANLIST_2G
    fi

    for ch in ${chs//,/ }
    do
        for ch_legal in ${channel_list}
        do
            if [ "$ch" == "$ch_legal" ]; then
                if [ -z "$chs_legal" ]; then
                    chs_legal="$ch"
                else
                    chs_legal="$chs_legal $ch"
                fi
                chans_len=$(($chans_len+1))
                break
            fi
        done
    done
    #end

    chan_util=$(cat ${CHAN_UTILS}${index})
    [ -z "${chan_util}" ] && return

    _log "[Info] channel legal: $chs_legal"

    _log "[Info] Channel util: $ifname - $chan_util"
    _log "[Info] Current channel: $ifname - $chan"

    if [ "$chan_util" -ge "$util_delta" ]; then
        #use MAC as a random delay
        #last char of MAC*delay_interval as delay time
        delay=0
        internet_src="`uci get network.wan.inet_src 2>/dev/null`"
        mac="$(ifconfig ${internet_src} | grep HWaddr | awk '{print $5}')"

        if [ -n "$mac" ]; then
            delay_base="${mac: -1}"
            delay=$(printf "%d\n" $((0x${delay_base} * delay_interval)))
        fi

        _log "[Info] delay time: $delay"

        #timestamp mod by Magic number first and then mod by chans_len to choose channel
        idx=$(((((GetTime + delay) % Magic_num) % chans_len) + 1 ))
        chosen_chan=`echo $chs_legal | cut -d ' ' -f$idx`

        _log "[Info] chosen_chan: $chosen_chan"

        if [ "$current_chan" != "$chosen_chan" ]; then
            change_channel $ifname $radio_device $chosen_chan
        fi
    fi
}

start_channel_balance() {
    #log level 8: debug
    [ "$(uci get acn.mgmt.syslog_level)" == "8" ] && debug_flag=1

    for dev_data in ${DEVS}
    do
        if [ "$dev_data" == "wlan0" ]; then
            radio="radio0"
        elif [[ "$dev_data" == "wlan1" ]]; then
            radio="radio1"
        fi

        util_delta=$(uci get wireless.$radio.chan_util_delta 2>/dev/null)

        ap_mode=$(uci get wireless.$radio.mode 2>/dev/null)

        [ -z "$util_delta" -o "$util_delta" -eq "0" -o  "$ap_mode" != "ap" ] && continue

        #avoid changing channel too frequently
        nowTS="`date +%s`"
        chan_changeTS="$chan_changeTS_file$radio"
        if [ -e "$chan_changeTS" ]; then
            beforeTS=$(cat $chan_changeTS)
            deltaTS=$(($nowTS - $beforeTS))
            [ "$deltaTS" -lt "$jump_cooldown" ] && {
                _log "[Info] $radio has changed channel for $deltaTS seconds, please wait for $jump_cooldown seconds"
                continue
            }
        fi

        #find an VAP enable
        result=
        result=$(iwinfo | grep ${dev_data} | head -n1 | cut -d' ' -f1 )

        if [ "$result" != "" ]; then
            start_get_chan_utils
            sleep 1
            check_radio_channel $result $util_delta
        fi
     done
}

clean_cron_entries() {
  _log "[Exit] clear cron rule: channel balance"
  _rm_cron_script ${SCRIPT}
}

case "$1" in
  boot)
    add_cron_entries
  ;;
  start)
    start_channel_balance
  ;;
  stop)
    clean_cron_entries
    stop_get_chan_utils
  ;;
esac

exit 0

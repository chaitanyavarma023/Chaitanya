#!/bin/sh

# Copyright (c) 2016, prpl Foundation
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without
# fee is hereby granted, provided that the above copyright notice and this permission notice appear
# in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
# INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
# FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
# ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Author: Nils Koenig <openwrt@newk.it>

SCRIPT=$0
LOCKFILE=/tmp/wifi_schedule.lock
LOGFILE=/tmp/log/wifi_schedule.log
LOGGING=0 #default is off
PACKAGE=wifi_schedule
GLOBAL=${PACKAGE}.@global[0]

_log()
{
    if [ ${LOGGING} -eq 1 ]; then
        local ts=$(date)
        echo "$ts $@" >> ${LOGFILE}
    fi
}

_exit()
{
    local rc=$1
    lock -u ${LOCKFILE}
    exit ${rc}
}

_add_cron_script()
{
    (crontab -l ; echo "$1") | sort | uniq | crontab -
}

_rm_cron_script()
{
    crontab -l | grep -v "$1" |  sort | uniq | crontab -
}

_get_uci_value_raw()
{
    local value
    value=$(uci get $1 2> /dev/null)
    local rc=$?
    echo ${value}
    return ${rc}
}

_get_uci_value()
{
    local key=$1
    local default=$2
    local value=$(_get_uci_value_raw $key)
    local rc=$?
    if [ ${rc} -ne 0 ]; then
        if [ -n "${default}" ]; then
            _log "Could not determine UCI value $key, use default '$default'"
            echo ${default}
        else
            _log "Could not determine UCI value $key"
        fi
        return 1
    fi
    echo ${value}
}

_format_dow_list()
{
    local dow=$1
    local flist=""
    local day
    for day in ${dow}
    do
        if [ ! -z ${flist} ]; then
            flist="${flist},"
        fi
        flist="${flist}${day:0:3}"
    done
    echo ${flist}
}


_enable_wifi_schedule()
{
    local entry=$1
    local starttime
    local stoptime
    starttime=$(_get_uci_value ${PACKAGE}.${entry}.starttime) || _exit 1
    # set || _exit 1 back when cloud is fixed
    stoptime=$(_get_uci_value ${PACKAGE}.${entry}.stoptime) 
    ###### to be removed when cloud config is fixed
    if [ $? -ne 0 ]; then
        stoptime=$(_get_uci_value ${PACKAGE}.${entry}.endtime) || _exit 1
    fi
    ##########

    local dow
    dow=$(_get_uci_value_raw ${PACKAGE}.${entry}.daysofweek) || _exit 1 
    
    local fdow=$(_format_dow_list "$dow")
    local forcewifidown
    forcewifidown=$(_get_uci_value ${PACKAGE}.${entry}.forcewifidown)
    local stopmode="stop"
    if [ $forcewifidown -eq 1 ]; then
        stopmode="forcestop"
    fi


    local stop_cron_entry="$(echo ${stoptime} | awk -F':' '{print $2, $1}') * * ${fdow} ${SCRIPT} ${stopmode}" # ${entry}"
    _add_cron_script "${stop_cron_entry}"

    if [ $starttime != $stoptime ]
    then                                                         
        local start_cron_entry="$(echo ${starttime} | awk -F':' '{print $2, $1}') * * ${fdow} ${SCRIPT} start" # ${entry}"
        _add_cron_script "${start_cron_entry}"
    fi

    return 0
}

_get_wireless_interfaces()
{
    local n=$(cat /proc/net/wireless | wc -l)
    cat /proc/net/wireless | tail -n $(($n - 2))|awk -F':' '{print $1}'| sed  's/ //' 
}


get_module_list()
{
    local mod_list
    local _if
    for _if in $(_get_wireless_interfaces)
    do
        local mod=$(basename $(readlink -f /sys/class/net/${_if}/device/driver))
        local mod_dep=$(modinfo ${mod} | awk '{if ($1 ~ /depends/) print $2}')
        mod_list=$(echo -e "${mod_list}\n${mod},${mod_dep}" | sort | uniq)
    done
    echo $mod_list | tr ',' ' '
}

save_module_list_uci()
{
    local list=$(get_module_list)
    uci set ${GLOBAL}.modules="${list}"
    uci commit ${PACKAGE}
}

_unload_modules()
{
    local list=$(_get_uci_value ${GLOBAL}.modules) 
    local retries
    retries=$(_get_uci_value ${GLOBAL}.modules_retries) || _exit 1
    _log "unload_modules ${list} (retries: ${retries})"
    local i=0
    while [ ${i} -lt ${retries}  &&  "${list}" != "" ]
    do  
        i=$(($i+1))
        local mod
        local first=0
        for mod in ${list}
        do
            if [ $first -eq 0 ]; then
                list=""
                first=1
            fi
            rmmod ${mod} > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                list="$list $mod"
            fi
        done
    done
}


_load_modules()
{
    local list=$(_get_uci_value ${GLOBAL}.modules)
    local retries
    retries=$(_get_uci_value ${GLOBAL}.modules_retries) || _exit 1
    _log "load_modules ${list} (retries: ${retries})"
    local i=0
    while [ ${i} -lt ${retries}  &&  "${list}" != "" ]
    do  
        i=$(($i+1))
        local mod
        local first=0
        for mod in ${list}
        do
            if [ $first -eq 0 ]; then
                list=""
                first=1
            fi
            modprobe ${mod} > /dev/null 2>&1
            rc=$? 
            if [ $rc -ne 255 ]; then
                list="$list $mod"
            fi
        done
    done
}

_create_cron_entries()
{
    local entries=$(uci show ${PACKAGE} 2> /dev/null | awk -F'.' '{print $2}' | grep -v '=' | grep -v '@global\[0\]' | uniq | sort)
    local _entry
    for entry in ${entries}
    do 
        local status
        status=$(_get_uci_value ${PACKAGE}.${entry}.enabled 0)
        if [ ${status} -eq 1 ]
        then
            _log "setup \"${entry}\" wifi schedule rule"
            _enable_wifi_schedule ${entry}
        fi
    done
}

clean_cron_entries()
{
    _log "clear all wifi schedule rules"
    _rm_cron_script ${SCRIPT}
}

is_ready() {
	# Not interested in value, just check for marker.
	uci -P /var/state get wifi_schedule.ready >/dev/null 2>&1
	return $?
}

set_ready() {
	uci -P /var/state set wifi_schedule.ready=1
	_rm_cron_script "${SCRIPT} verify"
}

# assumes, that both wireless radios work synchronously;
# checks only first one
# RADIO INTERFACES ARE RETRIEVED IN A HACKY WAY
verify_wifi()
{
    # on qca first radio is wifi0, on rtk it is wlan0
#    radio_name="$(ip l | egrep "(wifi0 | wlan0):" | awk -F": " '{print $2}' | tail -n 1)"
#    [ -n "$radio_name" ] || {
#      radio_name="$(ip l | egrep "(wifi1 | wlan1):" | awk -F": " '{print $2}' | tail -n 1)"
#    }

#    [ -n "$radio_name" ] || {
#      radio_name="wlan0"
#    }

#    radio_ifname=$radio_name
#    [ "$radio_name" == "wlan0" ] && radio_name="radio0"
#    [ "$radio_name" == "wlan1" ] && radio_name="radio1"

#    [ -n "$radio_name" ]  || {
#        _log "error: could not retrieve radio_name: exiting"
#        _exit 1
#    }

    day_of_week=$(date +%a)
    curr_time=$(date +%H%M)
    # Store whether wifi scheduler is setting up for first time.
    init_check=$(is_ready || (set_ready && echo "yes"))

    _log "verifying current wifi state."

    if [ "$(_get_uci_value ${GLOBAL}.enabled 0)" == "0" ]; then
        
#        if [ "$(_get_uci_value wireless.$radio_name.disabled 0)" == "0" ]; then
            last_action="start"
#        else
#            last_action="forcestop"
#        fi

        _log "restore radios state, because schedule is disabled: ${last_action}"

    else

        # entries ordered by descending time (first is latest)
        this_weekday_entries=$(crontab -l | egrep ".*$day_of_week.*${SCRIPT}" | awk '{printf("%02d%02d%s\n",$2,$1,$0)}' | sort -r |  awk '{print substr($0,5)}' )
        # going through today's entries from latest to earliest
        # if some entry is earlier than current time, the state should come from that entry's action

        _log "revalidate radios active schedule, now: ${curr_time}, ${day_of_week}"

        PREV_IFS=$IFS
        # - setting internal separator so that "for" loop will split variable by \n
        IFS=$'\n'
        for entry in $this_weekday_entries; do
            entry_time=$( echo "$entry" | awk '{print(sprintf("%02d%02d\n", $2, $1))}' )
            if [ "$curr_time" -gt "$entry_time" ]; then
                last_entry=$entry
                last_action=$(echo "$entry" | awk '{print $NF}')
                time_early=FALSE
                break
            fi
        done
        IFS=$PREV_IFS

        # if our time is before first today's entry we need the last entry back in time
        if [ -z "${time_early+x}" ] ; then
            # going back in time until we find cron entries
            for offset in $(seq 1 1 7); do
                prev_weekday_name=$(date --date -$((24*$offset)):00 | awk '{print $1}')
                # entries ordered by descending time (first is latest)
                prev_weekday_entries=$(crontab -l | egrep ".*$prev_weekday_name.*${SCRIPT}" | awk '{printf("%02d%02d%s\n",$2,$1,$0)}' | sort -r |  awk '{print substr($0,5)}' )
                # if no entries that weekday
                if [ "x" == "x$prev_weekday_entries" ]; then
                    continue
                fi
                # taking last entry - the one that should have happened right before current weekday and time
                last_entry=$(echo "$prev_weekday_entries" | head -1)
                last_action=$(echo "$last_entry" | awk '{print $NF}')
                break
            done
        fi
    fi

    # If wifi scheduler setting up for first time skip radio enable.
    if [ "$last_action" == "start" -a -z "$init_check" ]; then #string includes start
        _log "radios start, now: ${curr_time}, ${day_of_week}"
#        if [ -z "$(ifconfig $radio_ifname | grep UP -w)" ]; then
            enable_wifi
#        fi
    fi
    if [ "$last_action" == "forcestop" ]; then #either stop or forcestop
        _log "radios stop, now: ${curr_time}, ${day_of_week}"
#        if [ -n "$(ifconfig $radio_ifname | grep UP -w)" ]; then
            disable_wifi
#        fi
    fi
}

check_cron_status()
{
    local global_enabled
    # Exit only if wifi_schedule config key is missing.
    global_enabled=$(_get_uci_value ${GLOBAL}.enabled) || _exit 1
    _rm_cron_script "${SCRIPT}"
    if [ ${global_enabled} -eq 1 ]; then
        _create_cron_entries
    fi

    if is_ready; then
        verify_wifi
    else
        _log "scheduling wifi state verification after 1 minute."
        # During initial setup and reconfigure same
        # wifi validation are done. However initiaial
        # setup requires different handling because
        # wireless configuration is in progress and
        # interfering with it could lead to device to
        # undetermined state. Defering it for one min.
        _add_cron_script "*/1 * * * * ${SCRIPT} verify"
    fi
}

disable_wifi()
{
    _rm_cron_script "${SCRIPT} recheck"
    _rm_cron_script "${SCRIPT} verify"
    /sbin/wifi down
    local unload_modules
    unload_modules=$(_get_uci_value_raw ${GLOBAL}.unload_modules) || _exit 1
    if [ "${unload_modules}" == "1" ]; then
        _unload_modules
    fi    
}

soft_disable_wifi()
{
    local _disable_wifi=1
    local iwinfo=/usr/bin/iwinfo
    if [ ! -e ${iwinfo} ]; then
        _log "${iwinfo} not available, skipping"
        return 1
    fi

    local ignore_stations=$(_get_uci_value_raw ${GLOBAL}.ignore_stations)
    [ -n "${ignore_stations}" ] && _log "Ignoring station(s) ${ignore_stations}"

    # check if no stations are associated
    local _if
    for _if in $(_get_wireless_interfaces)
    do
        local stations=$(${iwinfo} ${_if} assoclist | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
        if [ -n "${ignore_stations}" ]; then
            stations=$(echo "${stations}" | grep -vwi -E "${ignore_stations// /|}")
        fi

        if [ -n "${stations}" ]; then
            _disable_wifi=0
            _log "Station(s) $(echo ${stations}) associated on ${_if}"
        fi
    done

    if [ ${_disable_wifi} -eq 1 ]; then
        _log "No stations associated, disable wifi."
        disable_wifi
    else
        _log "Could not disable wifi due to associated stations, retrying..."
        local recheck_interval=$(_get_uci_value ${GLOBAL}.recheck_interval 1)
        _add_cron_script "*/${recheck_interval} * * * * ${SCRIPT} recheck"
    fi
}

enable_wifi()
{
    _rm_cron_script "${SCRIPT} recheck"
    _rm_cron_script "${SCRIPT} verify"
    /sbin/wifi
}

usage()
{
    echo ""
    echo "$0 cron|start|stop|forcestop|recheck|getmodules|savemodules|help"
    echo ""
    echo "    UCI Config File: /etc/config/${PACKAGE}"
    echo ""
    echo "    cron: Create cronjob entries."
    echo "    start: Start wifi."
    echo "    stop: Stop wifi gracefully, i.e. check if there are stations associated and if so keep retrying."
    echo "    forcestop: Stop wifi immediately."
    echo "    recheck: Recheck if wifi can be disabled now."
    echo "    getmodules: Returns a list of modules used by the wireless driver(s)"
    echo "    savemodules: Saves a list of automatic determined modules to UCI"
    echo "    help: This description."
    echo ""
}

###############################################################################
# MAIN
###############################################################################
LOGGING=$(_get_uci_value ${GLOBAL}.logging 0)
_log ${SCRIPT} $1 $2
lock ${LOCKFILE}

case "$1" in
    cron) check_cron_status ;;
    clean) clean_cron_entries ;;
    start) enable_wifi ;;
    forcestop) disable_wifi ;;
    stop) soft_disable_wifi ;;
    recheck) soft_disable_wifi ;;
    verify) verify_wifi ;;
    getmodules) get_module_list ;;
    savemodules) save_module_list_uci ;;
    help|--help|-h|*) usage ;;
esac

_exit 0

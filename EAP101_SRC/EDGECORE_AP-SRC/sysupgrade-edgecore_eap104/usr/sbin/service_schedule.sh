#!/bin/sh

. /lib/functions.sh

is_vap_on(){
    local iface="$1"
    ip li sh ${iface} 2> /dev/null | grep -w UP > /dev/null 2>&1
    [ $? -eq 0 ] && echo 0 || echo 1
}

vap_if_down(){
    local iface="$1"
    ifconfig ${iface} down > /dev/null 2>&1
}

vap_if_up(){
    local iface="$1"
    ifconfig ${iface} up > /dev/null 2>&1
}

current_wifi_plan()
{
    local off_plan="$1"
    local weekday=$(date +%w)
    local hour=$(date +%H)
    local plan_of_day=
    len=${#hour}
    [ $len -eq 2 ] && hour=$(echo $hour | sed 's/^0//g')
    plan_of_day=$(echo $off_plan | cut -d";" -f $((weekday+1)))
    echo $((($plan_of_day>>$hour)&1))
}

schedule_wifi(){
    local disabled
    local ifname
    local service_schedule
    local service_off_plan
    local curr_vap_on plan_vap_on

    config_get disabled $1 disabled
    [ "$disabled" = "1" ] && return
    config_get service_schedule $1 service_schedule
    [ -z "$service_schedule" ] && return
    config_get service_off_plan $1 service_off_plan
    [ -z "$service_off_plan" ] && return
    config_get ifname $1 ifname
    [ -z "$ifname" ] && return
    curr_vap_on=$(is_vap_on $ifname)
    plan_vap_on=$(current_wifi_plan $service_off_plan)
    if [ "$curr_vap_on" != "$plan_vap_on" ];then
        if [ "$curr_vap_on" = "0" ];then
             vap_if_down $ifname
        elif [ "$curr_vap_on" = "1" ];then
             vap_if_up $ifname
        fi
    fi
}

[ ! -f /tmp/.service_schedule ] && exit
[ "$(cat /tmp/.service_schedule)" != "0" ] && exit

config_load wireless
config_foreach schedule_wifi wifi-iface


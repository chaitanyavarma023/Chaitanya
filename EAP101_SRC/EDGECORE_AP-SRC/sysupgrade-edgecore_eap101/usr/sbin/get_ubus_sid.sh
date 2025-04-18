#!/bin/sh

need_grant=0
if [ $(ubus call session list | grep '"timeout": 0,' | wc -l) -le 1 ]; then
    need_grant=1
    data=$(ubus call session create '{ "timeout": 0}' | grep ubus_rpc_session | grep -v "00000000000000000000000000000000" | cut -d":" -f2)
else
    cnt=0
    idx=0
    for num in $(ubus call session list | grep '"timeout"' | cut -d ":" -f2 | sed 's/,//g')
    do
        cnt=$((cnt+1))
        [ $num -eq 0  ] && idx=$((idx+1))
        [ $idx -eq 2  ] && break
    done

    i=0
    for data in $(ubus call session list | grep "ubus_rpc_session" | cut -d ":" -f2)
    do
        i=$((i+1))
        [ $i -eq $cnt  ] && break
    done
fi

if [ -n "${data}" ]; then
    data=${data#*\"}
    sid=${data%%\"*}
    if [ "${need_grant}" = "1" ]; then
        ubus call session grant "{\"ubus_rpc_session\": \"${sid}\", \"scope\": \"ubus\", \"objects\":[[\"*\", \"*\"]]}"
        ubus call session grant "{\"ubus_rpc_session\": \"${sid}\", \"scope\": \"uci\", \"objects\":[[ \"*\", \"read\" ],[\"*\", \"write\"]]}"
        ubus call session grant "{\"ubus_rpc_session\": \"${sid}\", \"scope\": \"file\", \"objects\":[[\"/sbin/reboot\", \"exec\"]]}"
        ubus call session grant "{\"ubus_rpc_session\": \"${sid}\", \"scope\": \"file\", \"objects\":[[\"*\", \"read\"]]}"
    fi
    echo $sid
fi


#!/bin/sh

MAC="$1"
NAS_ID="$2"
VID="$3"
if [ -n "$MAC" -a -f /tmp/online/$MAC ]; then
    unset user
    i=0; while read "user[$i]"; do let i=i+1; done < /tmp/online/$MAC
    if [ "${user[6]}" = "RADIUS" ]; then
        en="$(< /db/subscriber/mgmt/${user[5]}/radius/notify_gw_change)"
        if [ "${en}" = "1" ]; then
            TRAFFIC=( $(. /ramfs/bin/get_traffic.sh $1) )
            if [ -z "${TRAFFIC[0]}" ]; then
            TRAFFIC=( 0 0 0 0)
            fi
            /ramfs/bin/radius_acct.sh Interim-Update "${MAC}" "${TRAFFIC[*]}" "" "${NAS_ID}" "${VID}"
        fi
    fi
fi

exit 0

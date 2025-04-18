#!/bin/sh
function delock()
{
    [ -n "$1" ] && [ -f "/tmp/cipgwnl_lock/$1" ] && rm -f "/tmp/cipgwnl_lock/$1"
}

# $1: MAC
# $2: exit code
function quit()
{
    [ -n "$1" ] && delock "$1"
    [ -n "$2" ] && exit $2 || exit 0
}

# $1 MAC, $2 v4|v6, $3 New IP addr, $4 VOLUME_CHECK, [$5 KICKED USER_MAC]
MAC="$1"
VER="$2"
NEWIP="$3"
VOLUME_CHECK="$4"

CIPGWCLI="/ramfs/bin/cipgwcli"

if [ -z "${MAC}" ] || [ -z "${VER}" ] || [ -z "${NEWIP}" ]; then
    quit ${MAC} 1
fi

if [ ${VOLUME_CHECK} -lt 0 ]; then
    ${CIPGWCLI} logout "${MAC}"
    quit ${MAC} 1
fi

calling_file=/tmp/radius_exec/${MAC}
[ -f $calling_file ] && source ${calling_file}

#-----------------------------------------------------
# Avoid Dual-ips on Single interface:
# Perform arping to check if present IP still exists.
# If yes, log and quit this shell script.
#-----------------------------------------------------
if [ "${VER}" = "v4" ] && [ -n "${IP}"  ]; then
	iface="$(ip route get ${IP} | grep dev | awk '{print $3}')"
	arping -I ${iface} -M ${MAC} ${IP} -c 1 -w 3 # ping one time and return back once it get reply.
	if [ "$?" == "0" ]; then
	    quit ${MAC}
	fi
fi

[ -z "${user_name}" ] && user_name=$(echo ${MAC} | sed 's/://g')
[ -z "${maxByteIn}" ] && maxByteIn=0
[ -z "${maxByteOut}" ] && maxByteOut=0
[ -z "${byte_amount}" ] && byte_amount=0

res=$(/ramfs/bin/cipgwcli query ${NEWIP})
if [ "${res}" != "" ]; then
	mac=$(echo ${res} | awk -F, '{print $2}')
	${CIPGWCLI} kick ${mac}
fi
${CIPGWCLI} login "${MAC}" "${user_name}" "${NEWIP}" "" "0" "0" "0" "${maxByteIn}" "${maxByteOut}" "${byte_amount}" "${idle_timeout}" "${session_timeout}" "${acct_interim}"

quit ${MAC}

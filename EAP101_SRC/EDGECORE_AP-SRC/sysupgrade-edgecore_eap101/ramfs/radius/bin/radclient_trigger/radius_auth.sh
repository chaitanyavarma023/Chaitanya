#!/bin/sh
#arg 1~5: "ori_name" "password" "user_mac" "mgmt_index" "srv_index" 
#  6~10 : "user_ipv4" "user_ipv6" "acct_session_id" "vlan_id" "http_user_agent"
# 11~15 : "auth_method" "chap challenge" "reqid" "mobile_browser" "os"
ori_name="$1"
password="$2"
user_mac="$3"
mgmt_index="$4"
srv_index="$5"
user_ipv4="$6"
user_ipv6="$7"
acct_session_id="$8"
vlan_id="$9"
http_user_agent="${10}"
auth_method="${11}"
chap_challenge="${12}"
reqid="${13}"
mobile_browser="${14}"
os=${15}

APNAME=`sh /ramfs/bin/get_assoc_AP_name.sh "${user_mac}"`

if [ "$mobile_browser" = "1" ]; then
    DEVICE_TYPE="Mobile"
else
    DEVICE_TYPE="N/A"
fi

. /conf/etc/profile
. /ramfs/bin/radius_func

# handle User-Name attribute os RADIUS packets
postfix="$(< /db/subscriber/mgmt/${mgmt_index}/postfix)"
user="$(get_username ${mgmt_index} "${ori_name%@*}" "${ori_name%@*}@${postfix}" "${ori_name}")"
[ -z "${user}" ] && user="${ori_name%@*}"

function get_prefix_oid()
{
    trap_meta="/etc/snmp/db/trap_meta.db"
    prefix_oid=""
    for oid in $(sqlite $trap_meta "select oid from trap_subtree_root where trap_class='ext_root' or trap_class='ac_radis_info'"); do
	prefix_oid="${prefix_oid}${oid}"
    done
    echo "$prefix_oid"
}
# format ip and find valid user ip (ipv4 or ipv6)
[ "$user_ipv4" == "0.0.0.0" ] && user_ipv4=""
[ "$user_ipv6" == "0000:0000:0000:0000:0000:0000:0000:0000" ] && user_ipv6=""
valid_user_ip=""
if [ -n "$user_ipv4" ]; then
    valid_user_ip="$user_ipv4"
elif [ -n "$user_ipv6" ]; then
    valid_user_ip="$user_ipv6"
fi

# Loading server information
SERVER_IP="`get_auth_server_ip \"${mgmt_index}\" \"${srv_index}\"`"
if [ -z "$SERVER_IP" ]; then
    exit
fi
AUTH_PORT="`get_auth_server_port \"${mgmt_index}\" \"${srv_index}\"`"
SECRET_KEY="`get_auth_server_key \"${mgmt_index}\" \"${srv_index}\"`"
AUTHEN="`get_auth_server_method \"${mgmt_index}\" \"${srv_index}\"`"


# Prepare sending message attributes

#   Service_Type          : $Service_Type
#   Acct-Session-Id       : $acct_session_id
#   User-Name             : $user
#   User-Password         : $password
#   Framed-IP-Address     : $user_ipv4
#   Called-Station-Id     : $calledid
#   Calling-Station-Id    : $callingid
#   Framed-MTU            : $framed_mtu
Service_Type=$(get_service_type ${mgmt_index})
calledid="`get_calledid`"
callingid="`get_callingid \"${user_mac}\"`"
framed_mtu="1400"
[ -n "${user_ipv4}" ] && framed_ip_address="${user_ipv4}"

# VSA attribute
sz_id="`/ramfs/bin/ip2sz.sh \"${valid_user_ip}\"`"
[ "${sz_id}" -lt 0 -o "${sz_id}" -gt "${VLAN_NUM}" ] && sz_id=""
sz_name="`get_file /db/sz/\"${sz_id}\"/name`"
current_vlan_id="`get_nas_port \"${valid_user_ip}\" \"${user_mac}\"`"
current_location_id="`get_wispr_location_id \"${sz_id}\" \"${current_vlan_id}\" \"${user_mac}\"`"

mac="$(echo -n $user_mac | tr 'a-z' 'A-Z')"
udptap_user_file="/sys/kernel/udptap/user/${mac}"
if [ -f "${udptap_user_file}" ]; then
    source "${udptap_user_file}"
fi

tIP="$user_ipv4"
nIP=""
if [ -n "$User_Original_IP" ]; then
    tIP="$User_Original_IP"
    nIP="$user_ipv4"
fi

if [ "$AUTHEN" == "PAP" ]; then
    Password="User-Password=\"$password\""
else
    Password="CHAP-Password=\"$password\""
fi

#   NAS-Identifier
#   NAS-Port
#   NAS-Port-ID
#   NAS-Port-Type
#   NAS-IP-Address
NAS_ID="`get_nas_id \"${mgmt_index}\" \"${sz_id}\" \"${vlan_id}\" \"${user_mac}\"`"
NAS_Port=${vlan_id}
NAS_Port_ID="`get_nas_port_id`"
NAS_Port_Type="`get_nas_port_type \"${mgmt_index}\"`"
NAS_IP_Address="`get_nas_ip`"

#   WISPr-Location-ID
#   WISPr-Location-Name
#   WISPr-Logoff-URL
WISPr_Location_ID="`get_wispr_location_id \"${sz_id}\" \"${NAS_Port}\" \"${user_mac}\" \"${auth_method}\"`"
WISPr_Location_Name="`get_wispr_location_name \"${sz_id}\" \"${NAS_Port}\" \"${user_mac}\" \"${auth_method}\"`"
WISPr_Logoff_URL="`get_wispr_logoff_url`"

# For Tunneled PLM : change NAS_Port to '31932000 + DEV-ID * 4096 + VID'
if [ $current_vlan_id -ge 31936096 ]; then
    NAS_Port="${current_vlan_id}"
fi

#CLASS
CLASS="`get_attr_class \"${mgmt_index}\" \"${sz_id}\" \"${vlan_id}\" \"${user_mac}\" \"${auth_method}\"`"

##### replace customized attributes #####
WAN_IP="${NAS_IP_Address}"
WAN_MAC="${calledid}"
CLIENT_IP="${framed_ip_address}"
CLIENT_MAC="${callingid}"
SZ_SSID="$(get_file "/db/sz/${sz_id}/ssid")"
CURRENT_VLAN_ID="${current_vlan_id}"
TIMESTAMP="$(date +%s)"
SESSION_ID="${acct_session_id}"
LOCATION_ID="${WISPr_Location_ID}"
LOCATION_NAME="${WISPr_Location_Name}"
GET_PKTTYPE="/ramfs/bin/get_pkttype"
RADATTR_PATH="/db/custom_radattr"
type="Auth"
[ -f ${RADATTR_PATH}/nas_ip ] && eval NAS_IP_Address=$(get_file "${RADATTR_PATH}/nas_ip")
[ -f ${RADATTR_PATH}/nas_id ] && eval NAS_ID=$(get_file "${RADATTR_PATH}/nas_id")
[ -f ${RADATTR_PATH}/nas_port ] && eval NAS_Port=$(get_file "${RADATTR_PATH}/nas_port")
[ -f ${RADATTR_PATH}/callingid ] && eval callingid=$(get_file "${RADATTR_PATH}/callingid")
[ -f ${RADATTR_PATH}/calledid ] && eval calledid=$(get_file "${RADATTR_PATH}/calledid")
[ -f ${RADATTR_PATH}/asid ] && eval acct_session_id=$(get_file "${RADATTR_PATH}/asid")
##### replace customized attributes #####

### handle the order of access-request attributes
[ "$(${GET_PKTTYPE} "User-Name" "${type}")" != "0" -a -n "${user}" ] && sendmsg="User-Name=\"${user}\""
[ -n "${Password}" ] && sendmsg="${sendmsg},${Password}"
[ "$(${GET_PKTTYPE} "Calling-Station-Id" "${type}")" != "0" -a -n "${callingid}" ] && sendmsg="${sendmsg},Calling-Station-Id=\"${callingid}\""
[ "$(${GET_PKTTYPE} "NAS-IP-Address" "${type}")" != "0" -a -n "${NAS_IP_Address}" ] && sendmsg="${sendmsg},NAS-IP-Address=\"${NAS_IP_Address}\""
[ "$(${GET_PKTTYPE} "Called-Station-Id" "${type}")" != "0" -a -n "${calledid}" ] && sendmsg="${sendmsg},Called-Station-Id=\"${calledid}\""
[ "$(${GET_PKTTYPE} "Service-Type" "${type}")" != "0" -a -n "${Service_Type}" ] && sendmsg="${sendmsg},Service-Type=\"${Service_Type}\""
[ "$(${GET_PKTTYPE} "NAS-Port-Type" "${type}")" != "0" -a -n "${NAS_Port_Type}" ] && sendmsg="${sendmsg},NAS-Port-Type=\"${NAS_Port_Type}\""
[ "$(${GET_PKTTYPE} "NAS-Identifier" "${type}")" != "0" -a -n "${NAS_ID}" ] && sendmsg="${sendmsg},NAS-Identifier=\"${NAS_ID}\""
[ "$(${GET_PKTTYPE} "Framed-MTU" "${type}")" != "0" -a -n "${framed_mtu}" ] && sendmsg="${sendmsg},Framed-MTU=\"${framed_mtu}\""
[ "$(${GET_PKTTYPE} "Class" "${type}")" != "0" -a -n "${CLASS}" ] && sendmsg="${sendmsg},Class=\"${CLASS}\""
[ "$(${GET_PKTTYPE} "Acct-Session-Id" "${type}")" != "0" -a -n "${acct_session_id}" ] && sendmsg="${sendmsg},Acct-Session-Id=\"${acct_session_id}\""
[ "$(${GET_PKTTYPE} "Framed-IP-Address" "${type}")" != "0" -a -n "${tIP}" ] && sendmsg="${sendmsg},Framed-IP-Address=\"${tIP}\""
[ "$(${GET_PKTTYPE} "NAS-Port" "${type}")" != "0" -a -n "${NAS_Port}" ] && sendmsg="${sendmsg},NAS-Port=\"${NAS_Port}\""
[ "$(${GET_PKTTYPE} "NAS-Port-Id" "${type}")" != "0" -a -n "${NAS_Port_ID}" ] && sendmsg="${sendmsg},NAS-Port-Id=\"${NAS_Port_ID}\""
[ "$(${GET_PKTTYPE} "WISPr-Location-ID" "${type}")" != "0" -a -n "${WISPr_Location_ID}" ] && sendmsg="${sendmsg},WISPr-Location-ID=\"${WISPr_Location_ID}\""
[ "$(${GET_PKTTYPE} "WISPr-Location-Name" "${type}")" != "0" -a -n "${WISPr_Location_Name}" ] && sendmsg="${sendmsg},WISPr-Location-Name=\"${WISPr_Location_Name}\""
[ "$(${GET_PKTTYPE} "WISPr-Logoff-URL" "${type}")" != "0" -a -n "${WISPr_Logoff_URL}" ] && sendmsg="${sendmsg},WISPr-Logoff-URL=\"${WISPr_Logoff_URL}\""
[ "$(${GET_PKTTYPE} "ZVendor-Http-User-Agent" "${type}")" != "0" -a -n "${http_user_agent}" ] && sendmsg="${sendmsg},ZVendor-Http-User-Agent=\"${http_user_agent}\""
[ "$(${GET_PKTTYPE} "ZVendor-Auth-Method" "${type}")" != "0" -a -n "${auth_method}" ] && sendmsg="${sendmsg},ZVendor-Auth-Method=\"${auth_method}\""
[ "$(${GET_PKTTYPE} "ZVendor-Current-VLAN-ID" "${type}")" != "0" -a -n "${current_vlan_id}" ] && sendmsg="${sendmsg},ZVendor-Current-VLAN-ID=\"${current_vlan_id}\""
[ "$(${GET_PKTTYPE} "ZVendor-Current-Location-ID" "${type}")" != "0" -a -n "${current_location_id}" ] && sendmsg="${sendmsg},ZVendor-Current-Location-ID=\"${current_location_id}\""
[ "$(${GET_PKTTYPE} "ZVendor-Service-Zone-Name" "${type}")" != "0" -a -n "${sz_name}" ] && sendmsg="${sendmsg},ZVendor-Service-Zone-Name=\"${sz_name}\""
[ "$(${GET_PKTTYPE} "ZVendor-NAT-IP-Address" "${type}")" != "0" -a -n "${nIP}" ] && sendmsg="${sendmsg},ZVendor-NAT-IP-Address=\"${nIP}\""

# Sending message to RADIUS server
NUM_RETRIES="`get_file /db/subscriber/mgmt/\"${mgmt_index}\"/radius/num_retries`"
RETRIES_TIMEOUT="`get_file /db/subscriber/mgmt/\"${mgmt_index}\"/radius/retries_timeout`"
echo "${sendmsg}" > /tmp/radius_login
if [ "$chap_challenge" != "" ]; then
    [ "$reqid" = "" ] && reqid=0
    recvmsg=$( echo "${sendmsg},CHAP-Challenge=$chap_challenge" | /usr/local/bin/radclient -i $reqid -N ${SERVER_IP}:${AUTH_PORT} auth ${SECRET_KEY} -r $NUM_RETRIES -t $RETRIES_TIMEOUT 2>/dev/null )
else
    recvmsg=$( echo "${sendmsg}" | /usr/local/bin/radclient ${SERVER_IP}:${AUTH_PORT} auth ${SECRET_KEY} -r $NUM_RETRIES -t $RETRIES_TIMEOUT 2>/dev/null )
fi

ret=$?

attr1="`echo $recvmsg | awk -F',' '{print $2;}' | awk '{print $1}'`"
attr2="`echo $recvmsg | awk -F',' '{print $2;}' | awk '{print $2}'`"
# recvmsg: Received response ID XXX, code "attr2", length = XX ...
# attr2 == 2: radclient auth successfully
# attr2 != 2: radclient success but auth error 

if [ "${auth_method}" = "MACAuth" -o "${auth_method}" = "NESPOT" ]; then
    [ ! -d "/tmp/mac_auth" ] && mkdir "/tmp/mac_auth"
    echo "${recvmsg}" > /tmp/mac_auth/${user_mac}_pre
fi

#Check clear trap
let oid_index=$mgmt_index-1
prefix_oid=$(get_prefix_oid)
if [ "$srv_index" == "1" ];then
    #primary
    ipaddr_oid=2
    port_oid=3
elif [ "$srv_index" == "2" ];then
    #second
    ipaddr_oid=5
    port_oid=6
fi
snmp_trap_str="\n\n\n${prefix_oid}.1.1.${ipaddr_oid}.${oid_index} ${SERVER_IP}\n${prefix_oid}.1.1.${port_oid}.${oid_index} ${AUTH_PORT}"
snmp_radiusauth_f="/tmp/.#snmp_radiusauth_${mgmt_index}_${srv_index}"

if [ "$attr1" == "code" ]; then
    if [ -f "$snmp_radiusauth_f" ]; then
        # if server(srv_index,mgmt_index) was unavailable berfore, then send available trap
        echo -e "$snmp_trap_str" | /ramfs/bin/immediate_trap.sh RadiusAuthServerAvailableTrap
        rm -f "$snmp_radiusauth_f"
    fi
else
    if [ ! -f "$snmp_radiusauth_f" ]; then
        # if server(srv_index,mgmt_index) is unavailable first time, send unavailable trap
        echo -e "$snmp_trap_str" | /ramfs/bin/immediate_trap.sh RadiusAuthServerUnavailableTrap
        touch "$snmp_radiusauth_f"
    fi
fi


check=$(echo "${recvmsg}" | grep '^Received.*code 2,')
if [ "${ret}" = "0" -a -z "${check}" ]; then
    #for radius 1.0.1, force to return 1
    ret=1
fi

#for roaming in history
postfix=$(< /db/subscriber/mgmt/${mgmt_index}/postfix)
if [ "${ret}" = "0" -a -n "${postfix}" -a -z "${postfix##.*}" ]; then
    #Record Format:
    #RecTime Type UserName NasIdentifier NasIPAddress NasPort CallingStationID UsrIPAddress AcctSessionID
    #    AcctSessionTime AcctInputOctets AcctOutputOctets AcctInputPackets AcctOutputPackets Message
    DT=`date "+%Y-%m-%d"`
    RT=`date "+%Y-%m-%d %H:%M:%S %z"`
    MSG="$( echo "$recvmsg" | grep -i "Reply-Message" | sed 's/^.*Reply-Message [^=]*=//;s/^[ ]*"//;s/"[ ]*$//' | tr '\n' ';' )"
    # handle Name field of rihistory. If ori_name with postfix then ori_name, else ori_name with auth_server's postfix.
    if [ "X${ori_name}" = "X${ori_name%@*}" ]; then
        log_name="${ori_name}@${postfix}"
    else
        log_name="${ori_name}"
    fi

    echo -e "${RT}\tAccept\t${log_name}\t${NAS_ID}\t${NAS_IP_Address}\t${NAS_Port}\t${user_mac}\t${user_ipv4}\t${user_ipv6}\t${acct_session_id}\t0\t0\t0\t0\t0\t${MSG}\t\t\t\t\t\t\t\tRoaming In\t${APNAME}\t${DEVICE_TYPE}\t${os}\t" >> "/db/rihistory/$DT"
fi

# VSA Pairs
vdata=""
if [ "$ret" = "0" ]; then
#    vdata="$(echo "$recvmsg" | /usr/bin/awk -f /ramfs/bin/find_bytes.awk -- - fvsp)"
    volume_total="$(echo "${recvmsg}" | grep "ZVendor-Byte-Amount[^-]" | cut -d "=" -f 2)"
    volume_total_4G="$(echo "${recvmsg}" | grep "ZVendor-Byte-Amount-4GB" | cut -d "=" -f 2)"
    if [ -n "${volume_total}" ]; then
	if [ -n "${volume_total_4G}" ]; then
	    volume_total_4G_to_byte=$((volume_total_4G*4294967296))
	    volume_total=$((volume_total+volume_total_4G_to_byte))
	fi
	vdata=${volume_total}
    fi
    volume_up="$(echo "${recvmsg}" | grep "ZVendor-MaxByteOut[^-]" | cut -d "=" -f 2)"
    volume_up_4GB="$(echo "${recvmsg}" | grep "ZVendor-MaxByteOut-4GB" | cut -d "=" -f 2)"
    volume_down="$(echo "${recvmsg}" | grep "ZVendor-MaxByteIn[^-]" | cut -d "=" -f 2)"
    volume_down_4GB="$(echo "${recvmsg}" | grep "ZVendor-MaxByteIn-4GB" | cut -d "=" -f 2)"
fi

echo "$recvmsg"
if [ -n "$vdata" ]; then
    echo "_byte_amount = $vdata"
fi
exit $ret


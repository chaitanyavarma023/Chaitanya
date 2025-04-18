#!/bin/bash
# [Start|Stop|Interim-Update/Alive] user_mac traffic [Cause] [ac-nas-id] [current-vid]
type="$1"
user_mac="$2"
traffic="$3"
cause="$4"
roaming_nasid="$5"
roaming_vid="$6"

APNAME=`sh /ramfs/bin/get_assoc_AP_name.sh "${user_mac}"`

. /conf/etc/profile
. /ramfs/bin/radius_func

# Load user data from online file
if [ -n "${user_mac}" -a ! -f "/db/online/$user_mac" ]; then
    user_mac="$(grep "${user_mac}" /tmp/status/ppp_client |cut -d ' ' -f1)"
fi
[ -f "/db/online/${user_mac}" ] || exit

# Get prefix oid from trap_meta.db
function get_prefix_oid()
{
    trap_meta="/etc/snmp/db/trap_meta.db"
    prefix_oid=""
    for oid in $(sqlite -init /tmp/timeout.sql $trap_meta "select oid from trap_subtree_root where trap_class='ext_root' or trap_class='ac_radis_info'"); do
	prefix_oid="${prefix_oid}${oid}"
    done
    echo "$prefix_oid"
}

unset user
i=0; while read "user[$i]"; do let i=i+1; done < "/db/online/${user_mac}"
uname="${user[1]}"
fullname="${user[2]}"
group_index="${user[4]}"
mgmt_index="${user[5]}"
UTYPE="${user[6]}"
#srv_index="${user[7]}"
session="${user[10]}"
logintime="${user[12]}"
interim="${user[13]}"
auth_method="${user[22]}"
[ "${auth_method}" = "PPPoE" -o "${auth_method}" = "PPTP" ] && VMAC="N/A" || VMAC="${user_mac}"  # for rihistory
vlanid="${user[23]}"
[ ${vlanid} -gt 4096 -a ${vlanid} -lt 16777216 ] && VLAN_ID="$((vlanid/4096)).$((vlanid%4096))" || VLAN_ID="${vlanid}" # VLAN_ID only for rihistory
original_name="${user[24]}"
qosGroup="${user[21]}"
policy="${user[18]}"
user_ipv4="${user[0]}"
user_ipv6="${user[25]}"
sz_id="${user[26]}"
[ "${sz_id}" -lt 0 -o "${sz_id}" -gt "${VLAN_NUM}" ] && sz_id=""
MOBILE="${user[27]}"
AP_DEV_ID="${user[28]}" #split tunnel
SOCIAL_TYPE="${user[29]}"
OS="${user[30]}"
ORI_IP="${user[31]}"

# handle User-Name attribute os RADIUS packets
username="`get_username ${mgmt_index} \"${uname}\" \"${fullname}\" \"${original_name}\"`"
[ -z "${username}" ] && username="${uname}"

# format ip and find valid user ip (ipv4 or ipv6)
[ "$user_ipv4" == "0.0.0.0" ] && user_ipv4=""
[ "$user_ipv6" == "0000:0000:0000:0000:0000:0000:0000:0000" ] && user_ipv6=""
valid_user_ip=""
if [ -n "$user_ipv4" ]; then
    valid_user_ip="$user_ipv4"
elif [ -n "$user_ipv6" ]; then
    valid_user_ip="$user_ipv6"
fi

tIP="${user_ipv4}"
nIP=""
if [ "${AP_DEV_ID}" != "0" -a -n "${ORI_IP}" ]; then
    tIP="${ORI_IP}"
    nIP="${user_ipv4}"
fi

# Exit condition
[ "$UTYPE" != "RADIUS" ] && exit

# Loading server information

tmp_ra_path="/tmp/ra/${user_mac}"

# Prepare sending message attributes
#    User setting
calledid="`get_calledid`"
callingid="`get_callingid \"${user_mac}\"`"
[ -n "${tIP}" ] && framed_ip_address="${tIP}"

#    NAS Setting
NAS_ID="`get_nas_id \"${mgmt_index}\" \"${sz_id}\" \"${current_vlan_id}\" \"${user_mac}\"`"
NAS_Port_ID="`get_nas_port_id`"
NAS_Port_Type="`get_nas_port_type \"${mgmt_index}\"`"
NAS_Port="${vlanid}"
if [ -z "${NAS_Port}" ]; then
    NAS_Port="${current_vlan_id}"
fi
NAS_IP_Address="`get_nas_ip`"

# VSA attribute
http_user_agent="`get_http_user_agent \"${user_mac}\"`"
auth_method="`get_auth_method \"${user_mac}\"`"
current_vlan_id="`get_nas_port \"${valid_user_ip}\" \"${user_mac}\"`"
current_location_id="`get_wispr_location_id \"${sz_id}\" \"${current_vlan_id}\" \"${user_mac}\"`"
current_ac_id="${NAS_ID}"
sz_name="`get_file /db/sz/\"${sz_id}\"/name`"

if [ "$MOBILE" = "1" ]; then
    DEVICE_TYPE="Mobile"
else
    DEVICE_TYPE="N/A"
fi

# check if cross-gateway roaming
if [ -n "$current_vlan_id" ] && [ $current_vlan_id -ge 31932000 ]; then
    [ -n "${roaming_vid}" ] && current_vlan_id="${roaming_vid}"
    [ -n "${roaming_nasid}" ] && current_ac_id="${roaming_nasid}"
fi

# For Tunneled PLM : change NAS_Port to '31932000 + DEV-ID * 4096 + VID'
if [ $current_vlan_id -ge 31936096 ]; then
    NAS_Port="${current_vlan_id}"
fi

#    Accouting setting
Acct_Session_Id=""
tmp_Acct_Session_Id="$(grep -e "^ACCT-SESSION-ID=" ${tmp_ra_path}|cut -d"=" -f 2)"
if [ -n "${tmp_Acct_Session_Id}" ]; then
    Acct_Session_Id="${tmp_Acct_Session_Id}"
fi

tn=( $(date "+%Y-%m-%d %H:%M:%S %z %s") )
mtime="${logintime}"
ntime="${tn[3]}"
dtime=-1
CAUSE=""
if [ "${type}" != "Start" -a -n "$mtime" -a -n "$ntime" ]; then
    let dtime=ntime-mtime
fi
if [ "${type}" = "Stop" -a "" != "${cause}" ]; then
    CAUSE="Acct-Terminate-Cause=\"${cause}\""
    case "$(echo ${cause}|tr 'a-z' 'A-Z')" in
        "KICK OUT"*)
            CAUSE="Acct-Terminate-Cause=\"NAS-Request\""
            ;;
    esac
    if [ "${cause}" = "Idle-Timeout" ]; then
        IDLE="$(echo "${traffic}" | cut -d" " -f 5)"
        [ -z "${IDLE}" ] && IDLE=$( grep -e "^IDLE-TIMEOUT=" ${tmp_ra_path}|cut -d"=" -f 2)
        let dtime=dtime-IDLE
    fi
fi
if [ "$dtime" -lt 0 ]; then
    dtime=0
fi
Acct_Session_Time="${dtime}"
Acct_Delay_Time=""
[ -f /db/subscriber/mgmt/${mgmt_index}/radius/account_delay_time ] && Acct_Delay_Time="$(< /db/subscriber/mgmt/${mgmt_index}/radius/account_delay_time)"
Acct_Authentic="1"
event_timestamp=$(date +%s)

#    WISPR Setting
WISPr_Location_ID="$(grep -e "^WISPR-LOCATION-ID=" ${tmp_ra_path}|sed -e 's/WISPR-LOCATION-ID=//')"
WISPr_Location_Name="$(grep -e "^WISPR-LOCATION-NAME=" ${tmp_ra_path}|sed -e 's/WISPR-LOCATION-NAME=//')"
if [ -z "${WISPr_Location_ID}" ]; then
    WISPr_Location_ID="$(get_wispr_location_id "${sz_id}" "${NAS_Port}" "${user_mac}" "${auth_method}")"
fi
if [ -z "${WISPr_Location_Name}" ]; then
    WISPr_Location_Name="$(get_wispr_location_name "${sz_id}" "${NAS_Port}" "${user_mac}" "${auth_method}")"
fi

#    CLASS Setting
CLASS=""
for i in $(grep -e "^_class=" ${tmp_ra_path}|cut -d"=" -f 2); do
    if [ -z "${CLASS}" ]; then
        CLASS="Class=\"$i\""
    else
        CLASS="${CLASS},Class=\"$i\""
    fi
done

#    TRAFFIC Setting
if [ -n "${traffic}" ]; then
    TAC=( ${traffic} )
    AIC=($(( ${TAC[1]} /4294967296)) $(( ${TAC[1]} % 4294967296)))
    AOC=($(( ${TAC[3]} /4294967296)) $(( ${TAC[3]} % 4294967296)))
    TRAFFIC="Acct-Input-Octets=\"${AIC[1]}\",Acct-Output-Octets=\"${AOC[1]}\",Acct-Input-Packets=\"${TAC[0]}\",Acct-Output-Packets=\"${TAC[2]}\",Acct-Input-Gigawords=\"${AIC[0]}\",Acct-Output-Gigawords=\"${AOC[0]}\""
fi

##### replace customized attributes #####
WAN_IP="${NAS_IP_Address}"
WAN_MAC="${calledid}"
CLIENT_IP="${framed_ip_address}"
CLIENT_MAC="${callingid}"
SZ_SSID="$(get_file "/db/sz/${sz_id}/ssid")"
CURRENT_VLAN_ID="${current_vlan_id}"
TIMESTAMP="${event_timestamp}"
SESSION_ID="${Acct_Session_Id}"
LOCATION_ID="${WISPr_Location_ID}"
LOCATION_NAME="${WISPr_Location_Name}"
GET_PKTTYPE="/ramfs/bin/get_pkttype"
RADATTR_PATH="/db/custom_radattr"
[ -f ${RADATTR_PATH}/nas_ip ] && eval NAS_IP_Address=$( < ${RADATTR_PATH}/nas_ip)
[ -f ${RADATTR_PATH}/nas_id ] && eval NAS_ID=$( < ${RADATTR_PATH}/nas_id)
[ -f ${RADATTR_PATH}/nas_port ] && eval NAS_Port=$( <${RADATTR_PATH}/nas_port)
[ -f ${RADATTR_PATH}/callingid ] && eval callingid=$( < ${RADATTR_PATH}/callingid)
[ -f ${RADATTR_PATH}/calledid ] && eval calledid=$( < ${RADATTR_PATH}/calledid)
[ -f ${RADATTR_PATH}/asid ] && eval Acct_Session_Id=$( < ${RADATTR_PATH}/asid)
##### replace customized attributes #####

### handle the order of accounting-request attributes
[ "$(${GET_PKTTYPE} "User-Name" "${type}")" != "0" -a -n "${username}" ] && sendmsg="User-Name=\"${username}\""
[ "$(${GET_PKTTYPE} "Acct-Status-Type" "${type}")" != "0" -a -n "${type}" ] && sendmsg="${sendmsg},Acct-Status-Type=\"${type}\""
[ "$(${GET_PKTTYPE} "Framed-IP-Address" "${type}")" != "0" -a -n "${framed_ip_address}" ] && sendmsg="${sendmsg},Framed-IP-Address=\"${framed_ip_address}\""
[ "$(${GET_PKTTYPE} "Calling-Station-Id" "${type}")" != "0" -a -n "${callingid}" ] && sendmsg="${sendmsg},Calling-Station-Id=\"${callingid}\""
[ "$(${GET_PKTTYPE} "NAS-IP-Address" "${type}")" != "0" -a -n "${NAS_IP_Address}" ] && sendmsg="${sendmsg},NAS-IP-Address=\"${NAS_IP_Address}\""
[ "$(${GET_PKTTYPE} "Called-Station-Id" "${type}")" != "0" -a -n "${calledid}" ] && sendmsg="${sendmsg},Called-Station-Id=\"${calledid}\""
[ "$(${GET_PKTTYPE} "NAS-Port-Type" "${type}")" != "0" -a -n "${NAS_Port_Type}" ] && sendmsg="${sendmsg},NAS-Port-Type=\"${NAS_Port_Type}\""
[ "$(${GET_PKTTYPE} "NAS-Identifier" "${type}")" != "0" -a -n "${NAS_ID}" ] && sendmsg="${sendmsg},NAS-Identifier=\"${NAS_ID}\""
[ "$(${GET_PKTTYPE} "Event-Timestamp" "${type}")" != "0" -a -n "${event_timestamp}" ] && sendmsg="${sendmsg},Event-Timestamp=\"${event_timestamp}\""
# send CLASS when type is Start
[ "$(${GET_PKTTYPE} "Class" "${type}")" != "0" -a -n "${CLASS}" ] && sendmsg="${sendmsg},${CLASS}"
[ "$(${GET_PKTTYPE} "Acct-Session-Id" "${type}")" != "0" -a -n "${Acct_Session_Id}" ] && sendmsg="${sendmsg},Acct-Session-Id=\"${Acct_Session_Id}\""
# send Acct-Session-Time and TRAFFIC when type is Stop or Interim Update
[ "$(${GET_PKTTYPE} "Acct-Session-Time" "${type}")" != "0" -a -n "${Acct_Session_Time}" ] && sendmsg="${sendmsg},Acct-Session-Time=\"${Acct_Session_Time}\""  
[ "${type}" != "Start" -a -n "${TRAFFIC}" ] && sendmsg="${sendmsg},${TRAFFIC}"
# send CAUSE when type is Stop
[ "$(${GET_PKTTYPE} "Acct-Terminate-Cause" "${type}")" != "0" -a -n "${CAUSE}" ] && sendmsg="${sendmsg},${CAUSE}"
[ "$(${GET_PKTTYPE} "NAS-Port" "${type}")" != "0" -a -n "${NAS_Port}" ] && sendmsg="${sendmsg},NAS-Port=\"${NAS_Port}\""
[ "$(${GET_PKTTYPE} "NAS-Port-ID" "${type}")" != "0" -a -n "${NAS_Port_ID}" ] && sendmsg="${sendmsg},NAS-Port-ID=\"${NAS_Port_ID}\""
[ "$(${GET_PKTTYPE} "Acct-Delay-Time" "${type}")" != "0" -a -n "${Acct_Delay_Time}" ] && sendmsg="${sendmsg},Acct-Delay-Time=\"${Acct_Delay_Time}\""
[ "$(${GET_PKTTYPE} "Acct-Authentic" "${type}")" != "0" -a -n "${Acct_Authentic}" ] && sendmsg="${sendmsg},Acct-Authentic=\"${Acct_Authentic}\""
[ "$(${GET_PKTTYPE} "WISPr-Location-ID" "${type}")" != "0" -a -n "${WISPr_Location_ID}" ] && sendmsg="${sendmsg},WISPr-Location-ID=\"${WISPr_Location_ID}\""
[ "$(${GET_PKTTYPE} "WISPr-Location-Name" "${type}")" != "0" -a -n "${WISPr_Location_Name}" ] && sendmsg="${sendmsg},WISPr-Location-Name=\"${WISPr_Location_Name}\""
[ "$(${GET_PKTTYPE} "ZVendor-Http-User-Agent" "${type}")" != "0" -a -n "${http_user_agent}" ] && sendmsg="${sendmsg},ZVendor-Http-User-Agent=\"${http_user_agent}\""
[ "$(${GET_PKTTYPE} "ZVendor-Auth-Method" "${type}")" != "0" -a -n "${auth_method}" ] && sendmsg="${sendmsg},ZVendor-Auth-Method=\"${auth_method}\""
[ "$(${GET_PKTTYPE} "ZVendor-Current-VLAN-ID" "${type}")" != "0" -a -n "${current_vlan_id}" ] && sendmsg="${sendmsg},ZVendor-Current-VLAN-ID=\"${current_vlan_id}\""
[ "$(${GET_PKTTYPE} "ZVendor-Current-Location-ID" "${type}")" != "0" -a -n "${current_location_id}" ] && sendmsg="${sendmsg},ZVendor-Current-Location-ID=\"${current_location_id}\""
[ "$(${GET_PKTTYPE} "ZVendor-Service-Zone-Name" "${type}")" != "0" -a -n "${sz_name}" ] && sendmsg="${sendmsg},ZVendor-Service-Zone-Name=\"${sz_name}\""
[ "$(${GET_PKTTYPE} "ZVendor-Current-AC-ID" "${type}")" != "0" -a -n "${current_ac_id}" ] && sendmsg="${sendmsg},ZVendor-Current-AC-ID=\"${current_ac_id}\""
[ "$(${GET_PKTTYPE} "ZVendor-NAT-IP-Address" "${type}")" != "0" -a -n "${nIP}" ] && sendmsg="${sendmsg},ZVendor-NAT-IP-Address=\"${nIP}\""

echo "$sendmsg" > /tmp/radius_acct

# get qos info
if [ "${qosGroup}" = 0 ]; then
    grpid=100
else
    grpid="`printf '%03d' ${qosGroup}`"
fi
# get group name for log
g_path="/db/subscriber/group/${group_index}"
group_name="$(< "${g_path}"/Name)"

UFILE="/tmp/qos/tc/grp_${grpid}/usr_${user_ipv4}"
QOS_CONF="/tmp/qos/tc/config"
if [ -f "${UFILE}" ]; then
    . "${UFILE}"
    . "${QOS_CONF}"
    [ -n "${RATE_IN}" ] && reqDL="${RATE_IN}"
    if [ "$reqDL" = "2kbit" ]; then
        reqDL="Unlimited"
    fi
    [ -n "${RATE_OUT}" ] && reqUL="${RATE_OUT}"
    if [ "$reqUL" = "2kbit" ]; then
        reqUL="Unlimited"
    fi
    [ -n "${MAXRATE_IN}" ] && maxDL="${MAXRATE_IN}"
    if [ "$maxDL" = "${BOUND_IN}" ]; then
        maxDL="Unlimited"
    fi
    [ -n "${MAXRATE_OUT}" ] && maxUL="${MAXRATE_OUT}"
    if [ "$maxUL" = "${BOUND_OUT}" ]; then
        maxUL="Unlimited"
    fi
else	# Disble Bandwidth Limitation on WAN therefore QoS Setting is invalid.
    reqDL="Unlimited"
    reqUL="Unlimited"
    maxDL="Unlimited"
    maxUL="Unlimited"
fi

postfix=$(< "/db/subscriber/mgmt/${mgmt_index}/postfix")
if [ -n "${postfix}" -a -z "${postfix##.*}" ]; then
    #Record Format:
    #  RecTime Type UserName NasIdentifier NasIPAddress NasPort UsrIPAddress AcctSessionID
    #  Acct_Session_Id AcctSessionTime AcctInputOctets AcctOutputOctets AcctInputPackets AcctOutputPackets Message
    DT="${tn[0]}"
    RT="${tn[0]} ${tn[1]} ${tn[2]}"
    if [ -n "${TAC[0]}" ]; then
        T1="${TAC[1]}"
        T2="${TAC[3]}"
        T3="${TAC[0]}"
        T4="${TAC[2]}"
    else
        T1=0
        T2=0
        T3=0
        T4=0
    fi
    # handle Name field of rihistory. If ori_name with postfix then ori_name, else ori_name with auth_server's postfix.
    if [ "X${original_name}" = "X${original_name%@*}" ]; then
        log_name="${original_name}@$( < /db/subscriber/mgmt/${mgmt_index}/postfix)"
    else
        log_name="${original_name}"
    fi

    if [ ! -f "/db/rihistory/$DT" ]; then
        /ramfs/bin/create_history_note.sh "rihistory" "${DT}"
    fi

    echo -e "${RT}\t${type}\t${log_name//\\/\\\\}\t${NAS_ID}\t${NAS_IP_Address}\t${NAS_Port}\t${VMAC}\t${tIP}\t${user_ipv6}\t${Acct_Session_Id}\t${Acct_Session_Time}\t${T1}\t${T2}\t${T3}\t${T4}\t${cause}\t${VLAN_ID}\t${group_name}\t${policy}\t${maxDL}\t${maxUL}\t${reqDL}\t${reqUL}\tRoaming In\t${APNAME}\t${DEVICE_TYPE}\t${OS}\t${nIP}" >> "/db/rihistory/$DT" 
fi


#send radius acct packet
#This for loop will send radius acct packet to ACCT server 2 when ACCT server 1 doesn't reply ACCT-Response packet in each time to send radius acct packet
ACCT_flag=0
for i in 1 2
do
    # Failover
    if [ -f /db/subscriber/mgmt/${mgmt_index}/radius/swap_server_en -a "$( < /db/subscriber/mgmt/${mgmt_index}/radius/swap_server_en)" == "Enabled" -a -f "/tmp/deadacctsrv" ]; then
        if [ $( < /tmp/deadacctsrv) -eq 1 ]; then 
            srv_index=2
        else
            srv_index=1
        fi
    else
        srv_index=$i
    fi

    # check if acct enabled
    if [ "$srv_index" -le 2 ]; then
        [ "`get_acct_enable \"${mgmt_index}\" \"${srv_index}\"`" != "Enabled" ] && continue
    else
        [ "`get_acct_enable \"${mgmt_index}\" \"${srv_index}\"`" != "Enabled" ] && exit 100
    fi

    # Loading server information
    SERVER_IP="`get_acct_server_ip \"${mgmt_index}\" \"${srv_index}\"`"
    ACCOUNT_PORT="`get_acct_server_port \"${mgmt_index}\" \"${srv_index}\"`"
    SECRET_KEY="`get_acct_server_key \"${mgmt_index}\" \"${srv_index}\"`"
    NUM_RETRIES="`get_file /db/subscriber/mgmt/\"${mgmt_index}\"/radius/num_retries`"
    RETRIES_TIMEOUT="`get_file /db/subscriber/mgmt/\"${mgmt_index}\"/radius/retries_timeout`"


    recvmsg=$( echo "$sendmsg" | /usr/local/bin/radclient $SERVER_IP:$ACCOUNT_PORT acct $SECRET_KEY -r $NUM_RETRIES -t $RETRIES_TIMEOUT 2>/dev/null )

    ret=$?

    attr1="`echo $recvmsg | awk -F',' '{print $2;}' | awk '{print $1}'`"
    attr2="`echo $recvmsg | awk -F',' '{print $2;}' | awk '{print $2}'`"

    [ "$attr1" == "code" -a "$attr2" == "5" ] && ACCT_flag=1

    #Check clear trap
    let oid_index=$mgmt_index-1
    prefix_oid=$(get_prefix_oid)
    if [ "$srv_index" -eq "1" ]; then
        ipaddr_oid=8
        port_oid=9
    else
        ipaddr_oid=11
        port_oid=12
    fi
    snmp_trap_str="\n\n\n${prefix_oid}.1.1.${ipaddr_oid}.${oid_index} ${SERVER_IP}\n${prefix_oid}.1.1.${port_oid}.${oid_index} ${ACCOUNT_PORT}"
    snmp_radiusacct_f="/tmp/.#snmp_radiusacct_${mgmt_index}_${srv_index}"

    if [ "$attr1" == "code" ]; then
        if [ -f "$snmp_radiusacct_f" ]; then
            # if this server was unavailable before,then send available trap
            echo -e "$snmp_trap_str" | /ramfs/bin/immediate_trap.sh RadiusAccServerAvailableTrap
            rm -f "$snmp_radiusacct_f"
        fi
        break
    else
        if [ ! -f "$snmp_radiusacct_f" ]; then
            # if this server is unavailable first time, send unavailable trap
            echo -e "$snmp_trap_str" | /ramfs/bin/immediate_trap.sh RadiusAccServerUnavailableTrap
            touch "$snmp_radiusacct_f"
        fi
    fi

    # Failover
    if [ -f /db/subscriber/mgmt/${mgmt_index}/radius/swap_server_en -a "$( < /db/subscriber/mgmt/${mgmt_index}/radius/swap_server_en)" == "Enabled" ]; then
        if [ ${srv_index} -eq 1 ]; then
            live=2
        else 
            live=1
        fi
        deadserver=$( < "/db/subscriber/mgmt/${mgmt_index}/radius/acct_server_ip_${srv_index}")
        liveserver=$( < "/db/subscriber/mgmt/${mgmt_index}/radius/acct_server_ip_${live}")
        msg="Accounting Server ${deadserver} not responding, switching to Accounting Server ${liveserver}."
        logger -s "${msg}"
        echo "${srv_index}" > /tmp/deadacctsrv
    fi
done

if [ "$ACCT_flag" -eq 0 ]; then
    exit 100
fi

#for re-acct transmit
check=$(echo "$recvmsg" | grep '^Received.*code 5,')
if [ "$ret" = "0" -a -z "$check" ]; then
    #for radius 1.0.1, force to return 1
    ret=1
fi
if [ "$ret" != "0" ]; then
    if [ "${type}" = "Start" -o "${type}" = "Stop" ]; then
        echo "$sendmsg" > "/var/run/radius_acct/${ntime}_${user_mac}"
        echo "$srv_index" >> "/var/run/radius_acct/${ntime}_${user_mac}"
        echo "$mgmt_index" >> "/var/run/radius_acct/${ntime}_${user_mac}"
    fi
fi

#return result
echo "${recvmsg}"
exit $ret



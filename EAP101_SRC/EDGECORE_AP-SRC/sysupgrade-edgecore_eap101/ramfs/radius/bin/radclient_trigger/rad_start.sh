#!/bin/sh
. /conf/etc/profile
[ -z "${BIN_PATH}" ] && BIN_PATH="/ramfs/bin"
source ${BIN_PATH}/bluepill_func.sh
[ -z ${Auth_Server_Num} ] && Auth_Server_Num=5
nas=
proxy=
is_boot=0
for i in $*; do
  case "$i" in
    'nas')
      nas=1
      ;;
    'proxy')
      proxy=1
      ;;
    'is_boot')
      is_boot=1
      ;;
    *)
      ;;
  esac
done
if [ ! -d /var/run/radius_acct ]; then
  mkdir -p /var/run/radius_acct
  chown nobody.nogroup /var/run/radius_acct
fi
if [ ! -d /var/run/radius_update ]; then
  mkdir -p /var/run/radius_update
  chown nobody.nogroup /var/run/radius_update
fi

### touch /tmp/ppp_auth_en for pppoe
for ((j=0; j<=${VLAN_NUM}; j++)); do
    ppp_auth_en=$( < /db/vlan/$j/ppp_auth_en)
    if [ "${ppp_auth_en}" == "Enabled" ]; then
	touch /tmp/ppp_auth_en
	break
    fi
done
### touch /tmp/ppp_auth_en for pptp
[ ! -f /tmp/ppp_auth_en -a "$( < /db/pptpd/enable)" == "Enabled" ] && touch /tmp/ppp_auth_en

if [ -n "$nas" ]; then
  /ramfs/bin/rad_nas.sh
fi
if [ -n "$proxy" ]; then
  /ramfs/bin/mk_preproxy_conf.sh
  /ramfs/bin/rad_proxy.sh
fi

LOG_PLACE=/var/log
LOG_FILE=/radius_log
if [ -d "${SDCARD_PATH}" ]; then
	LOG_PLACE=${SDCARD_PATH}/radiuslog
fi

RADPID="$(ps ww | grep radius[d] | sort | /bin/sed -n '1p' | awk '{print $1}')"
if [ "$RADPID" != "" ]; then
    [ "${is_boot}" != "1" ] && del_service radiusd "0"
    killall radiusd
fi
TAILPID="$(ps ww | grep "radius\.log" | sort | /bin/sed -n '1p' | awk '{print $1}')"
if [ "$TAILPID" != "" ]; then
    kill $TAILPID
fi

function rad_start_cipacct()
{
    if [ "${is_boot}" = "1" ]; then
	[ -x /ramfs/radius/bin/rad_cipacct ] && /ramfs/radius/bin/rad_cipacct </dev/null >/dev/null 2>&1 &
    fi
}

function rad_start_and_exit()
{
    tail -f /var/log/radius.log | rotatelogs ${LOG_PLACE}${LOG_FILE} 1M &
    /ramfs/radius/sbin/radiusd &

    if [ -f "/ramfs/bin/util_sys.sh" ]; then
	source /ramfs/bin/util_sys.sh
	cpuVal=$(< /db/smp_affinity/other_process)
	[ -z "${cpuVal}" ] && cpuVal="ff"
	set_cpu radiusd ${cpuVal}
    fi

    [ "${is_boot}" = "1" ] || add_service radiusd "0"
    rad_start_cipacct
    exit
}

if [ -f /tmp/ppp_auth_en ]; then
    rm -f /tmp/ppp_auth_en
    rad_start_and_exit
fi

Capwap_en=$(< /db/capwap/capwap_status)
ikev2_enable=$(< /db/ikev2/enable)
for i in $(seq 1 ${Auth_Server_Num}) 103; do
    dot_one_X=$( < /db/subscriber/mgmt/$i/radius/8021x)
    Roamout=$( < /db/subscriber/mgmt/$i/local_roamingout)
    if [ "${dot_one_X}" == "Enabled" ] || [ "${Roamout}" == "Enabled" ] || [ "${Capwap_en}" == "Enabled" ] || [ "${ikev2_enable}" == "Enabled" ]; then
	rad_start_and_exit
    fi
done

# if DM & CoA then radiusd
while read line; do
    if [ ${line%%,*} -eq 3 ]; then
	rad_start_and_exit
    fi
done < /db/subscriber/radius/nas_list

rad_start_cipacct

#!/bin/sh
. /lib/functions.sh

sync_wifi_cmd_file="/tmp/mesh_sync_wifi.sh"
tar_mpp_wifi_file="/tmp/recived_wireless.tar.gz"
mpp_wifi_file="/tmp/wireless"

del_old_vaps() {
  local section_name="$1"
  [ -n "$section_name" -a "$section_name" != "wmesh" ] && {
    keeped_vap="`cat ${sync_wifi_cmd_file} | grep ${section_name}`"
    [ -z "$keeped_vap" ] && uci -q del wireless.$section_name
  }
}

for line in $(uci -c /tmp/ show wireless | grep wifi-iface)
do
  vap_radio="`echo $line | awk -F"=" '{print $1}'`"
  is_exist="`uci -q get $vap_radio`"
  [ -z "$is_exist" ] && uci -q set $line
done

uci -c /tmp/ show wireless | grep radio | grep wifi-iface | sort > ${sync_wifi_cmd_file}

uci -c /tmp/ show wireless | grep "wireless.radio" | grep "created\|\.device\|disabled\|encryption\|ifname\|\.key\|max_inactivity\|maxassoc\|\.mode\|multicast_to_unicast\|\.network\|ssid\|wds\|wpa_group_rekey\|country\|txpower\|max_txpwr\|hidden" | sort >> ${sync_wifi_cmd_file}

[ -f "${sync_wifi_cmd_file}" ] && {
  #delete exist vaps
  config_load wireless
  config_foreach del_old_vaps wifi-iface

  # generate command: uci set wireless.radioX_Y.xxxx=xxxx
  sed -i 's/^/uci -q set /' ${sync_wifi_cmd_file}

  for line in $(cat ${sync_wifi_cmd_file} | awk -F'.' '{print $2}' | sort | uniq)
  do
    broadcast_val="`cat ${sync_wifi_cmd_file} | grep ${line}.hidden`"
    [ "`echo  ${line} | grep '_'`" != "" ] && {
      [ -z "$broadcast_val" ] && {
        echo "uci -q del wireless.${line}.hidden" >> ${sync_wifi_cmd_file}
      }
    }
  done

  chmod 777 ${sync_wifi_cmd_file}
  #sync vaps from MPP
  . ${sync_wifi_cmd_file}
  uci commit wireless
}

rm -f ${mpp_wifi_file}
rm -f ${sync_wifi_cmd_file}
rm -f ${tar_mpp_wifi_file}
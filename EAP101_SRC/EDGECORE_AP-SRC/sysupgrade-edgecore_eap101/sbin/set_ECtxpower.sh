#!/bin/sh

. /lib/functions.sh
. /lib/acn/acn_functions.sh
. /usr/share/libubox/jshn.sh

DEVS="radio0_1 radio1_1 radio2_1"
PHYS="phy0 phy1 phy2"
LOGFILE="/tmp/log/set_ECtxpower.log"
LOGGING=0 #default is off

_log() {
    if [ ${LOGGING} -eq 1 ]; then
        local ts=$(date)
        echo "$ts $@" >> ${LOGFILE}
    fi
}

#wlan0 or wlan1 or wlan2
iface="$1"
channel_selected="$2"

MID=`acc hw get product_name | cut -d'=' -f2 | cut -d'-' -f1`
txpower_file_temp="/etc/fake_iw_reg/tx_power_template.json"
txpower_file_="/etc/fake_iw_reg/$MID/tx_power_"

#find radioX
for dev_data in ${DEVS}
do
  #ifname: radioX
  ifname="`uci get wireless.$dev_data.ifname 2>/dev/null`"

    if [ "$ifname" == "$iface" ]; then
        section_name="`uci get wireless.$dev_data.device 2>/dev/null`"
        break;
    fi
done

#find phyX
for phy_data in ${PHYS}
do
  #ifname: wlanX
  ifname=$(cat /var/run/hostapd-${phy_data}.conf | grep ^interface | cut -d'=' -f2)

    if [ "$ifname" == "$iface" ]; then
        phy_name="$phy_data"
        break;
    fi
done

htmode_now="`uci get wireless.$section_name.htmode 2>/dev/null | grep -o -E '[0-9]+'`"
hwmode_now="`uci get wireless.$section_name.hwmode 2>/dev/null | grep -o -E '[a-z]+'`"
band="`uci get wireless.$section_name.band 2>/dev/null`"
uci_tx="`uci get wireless.$section_name.txpower 2>/dev/null`"

cert=$(get_TxPowerCert_info)

txpower_file="${txpower_file_}${cert}.json"

if [ ! -s "$txpower_file" ]; then
  txpower_file="${txpower_file_}FCC.json"
fi

_log "set_ECtxpower begins"
_log "channel_selected: $channel_selected"
_log "iface: $iface"

json_init
json_load_file $txpower_file

json_get_keys radios

for radio in $radios; do
  #echo $radio

  if [ "$radio" == "$band" ]; then
    json_select $radio
    json_get_keys chs
    for ch in $chs; do
      _log "channel: $ch"
      if [ "$ch" == "$channel_selected" ]; then
        json_select $ch
        json_get_keys hwmodes
        for hwmode in $hwmodes; do
          _log "hwmode: $hwmode"
          if [ "$hwmode" == "$hwmode_now" ]; then
            json_select $hwmode
            json_get_keys htmodes
            for htmode in $htmodes; do
              _log "htmode: $htmode"
              if [ "$htmode" == "$htmode_now" ]; then
                json_get_var txpower $htmode
                _log "$txpower"

                if [ "$uci_tx" -gt "$txpower" ]; then
                  iw phy "$phy_name" set txpower fixed "${txpower%%.*}00"
                else
                  iw phy "$phy_name" set txpower fixed "${uci_tx%%.*}00"
                fi
                break;
              fi

            done
            break;
          fi

        done
        break;
      fi

    done
  fi

done

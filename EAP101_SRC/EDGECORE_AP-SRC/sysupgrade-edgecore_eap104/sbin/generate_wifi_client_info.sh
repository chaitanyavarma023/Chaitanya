#!/bin/sh

. /usr/share/libubox/jshn.sh

radio_info="/tmp/ep_radio_info.json"
vap_info="/tmp/ep_vap_info.json"
peer_info="/tmp/ep_peer_info.json"
iw_station_dump="/tmp/ep_iw_dump"
dhcp_list="/tmp/ep_dhcp.list"
wifi_client_json="/tmp/wifi_clients.json"
system_mac="`sed s/://g /sys/class/net/eth0/address`"

parse_clients() {
  local radio radios
  local is_radio_added=false
  local is_vap_added=false
  local is_client_added=false

  json_load "$(ubus call luci-rpc getWirelessDevices)"
  json_get_keys radios

  if [ "$radios" != "" ]; then
    echo "  \"radios\": {" > $radio_info
    echo "    \"dev\": {" >> $radio_info

    echo "," > $vap_info
    echo "  \"vaps\": [" >> $vap_info

    echo "," > $peer_info
    echo "  \"peers\": [" >> $peer_info
  fi

  for radio in $radios; do
    echo "      \"$radio\": {" >> $radio_info

    local iface ifaces

    json_select $radio
    json_select interfaces

    json_get_keys ifaces

    for iface in $ifaces; do

      local ifname section frequency radio_mac vap_mac ssid
      local limit_up_enable limit_up limit_down_enable limit_down disabled

      json_select $iface
      json_get_var ifname ifname
      json_get_var section section
      
      if [ -n "$(echo $ifname | grep wlan | awk -F. '{print $1}')" -a -z "$(echo $ifname | awk -F. '{print $2}')" ]; then

        iw $ifname station dump > $iw_station_dump.$ifname

        local tmp_peer="/tmp/ep_peer_tmp_info.json"
        local is_mac_added=false
        local is_signal_added=false

        while read LINE
        do
          mac_value="$(echo $LINE | grep 'Station' | awk '{print toupper($2)}')"
          host_name="\"\""
          [ -n "$mac_value" ] && {
            is_mac_added=true
            _mac_value="$(echo $mac_value | sed 's/://g' | awk '{print tolower($0)}')"
            echo "    {" >> $tmp_peer
            echo "      \"mac\": \"$_mac_value\"," >> $tmp_peer
            echo "      \"vap\": \"$ifname\"," >> $tmp_peer

            host_name=$(cat $dhcp_list | grep $mac_value | awk -F "=" '{print $2}')
          }

          signal_value="$(echo $LINE | grep 'signal' | awk '{print $2}' | grep -E '^-[0-9]+$')"


          [ -n "$signal_value" ] && {
            is_signal_added=true
            echo "      \"signal\": [" >> $tmp_peer
            echo "        $signal_value," >> $tmp_peer
            echo "        $signal_value" >> $tmp_peer
            echo "      ]," >> $tmp_peer
            echo "      \"hostname\": $host_name" >> $tmp_peer
            echo "    }," >> $tmp_peer
          }
          if [ "$is_mac_added" == true -a "$is_signal_added" == true ]; then
            cat $tmp_peer >> $peer_info
            rm -f $tmp_peer

            is_client_added=true
            is_mac_added=false
            is_signal_added=false
          fi
        done < $iw_station_dump.$ifname
        rm -f $iw_station_dump.$ifname

        json_select iwinfo
        
        json_get_var frequency frequency
        [ $iface == "1" ] && {

          json_get_var radio_mac bssid
          radio_mac="$(echo $radio_mac | sed 's/://g' | awk '{print tolower($0)}')"

          if [ "$radio_mac" != "" -a "$frequency" != "" ]; then
            is_radio_added=true
            echo "        \"mac\": \"$radio_mac\"," >> $radio_info
            echo "        \"frequency\": $frequency" >> $radio_info
          fi

        }

        json_get_var vap_mac bssid
        json_get_var ssid ssid
        vap_mac="$(echo $vap_mac | sed 's/://g' | awk '{print tolower($0)}')"
        section="$(echo $section | sed 's/_.*//g')"

        if [ "$vap_mac" != "" -a "$ssid" != "" ]; then
          is_vap_added=true
          echo "    {" >> $vap_info
          echo "      \"mac\": \"$vap_mac\"," >> $vap_info
          echo "      \"ssid\": \"$ssid\"," >> $vap_info
          echo "      \"name\": \"$ifname\"," >> $vap_info
          echo "      \"radio\": \"$section\"" >> $vap_info
          echo "    }," >> $vap_info
        fi

        json_select ..
      fi
      json_select ..
    done
    json_select ..
    json_select ..

    echo "      }," >> $radio_info

  done

  if [ "$radios" != "" ]; then
    #remove last ","
    sed -i '$ s/,$//' $radio_info

    echo "    }" >> $radio_info
    echo -n "  }" >> $radio_info

    #remove last ","
    sed -i '$ s/,$//' $vap_info
    echo -n "  ]" >> $vap_info

    #remove last ","
    sed -i '$ s/,$//' $peer_info
    echo -n "  ]" >> $peer_info
  fi

  if [ "$is_client_added" == true ]; then

    [ "$is_radio_added" == false ] && rm -f $radio_info
    [ "$is_vap_added" == false ] && rm -f $vap_info

    if [ -f $radio_info -o -f $vap_info -o -f $peer_info ]; then
      echo "{" > $wifi_client_json
      if [ "$system_mac" != "" ]; then
        echo "  \"system\": {"  >> $wifi_client_json
        echo "    \"mac\": \"$system_mac\"" >> $wifi_client_json
        echo "  },"  >> $wifi_client_json
      fi
      cat $radio_info $vap_info $peer_info >> $wifi_client_json
      echo "" >> $wifi_client_json
      echo "}" >> $wifi_client_json
    fi
  fi
}

parse_hostname() {
   ubus call luci getECDhcpList | sed  '/\"ipv[4,6]\":/d' | xargs echo | sed 's/{ //g' | sed 's/: name: /="/g' | sed 's/, }, /"\n/g' | sed 's/, } }/"/g' > $dhcp_list
}

rm -f ${wifi_client_json}
parse_hostname
parse_clients
rm -f /tmp/ep_*

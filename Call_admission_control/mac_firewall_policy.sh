#!/bin/sh
#|===================================================================================================================================================
#|      FILE            :  mac_firewall_policy.sh
#|      PATH            :  /usr/lib/lua/luci/ap/
#|      USAGE           :  Accept/Drop client to client connection based on MAC OUI
#|      ARGUMENTS       :  2 arguments : 'WLAN_name' 'Source MAC Address/isolation/intra_vlan/inter_vlan'
#|                         3 arguments : 'WLAN_name' 'disable/isolation/intra_vlan/inter_vlan' 'maclist' 'revision_no'
#|                          e.g. sh /usr/lib/lua/luci/ap/client_isolation.sh 'WLAN123' '1'
#|                               sh /usr/lib/lua/luci/ap/client_isolation.sh 'WLAN123' '1' 'a4:5e:60:af:62:95,11:22:33:44:55:66' '100'
#|                              $1 : wlan name where the feature has to be applied
#|                              $2 : 0 for disable
#|                                   1 for enable ( isolation / intra vlan / inter vlan )
#|                         3 arguments :
#|                          e.g. sh /usr/lib/lua/luci/ap/client_isolation.sh whitelist 1 a4:5e:60:af:62:95=192.168.7.49,33:22:11:22:33:11=192.168.8.22 100
#|                               sh /usr/lib/lua/luci/ap/client_isolation.sh whitelist 1 a4:5e:60:af:62:95,11:22:33:44:55:66 100
#|                               sh /usr/lib/lua/luci/ap/client_isolation.sh whitelist 0 a4:5e:60:af:62:95=192.168.7.49,33:22:11:22:33:11=192.168.8.22 100
#|                               sh /usr/lib/lua/luci/ap/client_isolation.sh whitelist 0 a4:5e:60:af:62:95,11:22:33:44:55:66 100
#|                             $1 : string "whitelist"
#|                             $2 : 1 or 0 for add or delete
#|                             $3 : mac list
#|                             $4 : revision no.
#|      RETURN VALUE    :  NULL
#|===================================================================================================================================================



ebtables -A FORWARD -i wlan1 -s 04:ea:56:23:74:70 -d 2c:be:eb:97:45:45 -j DROP
ebtables -A FORWARD -i wlan1 -s 2c:be:eb:97:45:45 -d 04:ea:56:23:74:70 -j DROP
ebtables -A FORWARD -i wlan0 -s 04:ea:56:23:74:70 -d 2c:be:eb:97:45:45 -j DROP
ebtables -A FORWARD -i wlan0 -s 2c:be:eb:97:45:45 -d 04:ea:56:23:74:70 -j DROP

ebtables -A FORWARD -i $interface -s $sourcemax -d $destmac -j $target
ebtables -A FORWARD -i $interface -s $sourcemax -d $destmac -j $target
ebtables -A FORWARD -i $interface -s $sourcemax -d $destmac -j $target
ebtables -A FORWARD -i $interface -s $sourcemax -d $destmac -j $target



ebtables  -A FORWARD -i $interface -s 04:ea:56:00:00:00/FF:FF:FF:00:00:00 -d 58:61:63:00:00:00/FF:FF:FF:00:00:00 -j DROP
ebtables  -A FORWARD -i $interface -s 04:ea:56:00:00:00/FF:FF:FF:00:00:00 -d 58:61:63:00:00:00/FF:FF:FF:00:00:00 -j DROP
ebtables  -A FORWARD -i $interface -s 58:61:63:00:00:00/FF:FF:FF:00:00:00 -d 04:ea:56:00:00:00/FF:FF:FF:00:00:00 -j DROP
ebtables  -A FORWARD -i $interface -s 58:61:63:00:00:00/FF:FF:FF:00:00:00 -d 04:ea:56:00:00:00/FF:FF:FF:00:00:00 -j DROP

ebtables  -A FORWARD -i $interface -s $sourcemaxoui -d $destmacoui -j $target
ebtables  -A FORWARD -i $interface -s $sourcemaxoui -d $destmacoui -j $target
ebtables  -A FORWARD -i $interface -s $sourcemaxoui -d $destmacoui -j $target
ebtables  -A FORWARD -i $interface -s $sourcemaxoui -d $destmacoui -j $target

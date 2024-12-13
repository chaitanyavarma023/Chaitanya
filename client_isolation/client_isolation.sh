#!/bin/sh
#|===================================================================================================================================================
#|      FILE            :  client_isolation.sh
#|      PATH            :  /usr/lib/lua/luci/ap/
#|      USAGE           :  isolates the client client connected the WLAN
#|      ARGUMENTS       :  2 arguments : 'WLAN_name' 'disable/isolation/intra_vlan/inter_vlan'
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
[ ! -d /usr/lib/lua/luci/L3 ] && mkdir /usr/lib/lua/luci/L3
[ "$1" == "configure_wan" -a "$(cat /usr/lib/lua/luci/L3/Client_Isolation |egrep -v '# wan|exit 0' |wc -l)" == "0" ] && exit 0
######################################   LOAD THE MODULES IF NOT LOADED ALREADY TO USE EBTABLES #############################################################
[ "$(lsmod|grep -w ebt_802_3)" -o "$2" != '1' ] || sh /usr/lib/lua/luci/ap/module_manager.sh load ebtables
######################################## Intialise variables ############################################
wlan=$1 ; action=$2 ; maclist=$3 ; revision=$4
vlan_name='' ; vlan_gateway='' ; vlan_mask='' 
vlan_name=$(uci get wireless.$(uci show wireless|grep "\.name='$1"|head -1|cut -d . -f2).network|cut -d _ -f1)
if [ "$vlan_name" != 'wan' ]; then
	#################### Update Network Configs Required #########################
	if [ "$2" == '0' -a ! "$(uci show opennds|grep "\.used_bridge='br-"$vlan_name"'")" -a "$(uci -q get network."$vlan_name".comment)" != 'nat-r' ]; then
		uci set network."$vlan_name".proto=none
		uci commit network ; /etc/init.d/network reload
	fi
	sleep 2
	################### Get Vlan Gateway & NetMask ####################
	vlan_gateway=$(ifstatus $vlan_name|jsonfilter -e @.route[*].nexthop|grep -v "0.0.0.0")
	[ "$vlan_gateway" ] || vlan_gateway=$(ifstatus $vlan_name|jsonfilter -e @.inactive.route[*].nexthop|grep -v "0.0.0.0")
	[ "$vlan_gateway" ] || vlan_gateway=$(ifstatus $vlan_name|jsonfilter -e '@["ipv4-address"][*].address')
	[ "$vlan_gateway" ] || { [ "$(uci show network|grep 'network.route.*.interface'|grep -w $vlan_name)" ] && vlan_gateway=$(uci -q get $(uci show network|grep 'network.route.*.interface'|grep -w $vlan_name|cut -d . -f1-2).gtw) ; }
	[ "$vlan_gateway" ] || { udhcpc -s /lib/netifd/dhcp.script -i br-"$vlan_name" -fqnR 1&>/tmp/"$vlan_name".dhcp ; vlan_gateway=$(cat /tmp/"$vlan_name".dhcp | grep 'unicasting a release' | awk -F ' to ' '{print $2}') ; }
	vlan_mask=$(ifstatus $vlan_name|jsonfilter -e '@["ipv4-address"][*].mask')
	[ "$vlan_mask" ] || { [ "$(uci show network|grep 'network.route.*.interface'|grep -w $vlan_name)" ] && vlan_mask=$(uci -q get $(uci show network|grep 'network.route.*.interface'|grep -w $vlan_name|cut -d . -f1-2).netmask) ; }
fi
#######################################  Check CONFIGURATION   #################################################
last_check()
{
	######################################   MAINTAINING EXIT VALUE IN FILE WHICH IS CONTAIING THE RULES    #############################################################
	sed -i '/exit/d' $mainfile
	[ "$(cat /usr/lib/lua/luci/L3/Client_Isolation 2&>/dev/null |grep -c ebtables)" != 0 ] && echo "exit 0" >> /usr/lib/lua/luci/L3/Client_Isolation
	######################################   UNLOAD THE MODULES IF NO FEATURE IS USING THE EBTABLES  #############################################################
	[ "$(cat /usr/lib/lua/luci/L3/* | grep 'ebtables -'| grep -cv wan)" == "0" -a ! -s /usr/lib/lua/luci/L3/Client_Isolation ] && sh /usr/lib/lua/luci/ap/module_manager.sh unload ebtables
	######################################   EXIT ONLY IF CALLED FOR WAN CHANGE UPDATE   #############################################################
	[ "$1" == "configure_wan" ] && exit 0
}
#######################################  ENV CONFIGURATION   #################################################
configure_isolate()
{
	for no in $(ebtables -t broute -L ISOLATE --Ln | grep -w "j RETURN" | cut -d. -f1| sort -rn);do ebtables -t broute -D ISOLATE $no ;done
	sed -i '/wan/d' $mainfile
	[ "$1" == "configure_wan" -a "$(cat /usr/lib/lua/luci/L3/Client_Isolation |egrep -v '# wan|exit 0' |wc -l)" == "0" ] && return
	wan_setup $1 "$(cat /usr/lib/lua/luci/internet/WanConf | jsonfilter -e @.Primary.Wan)"
	wan2="$(cat /usr/lib/lua/luci/internet/WanConf | jsonfilter -e @.Secondary.Wan)"
	[ "$wan2" != '' ] && wan_setup $1 $wan2
	last_check $1
}
#######################################  GATEWAY AND DNSs RULES FOR EACH WAN   #################################################
wan_setup()
{
	status=$(ifstatus $2)
	if [ "$(echo $status|jsonfilter -e @.up)" == "true" ];then
		# IF WAN IS UP THEN WE CAN GET THE DATA SO NEED TO CALL FROM THE CRONTAB
		(crontab -l | sed "/client_isolation.sh/d") | crontab -
		/etc/init.d/cron restart
	else
		# IF WAN IS NOT UP THEN AFTER A MIN THIS WILL GOING TO CALL AGAIN FROM THE CRONTAB
		(crontab -l | sed "/client_isolation.sh/d") | crontab -
		(crontab -l ; echo "* * * * * sh /usr/lib/lua/luci/ap/client_isolation.sh configure_wan") | crontab -
		/etc/init.d/cron restart
	fi
	gateway=$(echo $status | jsonfilter -e @.route[*].nexthop| grep -v "0.0.0.0")
	ap_address=$(echo $status | jsonfilter -e '@["ipv4-address"][*].address')
	# CREATE THE RULES ONLY WHEN DATA IS AVALAIBLE
	if [ "$gateway" != '' ] ;then
		dns1=$(echo $status | jsonfilter -e '@["dns-server"][0]')
		dns2=$(echo $status | jsonfilter -e '@["dns-server"][1]')
		# CHECKING IF THE FILE IS EMPTY OF NOT
		[ -s /usr/lib/lua/luci/L3/Client_Isolation ] && mainfilie_is_empty=1 || mainfilie_is_empty=0
		# INSERTING THE RULES AT THE BEGINING
		[ "$dns1" != '' -a "$gateway" != "$dns1" ] && {
			ebtables -t broute -I ISOLATE -p IPv4 --ip-dst $dns1 -j RETURN
			if [ $mainfilie_is_empty ];then
				echo "ebtables -t broute -I ISOLATE -p IPv4 --ip-dst $dns1 -j RETURN # $2" >> $mainfile
			else
				sed -i '1i ebtables -t broute -I ISOLATE -p IPv4 --ip-dst '$dns1' -j RETURN #'$2'' $mainfile
			fi
		}
		[ "$dns2" != '' -a "$dns2" != "$dns1" ] && {
			ebtables -t broute -I ISOLATE -p IPv4 --ip-dst $dns2 -j RETURN
			if [ $mainfilie_is_empty ];then
				echo "ebtables -t broute -I ISOLATE -p IPv4 --ip-dst $dns2 -j RETURN # $2" >> $mainfile
			else
				sed -i '1i ebtables -t broute -I ISOLATE -p IPv4 --ip-dst '$dns2' -j RETURN # '$2'' $mainfile
			fi
		}
		[ "$ap_address" != '' ] && {
			ebtables -t broute -I ISOLATE -p IPv4 --ip-dst $ap_address -j RETURN
			if [ $mainfilie_is_empty ];then
				echo "ebtables -t broute -I ISOLATE -p IPv4 --ip-dst $ap_address -j RETURN # $2" >> $mainfile
			else
				sed -i '1i ebtables -t broute -I ISOLATE -p IPv4 --ip-dst '$ap_address' -j RETURN # '$2'' $mainfile
			fi
		}
		ebtables -t broute -I ISOLATE -p IPv4 --ip-dst $gateway -j RETURN
		if [ $mainfilie_is_empty ];then
			echo "ebtables -t broute -I ISOLATE -p IPv4 --ip-dst $gateway -j RETURN # $2" >> $mainfile
		else
			sed -i '1i ebtables -t broute -I ISOLATE -p IPv4 --ip-dst '$gateway' -j RETURN # '$2'' $mainfile
		fi
	fi
}
######################################   MAIN    #############################################################
mainfile=/usr/lib/lua/luci/L3/Client_Isolation
whitelist_file=/usr/lib/lua/luci/L3/Client_Isolation_whitelist
######################################### UPDATE THE WAN RULES IF NOT PRESENT #########################################################
[ "$1" == "configure_wan" ] && configure_isolate $1
######################################### DELETE WHITE MACLIST #########################################################
[ "$action" == "0" -o "$#" -gt "2" ] && sed -i '/'$wlan'/d' $whitelist_file
######################################### ADD WHITE MACLIST #########################################################
[ "$#" -gt "2" -a "$action" == "1" ] && echo "$wlan#$maclist" >> $whitelist_file
IF_2=$(uci -q get $(uci show wireless|grep ".name='"$wlan"_2'"|cut -f 1,2 -d .).ifname)
IF_5=$(uci -q get $(uci show wireless|grep ".name='"$wlan"_5'"|cut -f 1,2 -d .).ifname)
######################################### DELETING THE RULES IF PRESENT IN FILE #########################################################
sed -i '/'$wlan'$/d' $mainfile
######################################### DELETING THE RULES IF PRESENT #########################################################
[ "$IF_2" != '' ] && for no in $(ebtables -t broute -L CLIENT_ISOLATION --Ln |tr -d '-'| grep -w $(echo $IF_2|tr -d '-')|cut -d. -f1|sort -nr); do ebtables -t broute -D CLIENT_ISOLATION $no ;done
[ "$IF_5" != '' ] && for no in $(ebtables -t broute -L CLIENT_ISOLATION --Ln |tr -d '-'| grep -w $(echo $IF_5|tr -d '-')|cut -d. -f1|sort -nr); do ebtables -t broute -D CLIENT_ISOLATION $no ;done
[ "$1" != "configure_wan" -a "$wlan" != '' ] && { ebtables -t broute -F "$wlan"_ISOLATE ; ebtables -t broute -X "$wlan"_ISOLATE ; }
if [ "$action" == "1" -o "$#" -gt "2" ] ;then
	Intra_Vlan=$(uci -q get $(uci show wireless|grep ".name='"$wlan""|cut -f 1,2 -d .|head -1).intra_vlan)
	Inter_Vlan=$(uci -q get $(uci show wireless|grep ".name='"$wlan""|cut -f 1,2 -d .|head -1).inter_vlan)
	if [ "$Intra_Vlan" == '1' -a "$Inter_Vlan" == '0' ]; then
		comment="Intra Vlan Disabled $wlan"
	elif [ "$Intra_Vlan" == '0' -a "$Inter_Vlan" == '1' ]; then
		comment="Inter Vlan Disabled $wlan"
	else
		comment="Isolation $wlan"
	fi
	######################################### APPLYING THE RULES #########################################################
	ebtables -t broute -N "$wlan"_ISOLATE
	echo 'ebtables -t broute -N '$wlan'_ISOLATE # '$comment'' >> $mainfile
	ebtables -t broute -P "$wlan"_ISOLATE RETURN
	echo 'ebtables -t broute -P '$wlan'_ISOLATE  RETURN # '$comment'' >> $mainfile
	if [ "$IF_2" != "" ]; then
		ebtables -t broute -A CLIENT_ISOLATION -i $IF_2 -j "$wlan"_ISOLATE
		echo 'ebtables -t broute -A CLIENT_ISOLATION -i '$IF_2' -j '$wlan'_ISOLATE # '$comment'' >> $mainfile
	fi
	if [ "$IF_5" != "" ]; then
		ebtables -t broute -A CLIENT_ISOLATION -i $IF_5 -j "$wlan"_ISOLATE
		echo 'ebtables -t broute -A CLIENT_ISOLATION -i '$IF_5' -j '$wlan'_ISOLATE # '$comment'' >> $mainfile
	fi
	####### CREATING WHITELIST FOR EACH INTERFACE #######
	whitelist=$(grep -w $wlan $whitelist_file| cut -d# -f2|head -1)
	if [ "$whitelist" != '' ]; then
		for pair in $(echo $whitelist|tr ',' '\n')
		do
			mac=$(echo $pair|cut -d = -f1) ; ip=$(echo $pair|cut -d = -f2)
			ebtables -t broute -I "$wlan"_ISOLATE -p IPv4 --ip-dst $ip -j RETURN
			echo 'ebtables -t broute -I '$wlan'_ISOLATE -p IPv4 --ip-dst '$ip' -j RETURN # '$comment'' >> $mainfile
			ebtables -t broute -I "$wlan"_ISOLATE -p IPv4 --ip-src $ip -j RETURN
			echo 'ebtables -t broute -I '$wlan'_ISOLATE -p IPv4 --ip-src '$ip' -j RETURN # '$comment'' >> $mainfile
			ebtables -t broute -I "$wlan"_ISOLATE -d $mac -j RETURN
			echo 'ebtables -t broute -I '$wlan'_ISOLATE -d '$mac' -j RETURN # '$comment'' >> $mainfile
			ebtables -t broute -I "$wlan"_ISOLATE -s $mac -j RETURN
			echo 'ebtables -t broute -I '$wlan'_ISOLATE -s '$mac' -j RETURN # '$comment'' >> $mainfile
		done
	fi
	####### For Vlan Tagged SSID #######
	if [ "$vlan_gateway" != '' ]; then
		ebtables -t broute -I "$wlan"_ISOLATE -p IPv4 --ip-dst $vlan_gateway -j RETURN
		echo 'ebtables -t broute -I '$wlan'_ISOLATE -p IPv4 --ip-dst '$vlan_gateway' -j RETURN # '$comment'' >> $mainfile
	else
		vlan_gateway=$(ifstatus $vlan_name|jsonfilter -e @.route[*].nexthop|grep -v "0.0.0.0")
		vlan_mask=$(ifstatus $vlan_name|jsonfilter -e '@["ipv4-address"][*].mask')
	fi
	####### For Captive Portal SSID #######
	if [ "$(uci -q get opennds.$1)" ]; then
		address=$(ifstatus $vlan_name|jsonfilter -e '@["ipv4-address"][*].address')
		gatewayport=$(uci -q get opennds."$1".gatewayport)
		[ "$address" -a "$gatewayport" ] && nds_conf="-p IPv4 --ip-dst $address --ip-proto tcp --ip-dport $gatewayport"
		if [ "$nds_conf" ]; then
			ebtables -t broute -I "$wlan"_ISOLATE $nds_conf -j ACCEPT
			echo 'ebtables -t broute -I '$wlan'_ISOLATE '$nds_conf' -j ACCEPT # '$comment'' >> $mainfile
		fi
	fi
	####### For Intra Vlan Disable #######
	if [ "$Intra_Vlan" == '1' -a "$Inter_Vlan" == '0' -a "$vlan_gateway" != '' ]; then
		ebtables -t broute -I "$wlan"_ISOLATE -p IPv4 --ip-dst ! "$vlan_gateway"/"$vlan_mask" -j RETURN
		echo 'ebtables -t broute -I '$wlan'_ISOLATE -p IPv4 --ip-dst ! '$vlan_gateway'/'$vlan_mask' -j RETURN # '$comment'' >> $mainfile
	fi
	####### For Inter Vlan Disable #######
	if [ "$Intra_Vlan" == '0' -a "$Inter_Vlan" == '1' -a "$vlan_gateway" != '' ]; then
		ebtables -t broute -I "$wlan"_ISOLATE -p IPv4 --ip-dst "$vlan_gateway"/"$vlan_mask" -j RETURN
		echo 'ebtables -t broute -I '$wlan'_ISOLATE -p IPv4 --ip-dst '$vlan_gateway'/'$vlan_mask' -j RETURN # '$comment'' >> $mainfile
	fi
	ebtables -t broute -A "$wlan"_ISOLATE -j ISOLATE
	echo 'ebtables -t broute -A '$wlan'_ISOLATE -j ISOLATE # '$comment'' >> $mainfile
fi
##############################################################################################################
configure_isolate 'configure_wan'
last_check 
[ "$revision" -gt "0" ]  && echo "$revision" > /etc/RevisionNo
exit 0
##############################################################################################################

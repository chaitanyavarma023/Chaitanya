#!/bin/sh

. /conf/etc/profile
[ -z ${Auth_Server_Num} ] && Auth_Server_Num=5
. /ramfs/bin/radius_func

if [ ! -d /var/run/radius_acct ]; then
  mkdir -p /var/run/radius_acct
  chown nobody.nogroup /var/run/radius_acct
fi
if [ ! -d /var/run/radius_update ]; then
  mkdir -p /var/run/radius_update
  chown nobody.nogroup /var/run/radius_update
fi

NAS_IP="`get_nas_ip`"
calledid="`get_calledid`"
wan_mac=$(echo ${calledid} |tr -d "-" |tr "A-Z" "a-z")

for mgmt_index in $(seq 1 ${Auth_Server_Num}); do
        Enabled=`cat /db/subscriber/mgmt/${mgmt_index}/mgmt_enable`
        Service_Type=$(get_service_type ${mgmt_index})
        if [ "$Enabled" = "Enabled" ]; then
		UTYPE=`cat /db/subscriber/mgmt/${mgmt_index}/utype`
		if [ "$UTYPE" = "RADIUS" ]; then
			NASID="`get_nas_id \"${mgmt_index}\"`"
			Nas_Port_Type="`get_nas_port_type \"${mgmt_index}\"`"
			let "srv_index=1"
			acctCnt="`get_acctCnt`"
			while [ ${srv_index} -le 2 ]
			do
				ACCT_SERVICE="`get_acct_enable \"${mgmt_index}\" \"${srv_index}\"`"
				if [ "$ACCT_SERVICE" = "Enabled" ]; then				
					SERVER_IP="`get_acct_server_ip \"${mgmt_index}\" \"${srv_index}\"`"
					ACCOUNT_PORT="`get_acct_server_port \"${mgmt_index}\" \"${srv_index}\"`"
					SECRET_KEY="`get_acct_server_key \"${mgmt_index}\" \"${srv_index}\"`"
					NUM_RETRIES="`get_file /db/subscriber/mgmt/\"${mgmt_index}\"/radius/num_retries`"
					RETRIES_TIMEOUT="`get_file /db/subscriber/mgmt/\"${mgmt_index}\"/radius/retries_timeout`"
					wan_mac=$(cat /db/wan/mac | sed -e "s/://g" |tr "A-Z" "a-z")  # lower case wan mac
					if [ -n "${SERVER_IP}" ]; then
						# Sending Accounting-On/Accounting-Off to RADIUS Server, Bug #4205
						# If the file /db/subscriber/mgmt/$mgmt_index/radius/acct_off_sent is exist, it means Accounting-Off has been sent. Currectly, just Lanner 7876 has the capability to do something before shutdown.
						if [ ! -f /db/subscriber/mgmt/$mgmt_index/radius/acct_off_sent${srv_index} ]; then
							acct_session_id=$(flock /tmp/post_id /ramfs/bin/create_acct_session_id.sh)
							/bin/echo "User-Name=\"${wan_mac}\",Acct-Status-Type=Accounting-Off,NAS-IP-Address=\"${NAS_IP}\",Called-Station-Id=\"${calledid}\",NAS-Identifier=\"${NASID}\",Acct-Session-Id=\"${acct_session_id}\",Acct-Terminate-Cause=Admin-Reboot" | /usr/local/bin/radclient $SERVER_IP:$ACCOUNT_PORT acct $SECRET_KEY -i $acctCnt -r $NUM_RETRIES -t $RETRIES_TIMEOUT
							acctCnt=$((( acctCnt + 1 ) % 256 ))
						else
							rm -f /db/subscriber/mgmt/$mgmt_index/radius/acct_off_sent${srv_index}
						fi
						acct_session_id=$(flock /tmp/post_id /ramfs/bin/create_acct_session_id.sh)
						/bin/echo "User-Name=\"${wan_mac}\",Acct-Status-Type=Accounting-On,NAS-IP-Address=\"${NAS_IP}\",Called-Station-Id=\"${calledid}\",NAS-Identifier=\"${NASID}\",Acct-Session-Id=\"${acct_session_id}\"" | /usr/local/bin/radclient $SERVER_IP:$ACCOUNT_PORT acct $SECRET_KEY -i $acctCnt -r $NUM_RETRIES -t $RETRIES_TIMEOUT
						acctCnt=$((( acctCnt + 1 ) % 256 ))
					fi
				fi
				let "srv_index +=1"
			done
			echo -n "$acctCnt" > /db/acctCnt
		fi
	fi
done

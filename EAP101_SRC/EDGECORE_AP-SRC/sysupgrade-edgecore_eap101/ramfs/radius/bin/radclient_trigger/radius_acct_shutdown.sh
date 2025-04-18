#!/bin/sh

. /conf/etc/profile
[ -z ${Auth_Server_Num} ] && Auth_Server_Num=5
. /ramfs/bin/radius_func

NAS_IP="`get_nas_ip`"
calledid=$(get_calledid)
wan_mac=$(echo $calledid |tr -d "-" |tr "A-Z" "a-z")
for mgmt_index in $(seq 1 ${Auth_Server_Num}); do
    Enabled=$(< /db/subscriber/mgmt/$mgmt_index/mgmt_enable)
    NASID="`get_nas_id \"${mgmt_index}\"`"
    if [ "$Enabled" = "Enabled" ]; then
        UTYPE=$(< /db/subscriber/mgmt/$mgmt_index/utype)
        if [ "$UTYPE" = "RADIUS" ]; then
            let "srv_index=1"
            while [ ${srv_index} -le 2 ]
            do
                ACCT_SERVICE="`get_acct_enable \"${mgmt_index}\" \"${srv_index}\"`"
                if [ "$ACCT_SERVICE" = "Enabled" ]; then
                    SERVER_IP="`get_acct_server_ip \"${mgmt_index}\" \"${srv_index}\"`"
                    ACCOUNT_PORT="`get_acct_server_port \"${mgmt_index}\" \"${srv_index}\"`"
                    SECRET_KEY="`get_acct_server_key \"${mgmt_index}\" \"${srv_index}\"`"
                    NUM_RETRIES="`get_file /db/subscriber/mgmt/\"${mgmt_index}\"/radius/num_retries`"
                    RETRIES_TIMEOUT="`get_file /db/subscriber/mgmt/\"${mgmt_index}\"/radius/retries_timeout`"
                    if [ -n "$SERVER_IP" ]; then
			# Sending Accounting-Stop to each user, for KT
			tmp_ra=$(ls /tmp/ra/ 2>/dev/null)
			tmp_ra=($tmp_ra)
			for (( i=0; i< ${#tmp_ra[*]}; i++ )); do
			    /ramfs/bin/nam_kick "${tmp_ra[$i]}" "Admin-Reboot" 
			done
                        # Sending Accounting-Off to RADIUS Server, Bug #4205
			acct_session_id=$(flock /tmp/post_id /ramfs/bin/create_acct_session_id.sh)
			acctCnt="`get_acctCnt`"
			/bin/echo "User-Name=\"${wan_mac}\",Acct-Status-Type=Accounting-Off,NAS-IP-Address=\"${NAS_IP}\",Called-Station-Id=\"${calledid}\",NAS-Identifier=\"${NASID}\",Acct-Session-Id=\"${acct_session_id}\",Acct-Terminate-Cause=Admin-Reboot" | /usr/local/bin/radclient $SERVER_IP:$ACCOUNT_PORT acct $SECRET_KEY -i $acctCnt -r $NUM_RETRIES -t $RETRIES_TIMEOUT
                        touch /db/subscriber/mgmt/$mgmt_index/radius/acct_off_sent${srv_index}
			acctCnt=$((( acctCnt + 1 ) % 256 ))
                    fi
                fi
                let "srv_index+=1"
            done
	    echo -n "$acctCnt" > /db/acctCnt
        fi
    fi
done


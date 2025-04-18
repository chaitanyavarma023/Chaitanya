#!/bin/sh

. /ramfs/bin/radius_func

PIDFILE="/var/run/radius_re_acct.pid"
if [ -f "$PIDFILE" ]; then
  pid=""
  read pid < "$PIDFILE"
  if [ -n "$pid" ]; then
    kill -0 "$pid" 2>/dev/null && exit
  fi
fi
echo "$$" > "$PIDFILE"

RADIUS_ACCT_PATH="/var/run/radius_acct"
QUEUE_DATA=`cd $RADIUS_ACCT_PATH; ls -1`

c1=$( echo "$QUEUE_DATA" | wc -l )
s1=""

for DATA in $QUEUE_DATA
do
  if [ -f "$RADIUS_ACCT_PATH/$DATA" ]; then
    rad_index=`/bin/cat "$RADIUS_ACCT_PATH/$DATA" | sed -n '2p'`
    mgmt_index=`/bin/cat "$RADIUS_ACCT_PATH/$DATA" | sed -n '3p'`
    SERVER_IP="`get_acct_server_ip \"${mgmt_index}\" \"${rad_index}`"
    ACCOUNT_PORT="`get_acct_server_port \"${mgmt_index}\" \"${rad_index}\"`"
    SECRET_KEY="`get_acct_server_key \"${mgmt_index}\" \"${rad_index}\"`"
    NUM_RETRIES="`get_file /db/subscriber/mgmt/\"${mgmt_index}\"/radius/num_retries`"
    RETRIES_TIMEOUT="`get_file /db/subscriber/mgmt/\"${mgmt_index}\"/radius/retries_timeout`"

    if [ -z "$SERVER_IP" ]; then
      ret=0
    else
      mtime=`eval /ramfs/bin/ftstamp "$RADIUS_ACCT_PATH/$DATA"`
      ntime=`date +%s`
      ACCT_DELAY_TIME=`expr $ntime - $mtime`
      if [ "$ACCT_DELAY_TIME" -lt 0 ]; then
	ACCT_DELAY_TIME=0
      fi

      recvmsg=$( /bin/cat "$RADIUS_ACCT_PATH/$DATA" | sed -n '1p' | sed 's/Acct-Delay-Time = 0/Acct-Delay-Time = '$ACCT_DELAY_TIME'/g' | /usr/local/bin/radclient $SERVER_IP:$ACCOUNT_PORT acct $SECRET_KEY -r $NUM_RETRIES -t $RETRIES_TIMEOUT 2>/dev/null )
      ret=$?

      check=$(echo "$recvmsg" | grep '^Received.*code 5,')
      if [ "$ret" = "0" -a -z "$check" ]; then
	#for radius 1.0.1, force to return 1
	ret=1
      fi
    fi

    if [ "$ret" != "0" ]; then
	echo "'$DATA':ERROR"
    else
	/bin/rm "$RADIUS_ACCT_PATH/$DATA"
	s1="+$s1"
    fi
  else
    s1="+$s1"
  fi
done

#keep last 100 records only
if [ $c1 -gt 100 ]; then
    c2=$(expr $c1 - ${#s1} - 100)
    if [ $c2 -gt 0 ]; then
	cd $RADIUS_ACCT_PATH
	rm -f $(echo "$QUEUE_DATA" | head "-$c2" )
    fi
fi
rm -f "$PIDFILE"

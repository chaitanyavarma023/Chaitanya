#!/bin/sh

PIDFILE="/var/run/radius_update.pid"
LCKFILE="/var/run/radius_update.lck"
if [ -f "$LCKFILE" ]; then
  pid=""
  read pid < "$LCKFILE"
  if [ -n "$pid" -a "$pid" != "$$" ]; then
    kill -0 "$pid" 2>/dev/null && exit
  fi
  rm -f "$LCKFILE"
fi
if [ -f "$PIDFILE" ]; then
  pid=""
  read pid < "$PIDFILE"
  if [ -n "$pid" -a "$pid" != "$$" ]; then
    kill -9 "$pid" 2>/dev/null
  fi
  rm -f "$PIDFILE"
fi
touch "$PIDFILE"
chmod 777 "$PIDFILE"
echo "$$" > "$PIDFILE"

while true; do

if [ -f "$LCKFILE" ]; then
  pid=""
  read pid < "$LCKFILE"
  if [ -n "$pid" -a "$pid" != "$$" ]; then
    kill -0 "$pid" 2>/dev/null && exit
  fi
  rm -f "$LCKFILE"
fi
touch "$LCKFILE"
chmod 777 "$LCKFILE"
echo "$$" > "$LCKFILE"

MACS=""
if [ -d /var/run/radius_update ] ;then
  MACS=`cd /var/run/radius_update; ls -tr`  # ls by reverse mtime order
fi
if [ -z "$MACS" ]; then
  rm -f "$PIDFILE" "$LCKFILE"
  exit
fi

vtime=""
stime=$(date +%s)

for MAC in $MACS; do 
  if [ -f "/var/run/radius_update/$MAC" ]; then
    if [ -f "/db/online/$MAC" ]; then
      interim=`cat "/db/online/$MAC" | /bin/sed -n '14p'`
      if [ -n "$interim" -a "$interim" -gt 0 ]; then
	mtime=`/ramfs/bin/ftstamp "/var/run/radius_update/$MAC"`
	dtime=$(expr "$mtime" + "$interim" - "$stime")
	if [ "$dtime" -le 0 ]; then
	  IP=`cat "/db/online/$MAC" | /bin/sed -n '1p'`
	  UTYPE=`cat "/db/online/$MAC" | /bin/sed -n '7p'`
	  touch "/var/run/radius_update/$MAC"
	  dtime="$interim"
	  if [ "$UTYPE" = "RADIUS" ]; then
	    TRAFFIC=( `/ramfs/bin/get_traffic.sh "$IP"` )
	    if [ "" = "${TRAFFIC[0]}" ]; then
	      TRAFFIC=( 0 0 0 0)
	    fi
	    /ramfs/bin/radius_acct.sh "Interim-Update" "$MAC" "${TRAFFIC[*]}"
            # 100: defined ACCT server 1 and 2 both fail now
            if [ "$?" = 100 ]; then
              break
            fi
	  fi
	fi
	if [ -z "$vtime" ] || [ "$vtime" -gt "$dtime" ]; then
	  vtime="$dtime"
	fi
      else
	rm -f "/var/run/radius_update/$MAC"
      fi
    else
      rm -f "/var/run/radius_update/$MAC"
    fi
  fi
done

etime=$(date +%s)
rm -f "$LCKFILE"

if [ -n "$vtime" ]; then
  dtime=$(expr "$stime" + "$vtime" - "$etime")
  if [ "$dtime" -gt 0 ]; then
    sleep "$dtime"
  fi
fi

done

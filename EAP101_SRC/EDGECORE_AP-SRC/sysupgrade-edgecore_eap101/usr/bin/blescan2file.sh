#!/bin/sh
exec 100>"/var/lock/blescan.lock"
flock 100

for i in 1 2 3 4   # scan duration = 2 sec * 4
do
	blescan.sh >>/tmp/blescan_tmp.record
done

MAC_FIELD_LEN=$(sed -n "1,1p" /tmp/blescan_tmp.record | awk '{print $1}' | awk '{print length($0)}')
sort /tmp/blescan_tmp.record | uniq -w $MAC_FIELD_LEN | grep "MFR=" > /tmp/blescan_tmp1.record
mv -f /tmp/blescan_tmp1.record /tmp/blescan.record

rm -f /tmp/blescan_tmp*
exec 100>&-

$(uci -q get tisbl.tisbl.command) # blescan.sh will do system reset, need to re-configure ibeacon broadcaster.

# blescan.sh will do system reset, need to re-configure watchdog.
wdt_enabled="$(uci -q get tisbl.tisbl.wdt_enabled)"
if [ "$wdt_enabled" == "1" ]; then
  wdt_touch.sh active
fi

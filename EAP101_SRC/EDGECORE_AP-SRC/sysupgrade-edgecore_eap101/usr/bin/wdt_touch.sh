#!/bin/sh
exec 100>"/var/lock/ble.lock"
fpid="/var/run/wdt_touch.pid"
exit=0
flock 100
if [ "$(uci -q get ibeacon.ibeacon.zigbee_enabled)" == "1" ]; then
  if [ "$1" == "inactive" ]; then
    # TODO: stop zigbee and do watchdog off
    :
  else
    com-wr.sh /dev/ttyMSM1 1 "\xFE\x01\x21\x23\x05\x06"             # set 5 seconds timeout
    com-wr.sh /dev/ttyMSM1 1 "\xFE\x00\x21\x21\x00"                 # watchdog on
  fi
else
  if [ "$1" == "inactive" ]; then
    com-wr.sh /dev/ttyMSM1 1 "\x01\x8B\xFE\x01\x00" >/dev/null      # watchdog off
  else
    com-wr.sh /dev/ttyMSM1 1 "\x01\x8C\xFE\x02\x05\x00" >/dev/null  # set 5 seconds timeout
    com-wr.sh /dev/ttyMSM1 1 "\x01\x8A\xFE\x01\x00" >/dev/null      # watchdog on
  fi
fi
if [ "$1" == "active" -o "$1" == "inactive" ]; then
  exit=1
elif [ -f "$fpid" ]; then
  { pgrep -f "wdt_touch.sh" | grep -w "$(cat "$fpid")"; } >/dev/null 2>&1 && exit=1
fi
[ "$exit" == "1" ] || echo $$ > "$fpid"
exec 100>&-
[ "$exit" == "1" ] && exit

[ -e /sys/class/gpio/gpio17 ] || echo 17 > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio17/direction

while true
do
  echo 0 > /sys/class/gpio/gpio17/value
  sleep 1
  echo 1 > /sys/class/gpio/gpio17/value
  sleep 1
done

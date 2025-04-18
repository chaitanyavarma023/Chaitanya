#!/bin/sh
cd /usr/lib/zstack/app

param2="0"
case $1 in
  permitjoin)
    param2="0xF0"  # set 240 seconds duration
    ;;
  listdev)
    rm -rf /tmp/zigbee_sensor.join
    ;;
  reset)
    param2="1"     # 1: hardware reset
    rm -rf /tmp/zigbee_sensor*
    ;;
  rmdev)
    param2=$(printf $2 | tr '[a-z]' '[A-Z]' | sed 's/0X//')
    sed -i "/${param2}/"d /tmp/zigbee_sensor.join /tmp/zigbee_sensor.record /tmp/zigbee_sensor_tmp.record
    ;;
  *)
    echo "Available commands:"
    echo "        permitjoin      permit join time in 240 senonds"
    echo "        listdev         list of devices currently in the database"
    echo "        reset           hardware reset"
    echo "        rmdev [addr]    remove specific device"
    exit
esac

exec 100>"/var/lock/ble.lock"
flock 100
./zbcli.bin $1 $param2 > /dev/null 2>&1
exec 100>&-

if [ "$1" == "reset" ]; then
  sleep 4
  /etc/init.d/ibeacon reload  # need to restart gateway after resetting hardware
fi

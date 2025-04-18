#!/bin/sh
# tisbl.sh $tty $baudrate $tichip $firmware $resetpin $backdoorpin
# tisbl.sh /dev/ttyMSM1 115200 2652 /etc/tifirmware/blinky_bd13.bin 79 67

#assumption: resetpin and backdoorpin are low active
tty=$1 
baudrate=$2
tichip=$3
firmware=$4
resetpin=$5
backdoorpin=$6

ti_reset() #assumption:resetpin is low active 
{
  if [ ! -e /sys/class/gpio/gpio${resetpin} ]; then
    echo ${resetpin} > /sys/class/gpio/export
  fi
  echo out > /sys/class/gpio/gpio${resetpin}/direction

  echo 1 > /sys/class/gpio/gpio${resetpin}/value
  echo 0 > /sys/class/gpio/gpio${resetpin}/value
  sleep 1
  echo 1 > /sys/class/gpio/gpio${resetpin}/value
}

ti_goto_bootloader() #assumption:backdoorpin is low active 
{
  if [ ! -e /sys/class/gpio/gpio${backdoorpin} ]; then
    echo ${backdoorpin} > /sys/class/gpio/export
  fi
  echo out > /sys/class/gpio/gpio${backdoorpin}/direction

  echo 0 > /sys/class/gpio/gpio${backdoorpin}/value
  ti_reset
  sleep 1
  echo 1 > /sys/class/gpio/gpio${backdoorpin}/value
}

exec 100>"/var/lock/ble.lock"
flock 100

if [ -e $firmware ]; then 
  ti_goto_bootloader
  tisbl $tty $baudrate $tichip $firmware #try to upgrade firmware
  if [ "$(uci -q get ibeacon.ibeacon.enabled)" == "1" ]; then
    com-wr.sh /dev/ttyMSM1 3 "\x01\x1D\xFC\x01\x00" > /dev/null
  fi
fi

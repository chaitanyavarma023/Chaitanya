#!/bin/sh
    devmem 0x1000003c 32 0x00FE01FF
    sleep 2
    echo 1 > /sys/class/gpio/pse_led_data1/value
    echo 1 > /sys/class/gpio/pse_led_data2/value
    echo 1 > /sys/class/gpio/pse_led_data3/value
    sleep 2
for i in `seq 1 24`;
do
    echo $i
    usleep 100
    echo 0 > /sys/class/gpio/pse_led_clk/value
    usleep 100
    echo 1 > /sys/class/gpio/pse_led_clk/value
done

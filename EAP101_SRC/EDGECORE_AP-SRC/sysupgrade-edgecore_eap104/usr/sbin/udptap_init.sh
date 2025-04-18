#!/bin/sh

brctl addbr brTun0
ifconfig brTun0 up

if [ -z "$(ifconfig | grep udpETH)" ]; then
	modprobe udptap
#else
#	brctl addif brTun0 udpETH
fi


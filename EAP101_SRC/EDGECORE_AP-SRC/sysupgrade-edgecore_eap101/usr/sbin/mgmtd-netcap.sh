#!/bin/sh
RUN_TIME=$1
MAX_SIZE=$2
PCAP_NAME=/tmp/mgmt-tmp.pcap
START_TIME=$(date +%s)

> $PCAP_NAME

shift
shift

tcpdump -w $PCAP_NAME $@ &
TPID=$!

while :; do
    CURR_TIME=$(date +%s)
    if [ $(expr $CURR_TIME - $START_TIME) -ge $RUN_TIME ]; then
        kill $TPID
        break
    fi
    if [ $(wc -c $PCAP_NAME | awk '{print $1}') -ge $MAX_SIZE ]; then
        kill $TPID
        break
    fi
done

#!/bin/sh

. /lib/acn/acn_functions.sh

CHAN_UTILS=/tmp/chan_utils_

#EAP101
#/sys/kernel/debug/ath11k/ipq6018\ hw1.0/mac${i}/fw_stats/pdev_stats

#EAP102
#/sys/kernel/debug/ath11k/ipq8074\ hw2.0/mac${i}/fw_stats/pdev_stats

#EAP104
#5G /sys/kernel/debug/ath11k/qcn6122_2/mac0/fw_stats/pdev_stats
#2.4G /sys/kernel/debug/ath11k/ipq5018\ hw1.0/mac0/fw_stats/pdev_stats

MID="$(get_MID)"

case $MID in
"EAP101"*)
pdev_stats0="/sys/kernel/debug/ath11k/ipq6018 hw1.0/mac0/fw_stats/pdev_stats"
pdev_stats1="/sys/kernel/debug/ath11k/ipq6018 hw1.0/mac1/fw_stats/pdev_stats"
;;
"EAP102"*)
pdev_stats0="/sys/kernel/debug/ath11k/ipq8074 hw2.0/mac0/fw_stats/pdev_stats"
pdev_stats1="/sys/kernel/debug/ath11k/ipq8074 hw2.0/mac1/fw_stats/pdev_stats"
;;
"EAP104"*)
pdev_stats0="/sys/kernel/debug/ath11k/qcn6122_2/mac0/fw_stats/pdev_stats"
pdev_stats1="/sys/kernel/debug/ath11k/ipq5018 hw1.0/mac0/fw_stats/pdev_stats"
;;
*);;
esac

#run twice to measure chan util
for c in 1 2 3
do
	for i in 0 1; do
		eval "pdev_stats=\$pdev_stats$i"

		#handle white space in the string
		tmp1=$(echo $pdev_stats | cut -d' ' -f1)
		if [ "$tmp1" != "$pdev_stats" ]; then
			tmp2=$(echo $pdev_stats | cut -d' ' -f2)
			stats=$(cat "$tmp1"\ "$tmp2" 2>&1 | grep count)
		else
			stats=$(cat $pdev_stats 2>&1 | grep count)
		fi

		if [ "$stats" != "" ]; then
			tx_count=$(echo $stats | awk '{print $4}')
			rx_count=$(echo $stats | awk '{print $8}')
			rx_clear=$(echo $stats | awk '{print $12}')
			cycle_count=$(echo $stats | awk '{print $15}')
			[ -f "/tmp/tx_count_prev$i" ] && tx_count_prev=$(cat /tmp/tx_count_prev$i) || tx_count_prev=0
			[ -f "/tmp/rx_count_prev$i" ] && rx_count_prev=$(cat /tmp/rx_count_prev$i) || rx_count_prev=0
			[ -f "/tmp/rx_clear_prev$i" ] && rx_clear_prev=$(cat /tmp/rx_clear_prev$i) || rx_clear_prev=0
			[ -f "/tmp/cycle_count_prev$i" ] && cycle_count_prev=$(cat /tmp/cycle_count_prev$i) || cycle_count_prev=0

			ignore=0

			if [ -z "${tx_count_prev}" -o -z "${rx_count_prev}" -o -z "${rx_clear_prev}" -o -z "${cycle_count_prev}" ]; then
				ignore=1
			fi
			if [ "${cycle_count}" -le "${cycle_count_prev}" ] || [ "${tx_count}" -lt "${tx_count_prev}" ] || [ "${rx_count}" -lt "${rx_count_prev}" ] || [ "${rx_clear}" -lt "${rx_clear_prev}" ]; then
				ignore=1
			fi

			if [ "$ignore" != "1" ]; then
				cycle_count_delta=$((cycle_count - cycle_count_prev))
				tx_count_delta=$((tx_count - tx_count_prev))
				rx_count_delta=$((rx_count - rx_count_prev))
				rx_clear_delta=$((rx_clear - rx_clear_prev))
				total_usage=$((rx_clear_delta * 100 / cycle_count_delta))
				tx_usage=$((tx_count_delta * 100 / cycle_count_delta))
				rx_usage=$((rx_count_delta * 100 / cycle_count_delta))

				echo ${total_usage} > ${CHAN_UTILS}$i
			fi

			echo ${tx_count} > /tmp/tx_count_prev$i
			echo ${rx_count} > /tmp/rx_count_prev$i
			echo ${rx_clear} > /tmp/rx_clear_prev$i
			echo ${cycle_count} > /tmp/cycle_count_prev$i
		fi
	done
done

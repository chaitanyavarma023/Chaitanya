#!/bin/sh

action=$1
iface=$2
mac=$3
mid=$4
qid=$((mid+1000))
reqDL=$5
maxDL=$6
reqUL=$7
maxUL=$8

add_tc(){
	local dir=$1
	local iface=$2
	local rate=$3
	local ceil=$4
	local rate_str= ceil_str= chain dir

	if [ "${dir}" = "DL" ];then
		chain="POSTROUTING"
		dir="-d"
	else
		chain="PREROUTING"
		dir="-s"
	fi

	if [ "${rate}" != "Unlimited" ]; then
		rate_str="rate ${rate}"
	fi

	if [ "${ceil}" != "Unlimited" ]; then
		ceil_str="ceil ${ceil}"
	fi

	if [ ! -n "${rate_str}" -a -n "${ceil_str}" ]; then
		rate_str=${ceil_str}
	fi
	
	if [ -n "${rate_str}" ]; then
		check=$(tc qdisc show dev ${iface} | grep "qdisc htb")
		[ -z "${check}" ] && tc qdisc add dev ${iface} root handle 6:0 htb r2q 100
		tc class replace dev ${iface} parent 6:0 classid 6:${qid} htb prio 3 ${rate_str} ${ceil_str}
		tc qdisc replace dev ${iface} parent 6:${qid} handle ${qid}:0 sfq perturb 10
		tc filter replace dev ${iface} parent 6:0 prio 5 protocol all handle ${mid} fw flowid 6:${qid}
		check=$(ebtables -t nat -L ${chain} | grep -i "${mac} -j mark")
		[ -z "${check}" ] && ebtables -t nat -I ${chain} ${dir} ${mac} -j mark --mark-set ${mid} --mark-target CONTINUE
	fi
}

del_tc(){
	local dir=$1
	local iface=$2
	local chain dir

	if [ "${dir}" = "DL" ];then
		chain="POSTROUTING"
		dir="-d"
	else
		chain="PREROUTING"
		dir="-s"
	fi

	ebtables -t nat -D ${chain} ${dir} ${mac} -j mark --mark-set ${mid} --mark-target CONTINUE
	tc filter del dev ${iface} parent 6:0 prio 5 protocol all handle ${mid} fw flowid 6:${qid}
	tc qdisc del dev ${iface} parent 6:${qid} handle ${qid}:0
	tc class del dev ${iface} parent 6:0 classid 6:${qid}
}

list(){
	{
		ebtables -t nat -L POSTROUTING;
		tc qdisc show | sed -n '/qdisc sfq/{/dev eth0/d;p}';
	} | awk \
	'
		BEGIN{
			n=0;
		}
		/mark-set/{
			split($2,a,":");x="0x";
			id = sprintf("%d", $6);
			if (!key[id]) {
				aid[n++] = id;
				key[id] = 1;
				mac[id] = sprintf("%02X:%02X:%02X:%02X:%02X:%02X",
					x a[1], x a[2], x a[3], x a[4], x a[5], x a[6]);
			}
		}
		/qdisc sfq/{
			id = sprintf("%d", $3) - 1000;
			if (key[id])
				dev[id] = $5;
		}
		END{
			for (i = 0; i < n; i++) {
				id = aid[i];
				if (id && mac[id]) {
					if (!dev[id])
						dev[id] = "dummy";
					printf("%d %s %s\n", id, mac[id], dev[id]);
				}
			}
		}
	'
}

case "${action}" in
    'add')
	logger "qos_user: add the entry of STA ${mac} of ${iface} (reqDL ${reqDL}/ maxDL ${maxDL}/ reqUL ${reqUL}/ maxUL ${maxUL})"
	add_tc "DL" "${iface}" "${reqDL}" "${maxDL}"
	add_tc "UL" "eth0" "${reqUL}" "${maxUL}"
	;;
    'del')
	logger "qos_user: delete the entry of STA ${mac} of ${iface}"
	del_tc "DL" "${iface}"
	del_tc "UL" "eth0"
	;;
    'list')
	list
	;;
esac

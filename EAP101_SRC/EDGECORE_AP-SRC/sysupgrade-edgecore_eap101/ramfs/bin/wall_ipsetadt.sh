#!/bin/sh

IPSETADT_LOCK="/var/lock/ipsetadt.lock"
IPSET_RESTORE="/tmp/ipset_restore"
DNS_QUERY="/ramfs/bin/dns-nb"
DNS_TMP="/tmp/hosts.tmp.ipsetadt"

WALL_FILE=$1
DNS_FILE=$2

if [ -f "${IPSETADT_LOCK}" ] || [ -z "$WALL_FILE" ] || [ -z "$DNS_FILE" ]; then
	exit 1
else
	touch ${IPSETADT_LOCK}
fi

[ -f "${IPSET_RESTORE}" ] && rm -f ${IPSET_RESTORE} 

ipset save zone_ip > ${IPSET_RESTORE}
ipset flush zone_ip

while read host; do
  total_host="${total_host} ${host}"
done < ${WALL_FILE}

${DNS_QUERY} ${total_host} > ${DNS_TMP}
set_name="zone_ip"
while read host; do
addrs=$(grep ${host} ${DNS_TMP} | cut -d ' ' -f1)
if [ -n "${addrs}" ]; then
	for addr in ${addrs}; do
		echo ${addr} | egrep '^[0-9]+.[0-9]+.[0-9]+.[0-9]+$' > /dev/null
		if [ $? -eq 0 ]; then
			echo "add ${set_name} ${addr}" >> ${IPSET_RESTORE}
		fi
	done
fi
done < ${WALL_FILE}

cat ${IPSET_RESTORE} | sort | uniq | ipset -! restore
cat ${DNS_TMP} | sort | uniq | cat > ${DNS_FILE}
kill -HUP $(cat /var/run/dnsmasq.pid)
rm -f ${IPSETADT_LOCK} ${DNS_TMP}


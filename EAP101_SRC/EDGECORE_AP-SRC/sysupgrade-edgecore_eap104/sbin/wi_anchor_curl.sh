#!/bin/sh

timestamp="`date +%s`"
url="`uci -q get addon.wianchor.bindingUrl`"

id_type="$1"
client_mac="$2"
client_ip="$3"
uid="$4"
os_type="$5"
phone="$6"

curl -k -d '{"timestamp": '$timestamp', "type": "'$id_type'", "uid": "'$uid'", "phone": "'$phone'", "client_mac": "'$client_mac'", "os_type": "'$os_type'"}' $url --connect-timeout 5 -m 5 &

/usr/sbin/login.sh login $client_mac $client_ip

#!/bin/sh

. /usr/share/libubox/jshn.sh
. /lib/functions/procd.sh

data=$(ubus call service list '{"name":"network","verbose":true}'|jq -c -M 'del(.network.instances)')

if [ -z "$(echo ${data} | jq .network.triggers | grep wireless)" ]; then
	json_load "${data}"
	json_select "network"
	json_select "triggers"

	_procd_add_config_trigger "config.change" "wireless" /etc/init.d/network reload
	_procd_add_config_trigger "config.change" "network" /etc/init.d/network restart

	mod_data=$(json_dump)
	new_tri="$(echo ${mod_data} | jq -c .network.triggers)"
	new_val="$(echo ${mod_data} | jq .network.validate | jq '[ .[] | .["data"] = .rules | del(.rules)]'|jq -c)"
	ubus call service set '{"name":"network","triggers":'${new_tri}',"validate":'$(printf %s ${new_val})'}'
fi


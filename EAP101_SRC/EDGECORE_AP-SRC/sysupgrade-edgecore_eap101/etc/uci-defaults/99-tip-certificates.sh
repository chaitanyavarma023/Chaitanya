#!/bin.sh

tip_mode=$(uci -q get acn.mgmt.management)
if [ ! -z $tip_mode ] && [ "$tip_mode" -eq 3 ]; then
uci add system certificates
uci set system.@certificates[-1].key=/etc/ucentral/key.pem
uci set system.@certificates[-1].cert=/etc/ucentral/cert.pem
uci set system.@certificates[-1].ca=/etc/ucentral/cas.pem
fi

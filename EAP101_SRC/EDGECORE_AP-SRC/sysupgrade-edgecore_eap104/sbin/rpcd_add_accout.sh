#!/bin/sh
. /lib/functions.sh

delete_account() {
  local sid="$1"
  local username
  config_get username "$sid" username
  if [ "$username" != "root" ]; then 
			uci delete rpcd.${sid}
  fi
}

config_load rpcd
config_foreach delete_account login

add_rpcd_account() {
  local sid="$1"
  local name
  config_get name "$sid" name

  if [ "$name" != "root" ]; then
uci -q batch <<-EOF >/dev/null
  add rpcd login
  set rpcd.@login[-1].username='$name'
  set rpcd.@login[-1].password='\$p\$'${name}
  add_list rpcd.@login[-1].read='*'
  add_list rpcd.@login[-1].write='*'
EOF
  fi
}

config_load users
config_foreach add_rpcd_account login

uci commit rpcd

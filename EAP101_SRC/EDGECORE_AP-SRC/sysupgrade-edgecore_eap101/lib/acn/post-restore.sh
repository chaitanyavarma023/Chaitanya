#!/bin/sh

#fix ticket 19673
remain_language() {
  cd /rom/etc/uci-defaults || return 0

  files="$(ls | grep luci-i18n-base-)"
  [ -z "$files" ] && return 0

  lang_dir="/tmp/.uci_language"
  mkdir -p $lang_dir

  for file in $files; do
    file_path="$lang_dir/$file"
    cp -f $file $file_path
    chmod 775 $file_path
    ( . "./$(basename $file_path)" )
  done

  rm -rf $lang_dir
}

remain_language

uci del acn.register.login 2> /dev/null
uci del acn.register.pass 2> /dev/null
uci del acn.register.host 2> /dev/null
uci set acn.register.state=0

uci commit acn.register
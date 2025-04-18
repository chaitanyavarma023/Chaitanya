#!/bin/sh
ifname="$1"
generate_file="$2"

ifname_str='"ifname":"'${ifname}'",'

[ -f $generate_file ] && {
  # remove last two lines
  sed -i 'N;$!P;$!D;$d' $generate_file

  # append '},' in the last line
  sed -i '$s/.*/                },/' $generate_file

  # remove first two lines and insert ifname info in the file
  ubus call iwinfo assoclist '{"device":"'$ifname'"}' | sed '1,2d' | sed '/mac/ a\'${ifname_str} >> $generate_file
} || {

  # insert ifname info in the file
  ubus call iwinfo assoclist '{"device":"'$ifname'"}' | sed '/mac/ a\'${ifname_str} > $generate_file
}

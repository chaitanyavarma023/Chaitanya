#!/bin/sh
if ( ! grep -qsE '^root:[!x]?:' /etc/shadow || \
     ! grep -qsE '^root:[!x]?:' /etc/passwd ) && \
   [ -z "$FAILSAFE" ]
then
        echo "WARNING: telnet is a security risk"
        busybox login
else
[ "$(uci -q get system.@system[0].ttylogin)" = 0 ] && exec /bin/ash --login

exec /bin/login
fi


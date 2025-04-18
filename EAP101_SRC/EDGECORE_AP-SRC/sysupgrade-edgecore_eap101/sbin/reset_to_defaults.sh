#!/bin/sh
#
# need to run with -y switch

format_media() {
	return 0
}

. /lib/functions.sh
include /lib/upgrade


[ x"$1" != x"-y" ] && return

logger -s -t reset -p user.info "Resetting to factory defaults .."

trap '' HUP
stop_ra_process

/sbin/jffs2reset $@ || return
format_media

/sbin/reboot

sleep 5

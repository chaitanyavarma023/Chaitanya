add_luci_conffiles()
{
	local filelist="$1"

	# save ssl certs
	if [ -d /etc/nixio ]; then
		find /etc/nixio -type f >> $filelist
	fi

	# save uhttpd certs
	[ -f "/etc/uhttpd.key" ] && echo /etc/uhttpd.key >> $filelist
	[ -f "/etc/uhttpd.crt" ] && echo /etc/uhttpd.crt >> $filelist

#save chilli certs
		[ -f "/etc/chilli/upload.pem" ] && echo /etc/chilli/upload.pem >> $filelist
		[ -f "/etc/chilli/upload.key" ] && echo /etc/chilli/upload.key >> $filelist
		[ -f "/etc/chilli/upload.crt" ] && echo /etc/chilli/upload.crt >> $filelist
		[ -f "/etc/chilli/cloud.pem" ] && echo /etc/chilli/cloud.pem >> $filelist
		[ -f "/etc/chilli/cloud.key" ] && echo /etc/chilli/cloud.key >> $filelist
		[ -f "/etc/chilli/cloud.crt" ] && echo /etc/chilli/cloud.crt >> $filelist
}

sysupgrade_init_conffiles="$sysupgrade_init_conffiles add_luci_conffiles"


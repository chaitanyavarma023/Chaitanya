. /lib/functions/system.sh

qca_do_upgrade() {
        local tar_file="$1"

        local board_dir=$(tar tf $tar_file | grep -m 1 '^sysupgrade-.*/$')
        board_dir=${board_dir%/}
	local dev=$(find_mtd_chardev "0:HLOS")

        tar Oxf $tar_file ${board_dir}/kernel | mtd write - ${dev}

        if [ -n "$UPGRADE_BACKUP" ]; then
                tar Oxf $tar_file ${board_dir}/root | mtd -j "$UPGRADE_BACKUP" write - rootfs
        else
                tar Oxf $tar_file ${board_dir}/root | mtd write - rootfs
        fi
}

platform_check_image() {
	local magic_long="$(get_magic_long "$1")"
	board=$(board_name)
	case $board in
	edgecore,eap101)
		local magic_full="$(get_magic_full "$1")"
		[ "$magic_full" = "737973757067726164652d65646765636f72655f656170313031" ] && return 0
		;;
	edgecore,eap102)
		local magic_full="$(get_magic_full "$1")"
		[ "$magic_full" = "737973757067726164652d65646765636f72655f656170313032" ] && return 0
		;;
	edgecore,oap103)
		local magic_full="$(get_magic_full "$1")"
		[ "$magic_full" = "737973757067726164652d65646765636f72655f6f6170313033" ] && return 0
		;;
	edgecore,eap104)
		local magic_full="$(get_magic_full "$1")"
		[ "$magic_full" = "737973757067726164652d65646765636f72655f656170313034" ] && return 0
		;;
	cig,wf188|\
	cig,wf188n|\
	cig,wf194c|\
	cig,wf194c4|\
	wallys,dr6018|\
	wallys,dr6018-v4|\
	edgecore,eap106|\
	hfcl,ion4xi|\
	hfcl,ion4xe|\
	tplink,ex227|\
	tplink,ex447|\
	qcom,ipq6018-cp01|\
	qcom,ipq807x-hk01|\
	qcom,ipq807x-hk14|\
	qcom,ipq5018-mp03.3)
		[ "$magic_long" = "73797375" ] && return 0
		;;
	esac
	return 1
}

mtd_name_to_part() {
	echo $(grep "\"$1\"" /proc/mtd | awk -F: '{print $1}')
}

get_active_part() {
	echo $(cat /proc/cmdline | sed 's/ / \n/g' | grep ubi.mtd | awk -F= '{print $2}')
}

check_dualboot() {
	local mtdname=$1
	local dualboot=0
	local mtdpart=$(mtd_name_to_part "${mtdname}")

	if [ -z "$mtdpart" ]; then
		local mtdpart1=$(mtd_name_to_part "${mtdname}1")
		local mtdpart2=$(mtd_name_to_part "${mtdname}2")
		if [ -n "$mtdpart1" -a -n "x$mtdpart2" ]; then
			dualboot=1
		fi
	fi

	echo $dualboot
}

platform_do_upgrade() {
	CI_UBIPART="rootfs"
	CI_ROOTPART="ubi_rootfs"
	CI_IPQ807X=1

	board=$(board_name)
	case $board in
	cig,wf188)
		qca_do_upgrade $1
		;;
	cig,wf188n|\
	cig,wf194c|\
	cig,wf194c4|\
	hfcl,ion4xi|\
	hfcl,ion4xe|\
	qcom,ipq6018-cp01|\
	qcom,ipq807x-hk01|\
	qcom,ipq807x-hk14|\
	qcom,ipq5018-mp03.3|\
	wallys,dr6018|\
	wallys,dr6018-v4|\
	tplink,ex447|\
	tplink,ex227)
		nand_upgrade_tar "$1"
		;;
	edgecore,eap106|\
	edgecore,eap104|\
	edgecore,eap102|\
	edgecore,oap103|\
	edgecore,eap101)
		local dualboot=0
		local mtdname=rootfs
		dualboot=$(check_dualboot $mtdname)

		if [ $dualboot -eq 1 ]; then
			CI_DUALBOOT=1
			active_partname=$(get_active_part)
			if [ $active_partname == "rootfs1" ]; then
				CI_UBIPART="rootfs2"
				CI_UBIPART_B="rootfs1"
				CI_NEWACTIVE=2
				nand_upgrade_tar "$1"
			elif [ $active_partname == "rootfs2" ]; then
				CI_UBIPART="rootfs1"
				CI_UBIPART_B="rootfs2"
				CI_NEWACTIVE=1
				nand_upgrade_tar "$1"
			fi
		else
			CI_UBIPART="rootfs1"
			nand_upgrade_tar "$1"
		fi
		;;
	esac
}

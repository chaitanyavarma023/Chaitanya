HELP=0

MTD10="17"
MTD11="18"

DEV_UBI0="/dev/ubi0"
DEV_UBI1="/dev/ubi1"
DEV_UBI1_BLK="/dev/ubiblock1"

SYS_UBI0_DIR="/sys/devices/virtual/ubi/ubi0"
SYS_UBI1_DIR="/sys/devices/virtual/ubi/ubi1"

ROOTFS_BACKUP_DIR="/var/cfgmtd"
ROOTFS_BACKUP_PART="${MTD10}"

BACKUP_FW_VER_FILE="/var/backup_fw_ver"

# parse options
while [ -n "$1" ]; do
	case "$1" in
		-h|--help)
			HELP=1
			break
		;;
		-*)
			echo "Invalid option: $1"
			exit 1
		;;
		*)
			break
		;;
	esac
	shift;
done

[ -z "$1" -o $HELP -gt 0 ] && {
        cat <<EOF
Usage: $0 [<options>...] <current | backup>
        current      get current partition firmware version
        backup       get backup partition firmware version

options:
        -h | --help  display this help

EOF
        exit 1
}

if [ ! -d "${ROOTFS_BACKUP_DIR}" ]; then
	mkdir -p ${ROOTFS_BACKUP_DIR}
fi

if [ "$(cat ${SYS_UBI0_DIR}/mtd_num)" = "${MTD10}" ]; then
	ROOTFS_BACKUP_PART="${MTD11}"
fi

case "$1" in
	current)
		cat /etc/edgecore_version
		;;
	backup)
		if [ ! -f ${BACKUP_FW_VER_FILE} ]; then
			ubiattach -m ${ROOTFS_BACKUP_PART} > /dev/null
			ubiblock --create ${DEV_UBI1}_1

			mount -t squashfs -o ro ${DEV_UBI1_BLK}_1 ${ROOTFS_BACKUP_DIR}

			if [ -d ${ROOTFS_BACKUP_DIR}/etc ]; then
				cat ${ROOTFS_BACKUP_DIR}/etc/edgecore_version > ${BACKUP_FW_VER_FILE}
			fi

			umount ${ROOTFS_BACKUP_DIR}

			ubiblock --remove ${DEV_UBI1}_1
			ubidetach -m ${ROOTFS_BACKUP_PART} 2> /dev/null
		fi

		cat ${BACKUP_FW_VER_FILE}
		;;
	*)
		echo "Partition does not exist !!"
		;;
esac


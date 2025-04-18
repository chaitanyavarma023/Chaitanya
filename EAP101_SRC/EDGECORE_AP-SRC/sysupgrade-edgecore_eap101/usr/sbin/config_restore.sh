#!/bin/sh

source=$1
target=
key=$2

[ -z "$key" ] && key=ACN

__read_file_magic() {
	dd if=$1 bs=4 count=1 | hexdump -v -n 4 -e '1/1 "%02x"' 2>/dev/null
	return 0
}

case "$(__read_file_magic $source)" in
		# tar.gz file
                1f8b0800)
			target=${source}
                ;;
		# should be a openssl encrypted file
                *)
			target=${source}.tar.gz
			openssl des3 -d -pass pass:${key} -in ${source} > ${target}
                ;;
        esac

# check configuration not empty and is tar.gz archive
if [ ! -s "${target}" -o "$(__read_file_magic $target)" != "1f8b0800" ]; then
	rm -f ${source} ${target}
	return 1
fi

tar -zxf ${target} -C / 2>/dev/null
rm -f ${source} ${target}
return 0

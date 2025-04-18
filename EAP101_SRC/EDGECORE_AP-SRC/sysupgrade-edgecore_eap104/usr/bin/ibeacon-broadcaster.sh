#!/bin/sh
#         script---------------- UUID---------------------------------------------------------------------- MAJOR----- MINOR----- TXPOWER-
#example: ibeacon-broadcaster.sh "E20A39F473F54BC4A12F17D1AD07A961" "100" "5" "14"

#When uci "ibeacon.ibeacon.txpower" is set, the opposite "broadcaster ibeacon'power" must also be set at the same time.
#            ibeacon.ibeacon.txpower    broadcaster ibeacon'power
#  dbm       set_value                  set_value
#  -20 dBm   0                          175 = 195 - 20
#  -18 dBm   1                          177 = 195 - 18
#  -15 dBm   2                          180 = 195 - 15
#  -12 dBm   3                          183 = 195 - 12
#  -10 dBm   4                          185 = 195 - 10
#  -9  dBm   5                          186 = 195 - 9
#  -6  dBm   6                          189 = 195 - 6
#  -5  dBm   7                          190 = 195 - 5
#  -3  dBm   8                          192 = 195 - 3
#   0  dBm   9                          195 = 195 + 0
#   1  dBm   10                         196 = 195 + 1
#   2  dBm   11                         197 = 195 + 2
#   3  dBm   12                         198 = 195 + 3
#   4  dBm   13                         199 = 195 + 4
#   5  dBm   14                         200 = 195 + 5

#The BLE virtual MAC comes from eth0, except the 1st byte of MAC do or operation with 2. 

MAC=$(ifconfig eth0 | grep HWaddr | awk '{print $5}')
MAC_BYTE=$(printf '\x%x' $((0x${MAC:0:2}|2)))    # do or operation with 2
VIRTUAL_MAC='\x'${MAC:15:2}'\x'${MAC:12:2}'\x'${MAC:9:2}'\x'${MAC:6:2}'\x'${MAC:3:2}${MAC_BYTE}

if [ "$#" -eq 4 ]; then
	UUID=$(echo -n ${1}| sed 's/-//g;s/\(..\)/\\x\1/g')
	MAJOR=$(printf %04x ${2} | sed 's/-//g;s/\(..\)/\\x\1/g')
	MINOR=$(printf %04x ${3} | sed 's/-//g;s/\(..\)/\\x\1/g')
#	txpower2powerIndex='175 177 180 183 185 186 189 190 192 195 196 197 198 199 200'
	txpower2powerIndex='AF B1 B4 B7 B9 BA BD BE C0 C3 C4 C5 C6 C7 C8'
	POWER='\x'${txpower2powerIndex:${4}*3:2}
	TXPOWER=$(printf %02x ${4} | sed 's/-//g;s/\(..\)/\\x\1/g')
else
	UUID="\xE2\x0A\x39\xF4\x73\xF5\x4B\xC4\xA1\x2F\x17\xD1\xAD\x07\xA9\x61"
	MAJOR="\x01\x23"
	MINOR="\x45\x67"
	TXPOWER="\x0E"
	POWER="\xC8"
fi	

exec 100>"/var/lock/ble.lock"
flock 100

com-wr.sh /dev/ttyMSM1 3 "\x01\x1D\xFC\x01\x00" > /dev/null # this reset command delay time must >= 3, if small than 3, the following commands  will be something wrong
com-wr.sh /dev/ttyMSM1 1 "\x01\x0C\xFC\x06${VIRTUAL_MAC}" > /dev/null
com-wr.sh /dev/ttyMSM1 1 "\x01\x01\xFC\x01${TXPOWER}" > /dev/null
com-wr.sh /dev/ttyMSM1 1 "\x01\x00\xFE\x08\x01\x00\x00\x00\x00\x00\x00\x00" > /dev/null 
com-wr.sh /dev/ttyMSM1 1 "\x01\x3E\xFE\x15\x12\x00\xA0\x00\x00\xA0\x00\x00\x07\x00\x00\x00\x00\x00\x00\x00\x00\x7F\x01\x01\x00" > /dev/null
com-wr.sh /dev/ttyMSM1 1 "\x09\x44\xFE\x23\x00\x00\x00\x1E\x00\x02\x01\x1A\x1A\xFF\x4C\x00\x02\x15${UUID}${MAJOR}${MINOR}${POWER}\x00" > /dev/null
com-wr.sh /dev/ttyMSM1 1 "\x01\x3F\xFE\x04\x00\x00\x00\x00" | hexdump.sh

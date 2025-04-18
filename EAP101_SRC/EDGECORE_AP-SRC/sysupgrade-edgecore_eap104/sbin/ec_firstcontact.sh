#!/bin/sh

DEV_ID="/etc/ucentral/dev-id"
FILE_CERT="/etc/ucentral/cert.pem"
FILE_KEY="/etc/ucentral/key.pem"
REDIRECT_JSON="/etc/ucentral/redirector.json"

[ ! -f $DEV_ID -o -f $REDIRECT_JSON ] && exit 0

device_id=$(cat $DEV_ID)

#ref: /usr/sbin/firstcontact -i $device_id
curl -X GET "https://clientauth.one.digicert.com/iot/api/v2/device/$device_id" --key "$FILE_KEY" --cert "$FILE_CERT" -o "$REDIRECT_JSON"
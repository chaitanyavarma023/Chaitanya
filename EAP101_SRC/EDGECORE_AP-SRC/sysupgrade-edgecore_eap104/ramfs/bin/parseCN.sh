#/bin/sh

ca_file=$1

if [ -f ${ca_file} ]; then
    CName=$(/usr/bin/openssl x509 -in ${ca_file} -noout -subject | sed -n '/^subject/s/^.*CN=//p')
    [ -z "${CName}" ] && CName=$(/usr/bin/openssl x509 -in ${ca_file} -noout -subject | sed -n '/^subject/s/^.*CN = //p')
fi

echo "$CName"


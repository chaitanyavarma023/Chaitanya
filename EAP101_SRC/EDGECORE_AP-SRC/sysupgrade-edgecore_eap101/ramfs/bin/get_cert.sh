#!/bin/sh
# default server.pem is localted /etc/freeraidus/certs/server.pem
cert="/etc/freeradius3/certs/server.pem"
cert_md5="$(md5sum $cert |cut -d' ' -f1)" #gateway.example.com

# overwirte by the cloud certificate
cloud_cert="/tmp/cloud.pem"
cloud_cert_path="$(uci -q get files.authport_certificate.url)"
cloud_cert_md5="$(uci -q get files.authport_certificate.md5)"

# download cloud intermediate certificate
cloud_intermediate_cert="/tmp/cloud_intermediate_cert.crt"
cloud_intermediate_cert_path="$(uci -q get files.authport_intermediate_certificate.url)"
cloud_intermediate_cert_md5="$(uci -q get files.authport_intermediate_certificate.md5)"

# intermediate certificate
intermediate_cer="/etc/certs/ca_bundle.crt"
intermediate_cer_md5="$(md5sum $intermediate_cer |cut -d' ' -f1)"

# uhttpd certificate
uhttpd_cert="/etc/chilli/server.pem"
uhttpd_cert_md5="$(md5sum $uhttpd_cert |cut -d' ' -f1)"

# check for authport
authport_enabled=$(uci show wireless | grep cloud_aaa | grep "='1'")

INTERFACE="eth0"
wianchor_cert_path="`uci -q get addon.wianchor.cert`"
[ "$wianchor_cert_path" == "" ] && {
    bindingUrl="`uci -q get addon.wianchor.bindingUrl`"
    wianchor_cert_path="`dirname $bindingUrl`/GetCert"
}

# check if intermediate certificate need to update
update_inter_cert="false"

# check if certificated need updated ? 
# action:0 --> no need to update
# action:1 --> update certificate from cloud
# action:2 --> update certificate from wianchor url
action=0

if [ -n "${cloud_cert_path}" -a -n "${cloud_cert_md5}" ]; then
    [ "$cloud_cert_md5" != "$uhttpd_cert_md5" ] && {
      action=1
      if [ -n "${cloud_intermediate_cert_path}" -a -n "${cloud_intermediate_cert_md5}" ]; then
        [ "$cloud_intermediate_cert_md5" != "$intermediate_cer_md5" ] && update_inter_cert="true"
      fi
    }
else
    [ "$cert_md5" != "$uhttpd_cert_md5" ] && action=2
fi

[ -n "$1" ] && action=2

if [ "$action" = "0" ]; then
	echo -n "ok"
	exit 0
fi

fail=0
if [ -n "${authport_enabled}" -a -z "${cloud_cert_path}" -a -z "${cloud_cert_md5}" ]; then
    action=1
    cert="/etc/freeradius3/certs/server.pem"
elif [ "$action" = "1" ]; then
    [ -f $cloud_cert ] && rm -f $cloud_cert
    curl -4 -k --connect-timeout 5 -m 5 -o ${cloud_cert} "${cloud_cert_path}" >/dev/null 2>&1
    chksum=$(md5sum ${cloud_cert} | cut -d" " -f 1)
    name=$(/ramfs/bin/parseCN.sh $cloud_cert)

    if [ -n "$name" ] && [ "${chksum}" = "${cloud_cert_md5}" ]; then
        cert="${cloud_cert}"

        if [ "$update_inter_cert" = "true" ]; then
          [ -f $cloud_intermediate_cert ] && rm -f $cloud_intermediate_cert
          curl -4 -k --connect-timeout 5 -m 5 -o ${cloud_intermediate_cert} "${cloud_intermediate_cert_path}" >/dev/null 2>&1
          chksum=$(md5sum ${cloud_intermediate_cert} | cut -d" " -f 1)
          if [ "${chksum}" != "${cloud_intermediate_cert_md5}" ]; then
            logger -t get_cert -p 1.3 "Invalid Intermediate Certificate from the cloud"
            rm -f $cloud_intermediate_cert
          fi
        fi

    else
        echo -n "fail"
        logger -t get_cert -p 1.3 "Invalid Certificate from the cloud, fallback to default"
        fail=1
    fi
else
    ap_mac="$(ifconfig $INTERFACE | awk '/HWaddr/ {print $NF}' | sed 's/://g' | awk '{print tolower($0)}')"
    DATE=$(date +"%Y%m%d")
    _hash_val="$(echo -n $ap_mac$(date +"%Y%m%d") | md5sum | awk  '{print $1}')"
    hash_val_1=$(expr substr "$_hash_val" 1 4)
    hash_val_2=$(echo "$_hash_val" | grep -o '....$')
    hash_val="${hash_val_1}${hash_val_2}"
    [ -f ${cloud_cert}.tar ] && rm -f ${cloud_cert}.tar
    curl -k -X POST --connect-timeout 5 -m 5 -H 'Content-Type: application/json' -d '{"ap_mac":"'$ap_mac'", "hash":"'$hash_val'"}' $wianchor_cert_path -o ${cloud_cert}.tar
    if [ $? = "0" ] && [ -f ${cloud_cert}.tar ]; then
        [ -d /tmp/ap.key ] && rm -rf /tmp/ap.key
        tar -xf ${cloud_cert}.tar -C /tmp
        [ -f /tmp/ap.key/cert.pem ] && cat /tmp/ap.key/cert.pem > ${cloud_cert}
        [ -f /tmp/ap.key/privkey.pem ] && cat /tmp/ap.key/privkey.pem >> ${cloud_cert}
        cert="${cloud_cert}"
    fi

    if [ ! -f /tmp/ap.key/cert.pem ] || [ ! -f /tmp/ap.key/privkey.pem ]; then
        echo -n "fail"
        logger -t get_cert -p 1.3 "Invalid Certificate from the wianchor, fallback to default"
        fail=1
    fi
fi

[ "$fail" = "1" ] && exit 1

# apply the certificate to uhttpd and radius
if [ "$action" = "1" ]; then
    cp ${cert} ${uhttpd_cert}
    cat $cert | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /etc/freeradius3/certs/cert-srv.crt
    openssl pkey -in ${cert} -inform PEM -out /etc/freeradius3/certs/cert-srv.key
    cp /etc/freeradius3/certs/cert-srv.crt /etc/uhttpd.crt
    cp /etc/freeradius3/certs/cert-srv.key /etc/uhttpd.key
    name=$(/ramfs/bin/parseCN.sh ${uhttpd_cert})
    [ -f $cloud_intermediate_cert ] && {
      cp $cloud_intermediate_cert $intermediate_cer
      cat $intermediate_cer >> /etc/uhttpd.crt
    }
fi

if [ "$action" = "2" ]; then
    [ -f /tmp/ap.key/cert.pem ] && {
        cp /tmp/ap.key/cert.pem /etc/uhttpd.crt
        cp /tmp/ap.key/cert.pem /etc/freeradius3/certs/cert-srv.crt
        cp /tmp/ap.key/cert.pem /etc/chilli/server.crt
    }
    [ -f /tmp/ap.key/privkey.pem ] && {
        cp /tmp/ap.key/privkey.pem /etc/uhttpd.key
        cp /tmp/ap.key/privkey.pem /etc/freeradius3/certs/cert-srv.key
        cp /tmp/ap.key/privkey.pem /etc/chilli/server.key
    }
    [ -d /tmp/ap.key ] && rm -rf /tmp/ap.key
    [ -f ${cloud_cert}.tar ] && rm -f ${cloud_cert}.tar
    name=$(/ramfs/bin/parseCN.sh /etc/uhttpd.crt)
fi

if [ -n "$(uci -q get network.bridge.type)" ]; then
    WAN1="$(uci -q get network.wan.device)"
else
    WAN1="br-wan"
fi

[ -z "$(ifconfig ${WAN1} 2>/dev/null)" ] && WAN1="eth0"
ip=$(ifconfig ${WAN1} | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
rm /tmp/hosts/cert

if [ -n "$ip" -a -n "$name" ]; then
   echo "$ip $name" > /tmp/hosts/cert
fi

[ -f $cloud_cert ] && rm -f $cloud_cert
[ -f $cloud_intermediate_cert ] && rm -f $cloud_intermediate_cert

# restart the service
/etc/init.d/uhttpd stop
/etc/init.d/uhttpd start

killall -HUP radiusd
killall -HUP stunnel
killall -HUP dnsmasq

/etc/init.d/cipuamd restart

/ramfs/bin/run_setup_aaa.sh >/dev/null 2>&1
[ "$?" = "0" ] && echo -n "ok" || echo -n "fail"

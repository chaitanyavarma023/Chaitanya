#!/bin/sh

certificate_content="/tmp/.certificate_parsed"
crt_path="/etc/chilli"

if [ -f "$crt_path/cloud.pem" ]; then
    certificate_path="$crt_path/cloud.pem"
elif [ -f "$crt_path/upload.pem" ]; then
    certificate_path="$crt_path/upload.pem"
else
    certificate_path="$crt_path/server.pem"
fi

[ -s "$certificate_content" ] && rm -f ${certificate_content}

get_issuer() {
  openssl x509 -in $certificate_path -noout -issuer | sed 's/issuer=//g' | sed 's/ //g'| awk 'BEGIN {FS=","}; { for (i=1; i<=NF; i++) print $i }' | awk 'BEGIN {FS="="}; {print "\""$1"\": \""$2"\","}' >> $certificate_content
}

get_version() {
   openssl x509 -in $certificate_path -text -noout | grep Version | awk 'FS=":" {if($2 ~ /^[0-9]+$/) print "\"Version\": \""$2"\","}' >> $certificate_content
}

get_serial() {
  openssl x509 -in $certificate_path -noout -serial | awk 'BEGIN {FS="="}; {print "\""$1"\": \""$2"\","}' >> $certificate_content
}

get_Sigature() {
   openssl x509 -in $certificate_path -text -noout | grep "Signature\ Algorithm" | uniq | awk 'FS=":" {print "\""$1"\": \""$3"\","}' >> $certificate_content
}

get_date_from() {
  openssl x509 -in $certificate_path -noout -startdate | awk 'BEGIN {FS="="}; {print "\""$1"\": \""$2"\","}' >> $certificate_content
}

get_date_until() {
  openssl x509 -in $certificate_path -noout -enddate | awk 'BEGIN {FS="="}; {print "\""$1"\": \""$2"\","}' >> $certificate_content
}

get_Key_Identifier() {
  openssl x509 -in $certificate_path -text -noout | grep "keyid" | awk 'BEGIN {FS="keyid:"}; {print "\"keyid\": \""$2"\","}' >> $certificate_content
}

get_ca_true() {
  openssl x509 -in $certificate_path -text -noout | grep "CA:" | awk 'BEGIN {FS=":"}; {if ($2 == "TRUE" || $2 == "FALSE") { print "\"CA\": \""$2"\"," }}' >> $certificate_content
}

#generate parsed certificate file with JSON format
echo "{" > $certificate_content
get_issuer
get_version
get_serial
get_Sigature
get_date_from
get_date_until
get_Key_Identifier
get_ca_true
echo "}" >> $certificate_content

#remove the last ","
total_lines=`sed -n "$=" $certificate_content`
let key_line=total_lines-1
sed -i "${key_line}s/,//" $certificate_content

return 0

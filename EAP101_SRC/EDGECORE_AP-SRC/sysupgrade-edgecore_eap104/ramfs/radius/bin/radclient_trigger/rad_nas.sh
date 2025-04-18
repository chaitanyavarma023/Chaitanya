#!/bin/sh
#compatible with old db
. /conf/etc/profile
[ -z ${Auth_Server_Num} ] && Auth_Server_Num=5

if [ ! -f /db/subscriber/radius/nas_max ]; then
  mkdir -p /db/subscriber/radius
  echo -n 20 > /db/subscriber/radius/nas_max
  chown nobody.nogroup /db/subscriber/radius /db/subscriber/radius/nas_max
fi
max=`cat /db/subscriber/radius/nas_max`
max=`expr $max + 0 2>/dev/null`
if [ -z "$max" ] || [ $max -eq 0 ]; then
  max=20
fi
if [ ! -f /db/subscriber/radius/nas_list_ui ]; then
  if [ -f /db/subscriber/radius/nas_list ]; then
    cp /db/subscriber/radius/nas_list /db/subscriber/radius/nas_list_ui
  else
    for j in $(seq 1 ${max}); do
      echo "0,,32,," >> /db/subscriber/radius/nas_list_ui
    done
  fi
fi

let "val_i=1"
last=0
while [ $val_i -le ${Auth_Server_Num} ]; do
  mgmt_enable=`cat /db/subscriber/mgmt/$val_i/mgmt_enable`
  UTYPE=`cat /db/subscriber/mgmt/$val_i/utype`
  EAP=`cat /db/subscriber/mgmt/$val_i/radius/8021x`
  if [ "$mgmt_enable" = "Enabled" -a "$UTYPE" = "RADIUS" -a "$EAP" = "Enabled" ]; then
    last=$val_i
  fi
  let "val_i +=1"
done
echo -n > /tmp/nas_list
let "val_i=${Auth_Server_Num}"
while [ $val_i -gt 0 ]; do
  if [ $val_i -eq $last ]; then
    awk -f /ramfs/bin/eap_rad.awk /db $val_i 1 >> /tmp/nas_list
  else
    awk -f /ramfs/bin/eap_rad.awk /db $val_i 0 >> /tmp/nas_list
  fi
  let "val_i -=1"
done
cat /tmp/nas_list | head -$max > /db/subscriber/radius/nas_list
chown nobody.nogroup /tmp/nas_list /db/subscriber/radius/nas_list /db/subscriber/radius/nas_list_ui
chmod 777 /tmp/nas_list /db/subscriber/radius/nas_list /db/subscriber/radius/nas_list_ui

cat /db/subscriber/radius/nas_list_ui >> /db/subscriber/radius/nas_list

#### for capwap split tunnel ##### Split Tunnel AP IP range
#Split Tunnel specific settings
#secret key : RVHS
#snmp community : public
#hide nas list in UI : 0 
CAPWAP_EN=$(< /db/capwap/capwap_status)
SPLIT_TUNNEL_CONFIG=`/ramfs/bin/ip_net.awk $(< /db/capwap/mgmt_ip)/$(< /db/capwap/netmask)`
SPLIT_TUNNEL_CONFIG_IP=${SPLIT_TUNNEL_CONFIG%/*}
SPLIT_TUNNEL_CONFIG_MASK=${SPLIT_TUNNEL_CONFIG#*/}
if [ "${CAPWAP_EN}" = "Enabled" ]; then
        echo "2,${SPLIT_TUNNEL_CONFIG_IP},${SPLIT_TUNNEL_CONFIG_MASK},RVHS,public,1" >>/db/subscriber/radius/nas_list
fi

rm -f /tmp/rclients.conf
#Generate data for rclients.conf by nas list
sh /ramfs/bin/mk_rad_nas_awk_list.sh /db
awk -f /ramfs/bin/rad_nas.awk /tmp > /tmp/rclients.conf
rm -f /tmp/nas_list_tmp ### Create by mk_rad_nas_awk_list.sh ###
if [ ! -f /db/config/clients.conf ];then
    echo -n > /db/config/clients.conf
    chown nobody.nogroup /db/config/clients.conf
fi

##### for pppoe and pptp #####
ikev2_enable="$(< /db/ikev2/enable)"
if [ -f /tmp/ppp_auth_en -o "${ikev2_enable}" = "Enabled" ]; then
    echo -e "client 127.0.0.1/32 { \n\tsecret\t\t= cipherium\n\tshortname\t= 127.0.0.1/32\n}\n" >>/tmp/rclients.conf
fi
if [ "${CAPWAP_EN}" = "Enabled" -a -z "$(grep -C 1 "client ${SPLIT_TUNNEL_CONFIG}" /tmp/rclients.conf | grep "RVHS")" ]; then
    echo -e "client ${SPLIT_TUNNEL_CONFIG} { \n\tsecret\t\t= RVHS\n\tshortname\t= ${SPLIT_TUNNEL_CONFIG}\n}\n" >>/tmp/rclients.conf
fi
if [ -f /tmp/rclients.conf ]; then
    chown nobody.nogroup /tmp/rclients.conf
    cat /tmp/rclients.conf > /db/config/clients.conf
else
    cat /dev/null > /db/config/clients.conf
fi

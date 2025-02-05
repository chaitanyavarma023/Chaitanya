#!/bin/sh

# Function to display usage and supported protocols
usage() {
  echo "Usage: $0 <protocol> <ACCEPT|DROP>"
  echo "Supported protocols:"
  echo "  ftp, esp, h323, h323-udp, http-proxy2, http-proxy3, http, https, ike"
  echo "  kerberos, l2tp, lpd, msrpc, natt, netbios-dgm, netbios-ns, netbios-ssn"
  echo "  sccp, ntp, pop3, pptp, rtsp, sips, sip, smb, smtp, snmp, ssh, svp"
  echo "  syslog, telnet, tftp, vocera"
  echo "Example: $0 svp DROP"
  exit 1
}

# Check arguments
[ $# -ne 2 ] && usage

protocol=$1
action=$(echo "$2" | tr '[:lower:]' '[:upper:]')
[ "$action" != "ACCEPT" ] && [ "$action" != "DROP" ] && usage

# Function to get AP IP information
get_ap_ip() {
  interface=$1
  ap_ip=$(ip -4 addr show dev "br-wan" 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1)
  ap_network=$(ip route show dev "br-wan" 2>/dev/null | grep proto\ kernel | awk '{print $1}')
  
  [ -z "$ap_ip" ] && echo "Could not determine IP for interface $interface" >&2 && return 1
  [ -z "$ap_network" ] && echo "Could not determine network for interface $interface" >&2 && return 1
  echo "$ap_ip:$ap_network"
}

# Destination selection menu
select_destination() {
  echo "Select destination option:" >&2
  echo "1. To all destinations" >&2
  echo "2. To a particular server" >&2
  echo "3. Except to a particular server" >&2
  echo "4. To a network" >&2
  echo "5. Except to a network" >&2
  echo "6. To AP IP" >&2
  echo "7. To AP network" >&2
#  echo "8. To AP IP all" >&2
  
  while true; do
    read -p "Enter choice (1-8): " dest_choice </dev/tty >&2
    case $dest_choice in
      1)
        dest_param=""
        echo "any:"
        return 0
        ;;
      2)
        read -p "Enter server IP: " server_ip </dev/tty >&2
        dest_param="-d $server_ip"
        echo "server:$dest_param"
        return 0
        ;;
      3)
        read -p "Enter exception server IP: " server_ip </dev/tty >&2
        dest_param="! -d $server_ip"
        echo "except-server:$dest_param"
        return 0
        ;;
      4)
        read -p "Enter network (CIDR format): " network </dev/tty >&2
        dest_param="-d $network"
        echo "network:$dest_param"
        return 0
        ;;
      5)
        read -p "Enter exception network (CIDR format): " network </dev/tty >&2
        dest_param="! -d $network"
        echo "except-network:$dest_param"
        return 0
        ;;
      6|7)
        ap_info=$(get_ap_ip "$interface")
        [ $? -ne 0 ] && return 1
        ap_ip=$(echo "$ap_info" | cut -d: -f1)
        ap_network=$(echo "$ap_info" | cut -d: -f2)
        
        case $dest_choice in
          6)
            dest_param="-d $ap_ip"
            echo "ap-ip:$dest_param"
            ;;
          7)
            dest_param="-d $ap_network"
            echo "ap-network:$dest_param"
            ;;
        esac
        return 0
        ;;
      *)
        echo "Invalid choice!" >&2
        ;;
    esac
  done
}

# Function to manage iptables rules for interfaces
manage_rules_interface() {
  operation=$1  # -A for add, -D for delete
  proto=$2
  port=$3
  dest=$4
  
  common_cmd="$dest -p $proto"
  [ -n "$port" ] && common_cmd="$common_cmd --dport $port"
  
  if [ "$proto" = "esp" ]; then
    iptables $operation INPUT -i "$interface" -p esp -j "$action"
#    iptables $operation OUTPUT -o "$interface" -p esp -j "$action"
    iptables $operation FORWARD -i "$interface" -p esp -j "$action"
    iptables -t raw $operation PREROUTING -i "$interface" -p esp -j "$action"
    iptables -t mangle $operation PREROUTING -i "$interface" -p esp -j "$action"
  else
    iptables $operation INPUT -i "$interface" $common_cmd -j "$action"
 #   iptables $operation OUTPUT -o "$interface" $common_cmd --sport $port -j "$action"
    iptables $operation FORWARD -i "$interface" $common_cmd -j "$action"
    iptables -t raw $operation PREROUTING -i "$interface" $common_cmd -j "$action"
    iptables -t mangle $operation PREROUTING -i "$interface" $common_cmd -j "$action"
  fi
}

# Function to manage iptables rules for SSIDs using physdev
manage_rules_ssid() {
  operation=$1
  proto=$2
  port=$3
  dest=$4

  physdev_in="-m physdev --physdev-in $interface"
  physdev_out="-m physdev --physdev-out $interface"
  
  common_cmd="$dest -p $proto"
  [ -n "$port" ] && common_cmd="$common_cmd --dport $port"
  
  if [ "$proto" = "esp" ]; then
    iptables $operation INPUT $physdev_in -p esp -j "$action"
    iptables $operation OUTPUT $physdev_out -p esp -j "$action"
    iptables $operation FORWARD $physdev_in -p esp -j "$action"
    iptables -t raw $operation PREROUTING $physdev_in -p esp -j "$action"
    iptables -t mangle $operation PREROUTING $physdev_in -p esp -j "$action"
  else
    iptables $operation INPUT $physdev_in $common_cmd -j "$action"
    iptables $operation OUTPUT $physdev_out $common_cmd --sport $port -j "$action"
    iptables $operation FORWARD $physdev_in $common_cmd -j "$action"
    iptables -t raw $operation PREROUTING $physdev_in $common_cmd -j "$action"
    iptables -t mangle $operation PREROUTING $physdev_in $common_cmd -j "$action"
  fi
}

# Collect SSIDs and interfaces
fetch_ssids() {
  MODEL_FILE="/etc/model"
  EXPECTED_MODEL="QN-I-210.HW2"
  if [ -f "$MODEL_FILE" ] && [ "$(cat "$MODEL_FILE")" = "$EXPECTED_MODEL" ]; then
    index=1
else
    index=0
fi
  
  ssid_map=""
  while true; do
    ssid=$(uci -q get "wireless.@wifi-iface[$index].ssid" | sed "s/'//g")
    [ -z "$ssid" ] && break
    iface=$(uci -q get "wireless.@wifi-iface[$index].ifname")
    if [ -n "$iface" ]; then
      ssid_map="$ssid_map"$'\n'"$ssid:$iface"
    fi
    index=$((index + 1))
  done
  echo "$ssid_map" | sed '/^$/d'
}

# User interface selection
select_interface() {
  echo "Select how you want to apply rules:" >&2
  echo "1. Apply rules to SSID" >&2
  echo "2. Apply rules directly to Interface" >&2
  read -p "Enter your choice (1 or 2): " choice </dev/tty >&2

  case "$choice" in
    1)
      ssid_map=$(fetch_ssids)
      [ -z "$ssid_map" ] && echo "No SSIDs found!" >&2 && exit 1
      
      unique_ssids=$(echo "$ssid_map" | cut -d: -f1 | sort -u | awk '{print NR ") " $1}')
      echo "Available SSIDs:" >&2
      echo "$unique_ssids" >&2
      
      read -p "Enter the SSID number: " ssid_num </dev/tty >&2
      if ! echo "$ssid_num" | grep -qE '^[0-9]+$'; then
        echo "Invalid SSID number!" >&2
        exit 1
      fi
      
      selected_ssid=$(echo "$unique_ssids" | sed -n "${ssid_num}p" | awk '{print $2}')
      if [ -z "$selected_ssid" ]; then
        echo "Invalid SSID number!" >&2
        exit 1
      fi
      
      interfaces=$(echo "$ssid_map" | grep "^${selected_ssid}:" | cut -d: -f2 | tr '\n' ' ')
      [ -z "$interfaces" ] && echo "No interfaces found for SSID: $selected_ssid" >&2 && exit 1
      echo "ssid:$interfaces"
      ;;
    2)
      read -p "Enter interface name: " interfaces </dev/tty >&2
      echo "interface:$interfaces"
      ;;
    *)
      echo "Invalid choice!" >&2
      exit 1
      ;;
  esac
}

# Protocol configuration
configure_protocol() {
  case "$protocol" in
    ftp) ports="21"; proto="tcp" ;;
    esp) proto="esp" ;;
    h323) ports="1720"; proto="tcp" ;;
    h323-udp) ports="1719"; proto="udp" ;;
    http-proxy2) ports="8080"; proto="tcp" ;;
    http-proxy3) ports="3128"; proto="tcp" ;;
    http) ports="80"; proto="tcp" ;;
    https) ports="443"; proto="tcp" ;;
    ike) ports="500 4500"; proto="udp" ;;
    l2tp) ports="1701 500 4500"; proto="udp" ;;
    lpd) tcp_ports="515"; udp_ports="515"; proto_tcp="tcp"; proto_udp="udp" ;;
    msrpc) tcp_ports="135"; udp_ports="135"; proto_tcp="tcp"; proto_udp="udp" ;;
    natt) ports="4500"; proto="udp" ;;
    netbios-dgm) ports="138"; proto="udp" ;;
    netbios-ns) ports="137"; proto="udp" ;;
    netbios-ssn) ports="139"; proto="tcp" ;;
    ntp) ports="123"; proto="udp" ;;
    pop3) ports="110 995"; proto="tcp" ;;
    pptp) ports="1723"; proto="tcp" ;;
    sips) tcp_ports="5061"; udp_ports="5061"; proto_tcp="tcp"; proto_udp="udp" ;;
    sip) tcp_ports="5060"; udp_ports="5060"; proto_tcp="tcp"; proto_udp="udp" ;;
    smb) tcp_ports="445 139"; udp_ports="137 138 139"; proto_tcp="tcp"; proto_udp="udp" ;;
    smtp) ports="25 465 587"; proto="tcp" ;;
    snmp) tcp_ports="161"; udp_ports="161 162"; proto_tcp="tcp"; proto_udp="udp" ;;
    vocera) tcp_ports="5100"; udp_ports="5000 16666"; proto_tcp="tcp"; proto_udp="udp" ;;
    ssh) ports="22"; proto="tcp" ;;
    syslog) ports="514"; proto="udp" ;;
    tftp) ports="69"; proto="udp" ;;
    telnet) ports="23"; proto="tcp" ;;
    sccp) tcp_ports="2000 2443"; udp_ports="16384:32767"; proto_tcp="tcp"; proto_udp="udp" ;;
    svp) ports="5060"; proto="udp"; udp_ports="16384:32767"; proto_udp="udp" ;;
    rtsp) tcp_ports="554"; udp_ports="6970:6999"; proto_tcp="tcp"; proto_udp="udp" ;;
    kerberos) tcp_ports="88 464"; udp_ports="88 464"; proto_tcp="tcp"; proto_udp="udp" ;;
    *) echo "Unsupported protocol: $protocol" >&2; usage ;;
  esac
}

# Main execution
selection=$(select_interface)
RULE_METHOD=$(echo "$selection" | cut -d: -f1)
interfaces=$(echo "$selection" | cut -d: -f2-)

configure_protocol

# Apply rules to all selected interfaces
for interface in $interfaces; do
  # Verify interface exists
  if ! ip link show dev "$interface" >/dev/null 2>&1; then
    echo "Interface $interface does not exist!" >&2
    continue
  fi

  # Get destination parameters
  dest_spec=$(select_destination)
  [ $? -ne 0 ] && exit 1
  dest_param=$(echo "$dest_spec" | cut -d: -f2-)
  
  # Delete existing rules first
  case "$protocol" in
    esp)
      if [ "$RULE_METHOD" = "ssid" ]; then
        manage_rules_ssid -D "esp" "" ""
        manage_rules_ssid -A "esp" "" "$dest_param"
      else
        manage_rules_interface -D "esp" "" ""
        manage_rules_interface -A "esp" "" "$dest_param"
      fi
      ;;
    *)
      # Process TCP ports
      if [ -n "$tcp_ports" ]; then
        for port in $tcp_ports; do
          if [ "$RULE_METHOD" = "ssid" ]; then
            manage_rules_ssid -D "tcp" "$port" "$dest_param"
            manage_rules_ssid -A "tcp" "$port" "$dest_param"
          else
            manage_rules_interface -D "tcp" "$port" "$dest_param"
            manage_rules_interface -A "tcp" "$port" "$dest_param"
          fi
        done
      fi
      
      # Process UDP ports
      if [ -n "$udp_ports" ]; then
        for port in $udp_ports; do
          if [ "$RULE_METHOD" = "ssid" ]; then
            manage_rules_ssid -D "udp" "$port" "$dest_param"
            manage_rules_ssid -A "udp" "$port" "$dest_param"
          else
            manage_rules_interface -D "udp" "$port" "$dest_param"
            manage_rules_interface -A "udp" "$port" "$dest_param"
          fi
        done
      fi
      
      # Process generic ports
      if [ -n "$ports" ]; then
        for port in $ports; do
          if [ "$RULE_METHOD" = "ssid" ]; then
            manage_rules_ssid -D "$proto" "$port" "$dest_param"
            manage_rules_ssid -A "$proto" "$port" "$dest_param"
          else
            manage_rules_interface -D "$proto" "$port" "$dest_param"
            manage_rules_interface -A "$proto" "$port" "$dest_param"
          fi
        done
      fi
      ;;
  esac
done

echo "Firewall rules successfully applied to: $interfaces"


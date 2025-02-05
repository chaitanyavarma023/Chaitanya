#!/bin/sh

# Function to display usage and supported protocols
usage() {
  echo "Usage: $0 <protocol> <ACCEPT|DROP>"
  echo "Supported protocols:"
  echo "  ftp"
  echo "  esp"
  echo "  h323"
  echo "  h323-udp"
  echo "  http-proxy2"
  echo "  http-proxy3"
  echo "  http"
  echo "  https"
  echo "  ike"
  echo "  kerberos"
  echo "  l2tp"
  echo "  lpd"
  echo "  msrpc"
  echo "  natt"
  echo "  netbios-dgm"
  echo "  netbios-ns"
  echo "  netbios-ssn"
  echo "  sccp"
  echo "  ntp"
  echo "  pop3"
  echo "  pptp"
  echo "  rtsp"
  echo "  sips"
  echo "  sip"
  echo "  smb"
  echo "  smtp"
  echo "  snmp"
  echo "  ssh"
  echo "  svp"
  echo "  syslog"
  echo "  telnet"
  echo "  tftp"
  echo "  vocera"
  echo "Example: $0 ftp DROP/ACCEPT"
  exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
  usage
fi

# Extract protocol and action from arguments
protocol=$1
action=$2

# Convert action to uppercase
action=$(echo "$action" | tr '[:lower:]' '[:upper:]')

# Validate action (ACCEPT or DROP)
if [ "$action" != "ACCEPT" ] && [ "$action" != "DROP" ]; then
  echo "Error: Action must be 'ACCEPT' or 'DROP'."
  usage
fi

# Define a function to apply iptables rules dynamically based on ports
apply_rules() {
  proto=$1
  port=$2
  action=$3
  range_flag=$4

  if [ "$proto" != "esp" ]; then
    # Handle both port ranges and individual ports
    if [ "$range_flag" = "range" ]; then
      iptables -A INPUT -i br-wan -p $proto --dport $port -j $action
      iptables -A OUTPUT -o br-wan -p $proto --sport $port -j $action
      iptables -A FORWARD -i br-wan -p $proto --dport $port -j $action
      iptables -t raw -A PREROUTING -i br-wan -p $proto --dport $port -j $action
      iptables -t mangle -A PREROUTING -i br-wan -p $proto --dport $port -j $action
    else
      iptables -A INPUT -i br-wan -p $proto --dport $port -j $action
      iptables -A OUTPUT -o br-wan -p $proto --sport $port -j $action
      iptables -A FORWARD -i br-wan -p $proto --dport $port -j $action
      iptables -t raw -A PREROUTING -i br-wan -p $proto --dport $port -j $action
      iptables -t mangle -A PREROUTING -i br-wan -p $proto --dport $port -j $action
    fi
  else
    iptables -A INPUT -i br-wan -p esp -j $action
    iptables -A OUTPUT -o br-wan -p esp -j $action
    iptables -A FORWARD -i br-wan -p esp -j $action
    iptables -t raw -A PREROUTING -i br-wan -p esp -j $action
    iptables -t mangle -A PREROUTING -i br-wan -p esp -j $action
  fi
  echo "$protocol traffic on $proto port $port is now $action."
}

# Process protocol and apply rules dynamically
case "$protocol" in
  ftp)
    ports="21"
    proto="tcp"
    ;;
  esp)
    proto="esp"
    ;;
  h323)
    ports="1720"
    proto="tcp"
    ;;
  h323-udp)
    ports="1719"
    proto="udp"
    ;;
  http-proxy2)                                                             
    ports="8080"                                                                
    proto="tcp"                                                                  
    ;;  
  http-proxy3)                                                             
    ports="3128"                                                                
    proto="tcp"                                                                  
    ;;  
  http)
    ports="80"
    proto="tcp"
    ;;
  https)
    ports="443"
    proto="tcp"
    ;;
  ike)
    ports="500 4500"
    proto="udp"
    ;;
  l2tp)
    ports="1701 500 4500"
    proto="udp"
    ;;
  lpd)
    tcp_ports="515"
    udp_ports="515"
    proto_tcp="tcp"
    proto_udp="udp"
    ;;
  msrpc)
    tcp_ports="135"
    udp_ports="135"
    proto_tcp="tcp"
    proto_udp="udp"
    ;;
  natt)
    ports="4500"
    proto="udp"
    ;;
  netbios-dgm)
    ports="138"
    proto="udp"
    ;;
  netbios-ns)
    ports="137"
    proto="udp"
    ;;
  netbios-ssn)
    ports="139"
    proto="tcp"
    ;;
  ntp)
    ports="123"
    proto="udp"
    ;;
  pop3)
    ports="110 995"
    proto="tcp"
    ;;
  pptp)
    ports="1723"
    proto="tcp"
    ;;
  sips)
   tcp_ports="5061"
   udp_ports="5061"
   proto_tcp="tcp"
   proto_udp="udp"
   ;;
  sip)
   tcp_ports="5060"
   udp_ports="5060"
   proto_tcp="tcp"
   proto_udp="udp"
   ;;
  smb)
   tcp_ports="445 139"
   udp_ports="137 138 139"
   proto_tcp="tcp"
   proto_udp="udp"
   ;;
  smtp)
   ports="25 465 587"
   proto="tcp"
   ;;
  snmp)
   tcp_ports="161"
   udp_ports="161 162"
   proto_tcp="tcp"
   proto_udp="udp"
   ;;
  vocera)
   tcp_ports="5100"
   udp_ports="5000 16666"
   proto_tcp="tcp"
   proto_udp="udp"
   ;;
  ssh)
   ports="22"
   proto="tcp"
   ;;
  syslog)
   ports="514"
   proto="udp"
   ;;
  tftp)
   ports="69"
   proto="udp"
   ;;
  telnet)
   ports="23"
   proto="tcp"
   ;;
  sccp)
    tcp_ports="2000 2443"
    udp_ports="16384:32767"
    proto_tcp="tcp"
    proto_udp="udp"
    ;;
  svp)
    ports="5060"
    proto="udp"
    udp_ports="16384:32767"
    proto_udp="udp"
    ;;
  rtsp)
    tcp_ports="554"
    proto_tcp="tcp"
    udp_ports="6970:6999"
    proto_udp="udp"
    ;;
  kerberos)
    tcp_ports="88 464"
    udp_ports="88 464"
    proto_tcp="tcp"
    proto_udp="udp"
    ;;
  *)
    echo "Error: Unsupported protocol '$protocol'."
    usage
    ;;
esac

# Apply rules for ESP
if [ "$protocol" = "esp" ]; then
  iptables -A INPUT -i br-wan -p esp -j $action
  iptables -A OUTPUT -o br-wan -p esp -j $action
  iptables -A FORWARD -i br-wan -p esp -j $action
  iptables -t raw -A PREROUTING -i br-wan -p esp -j $action
  iptables -t mangle -A PREROUTING -i br-wan -p esp -j $action
else
  # Apply rules for protocols with both tcp and udp ports
  if [ -n "$tcp_ports" ]; then
    for port in $tcp_ports; do
      apply_rules "$proto_tcp" "$port" "$action" "single"
    done
  fi

  if [ -n "$udp_ports" ]; then
    for port in $udp_ports; do
      apply_rules "$proto_udp" "$port" "$action" "range"
    done
  fi

  # Apply rules for single protocol (e.g., ftp, http, etc.)
  if [ -n "$ports" ]; then
    for port in $ports; do
      if echo "$port" | grep -q ":"; then
        apply_rules "$proto" "$port" "$action" "range"
      else
        apply_rules "$proto" "$port" "$action" "single"
      fi
    done
  fi
fi


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


#!/bin/sh

# Function to display usage and supported protocols
usage() {
  echo "Usage: $0 <protocol> <ACCEPT|DROP>"
  echo "Supported protocols:"
  echo "  ftp, esp, h323, h323-udp, http-proxy2, http-proxy3, http, https, ike, kerberos, l2tp, lpd, msrpc, natt,"
  echo "  netbios-dgm, netbios-ns, netbios-ssn, sccp, ntp, pop3, pptp, rtsp, sips, sip, smb, smtp, snmp, ssh,"
  echo "  svp, syslog, telnet, tftp, vocera"
  echo "Example: $0 ftp DROP/ACCEPT"
  exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
  usage
fi

# Ask the user to input the network interface
read -p "Enter the network interface (e.g., eth0, wlan0, br-wan): " interface

# Extract protocol and action from arguments
protocol=$1
action=$2

# Convert action to uppercase
action=$(echo "$action" | tr '[:lower:]' '[:upper:]')

# Validate action (ACCEPT or DROP)
if [ "$action" != "ACCEPT" ] && [ "$action" != "DROP" ]; then
  echo "Error: Action must be 'ACCEPT' or 'DROP'."
  usage
fi

# Function to apply iptables rules dynamically based on ports
apply_rules() {
  proto=$1
  port=$2
  action=$3
  range_flag=$4

  if [ "$proto" != "esp" ]; then
    # Handle both port ranges and individual ports
    if [ "$range_flag" = "range" ]; then
      iptables -A INPUT -i $interface -p $proto --dport $port -j $action
      iptables -A OUTPUT -o $interface -p $proto --sport $port -j $action
      iptables -A FORWARD -i $interface -p $proto --dport $port -j $action
      iptables -t raw -A PREROUTING -i $interface -p $proto --dport $port -j $action
      iptables -t mangle -A PREROUTING -i $interface -p $proto --dport $port -j $action
    else
      iptables -A INPUT -i $interface -p $proto --dport $port -j $action
      iptables -A OUTPUT -o $interface -p $proto --sport $port -j $action
      iptables -A FORWARD -i $interface -p $proto --dport $port -j $action
      iptables -t raw -A PREROUTING -i $interface -p $proto --dport $port -j $action
      iptables -t mangle -A PREROUTING -i $interface -p $proto --dport $port -j $action
    fi
  else
    iptables -A INPUT -i $interface -p esp -j $action
    iptables -A OUTPUT -o $interface -p esp -j $action
    iptables -A FORWARD -i $interface -p esp -j $action
    iptables -t raw -A PREROUTING -i $interface -p esp -j $action
    iptables -t mangle -A PREROUTING -i $interface -p esp -j $action
  fi
  echo "$protocol traffic on $proto port $port is now $action on $interface."
}

# Define port mappings for protocols
case "$protocol" in
  ftp) ports="21"; proto="tcp";;
  esp) proto="esp";;
  h323) ports="1720"; proto="tcp";;
  h323-udp) ports="1719"; proto="udp";;
  http-proxy2) ports="8080"; proto="tcp";;
  http-proxy3) ports="3128"; proto="tcp";;
  http) ports="80"; proto="tcp";;
  https) ports="443"; proto="tcp";;
  ike) ports="500 4500"; proto="udp";;
  l2tp) ports="1701 500 4500"; proto="udp";;
  ntp) ports="123"; proto="udp";;
  pop3) ports="110 995"; proto="tcp";;
  pptp) ports="1723"; proto="tcp";;
  sips) tcp_ports="5061"; udp_ports="5061"; proto_tcp="tcp"; proto_udp="udp";;
  sip) tcp_ports="5060"; udp_ports="5060"; proto_tcp="tcp"; proto_udp="udp";;
  smb) tcp_ports="445 139"; udp_ports="137 138 139"; proto_tcp="tcp"; proto_udp="udp";;
  smtp) ports="25 465 587"; proto="tcp";;
  snmp) tcp_ports="161"; udp_ports="161 162"; proto_tcp="tcp"; proto_udp="udp";;
  ssh) ports="22"; proto="tcp";;
  syslog) ports="514"; proto="udp";;
  tftp) ports="69"; proto="udp";;
  telnet) ports="23"; proto="tcp";;
  sccp) tcp_ports="2000 2443"; udp_ports="16384:32767"; proto_tcp="tcp"; proto_udp="udp";;
  rtsp) tcp_ports="554"; udp_ports="6970:6999"; proto_tcp="tcp"; proto_udp="udp";;
  kerberos) tcp_ports="88 464"; udp_ports="88 464"; proto_tcp="tcp"; proto_udp="udp";;
  *) echo "Error: Unsupported protocol '$protocol'."; usage;;
esac

# Apply rules
if [ "$protocol" = "esp" ]; then
  iptables -A INPUT -i $interface -p esp -j $action
  iptables -A OUTPUT -o $interface -p esp -j $action
  iptables -A FORWARD -i $interface -p esp -j $action
  iptables -t raw -A PREROUTING -i $interface -p esp -j $action
  iptables -t mangle -A PREROUTING -i $interface -p esp -j $action
else
  if [ -n "$tcp_ports" ]; then
    for port in $tcp_ports; do
      apply_rules "$proto_tcp" "$port" "$action" "single"
    done
  fi
  if [ -n "$udp_ports" ]; then
    for port in $udp_ports; do
      apply_rules "$proto_udp" "$port" "$action" "range"
    done
  fi
  if [ -n "$ports" ]; then
    for port in $ports; do
      apply_rules "$proto" "$port" "$action" "single"
    done
  fi
fi

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


#!/bin/sh

# Function to display usage and supported protocols
usage() {
  echo "Usage: $0 <interface> <protocol> <ACCEPT|DROP>"
  echo "Supported protocols:"
  echo "  ftp, esp, h323, h323-udp, http-proxy2, http-proxy3, http, https, ike"
  echo "  kerberos, l2tp, lpd, msrpc, natt, netbios-dgm, netbios-ns, netbios-ssn"
  echo "  sccp, ntp, pop3, pptp, rtsp, sips, sip, smb, smtp, snmp, ssh, svp"
  echo "  syslog, telnet, tftp, vocera"
  echo "Example: $0 eth0 ftp DROP"
  exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 3 ]; then
  usage
fi

# Extract interface, protocol, and action from arguments
interface=$1
protocol=$2
action=$3

# Convert action to uppercase
action=$(echo "$action" | tr '[:lower:]' '[:upper:]')

# Validate action (ACCEPT or DROP)
if [ "$action" != "ACCEPT" ] && [ "$action" != "DROP" ]; then
  echo "Error: Action must be 'ACCEPT' or 'DROP'."
  usage
fi

# Define function to delete existing rules before applying new ones
delete_existing_rules() {
  proto=$1
  port=$2
  opposite_action=$3

  if [ "$proto" = "esp" ]; then
    iptables -D INPUT -i "$interface" -p esp -j "$opposite_action" 2>/dev/null
    iptables -D OUTPUT -o "$interface" -p esp -j "$opposite_action" 2>/dev/null
    iptables -D FORWARD -i "$interface" -p esp -j "$opposite_action" 2>/dev/null
    iptables -t raw -D PREROUTING -i "$interface" -p esp -j "$opposite_action" 2>/dev/null
    iptables -t mangle -D PREROUTING -i "$interface" -p esp -j "$opposite_action" 2>/dev/null
  else
    iptables -D INPUT -i "$interface" -p "$proto" --dport "$port" -j "$opposite_action" 2>/dev/null
    iptables -D OUTPUT -o "$interface" -p "$proto" --sport "$port" -j "$opposite_action" 2>/dev/null
    iptables -D FORWARD -i "$interface" -p "$proto" --dport "$port" -j "$opposite_action" 2>/dev/null
    iptables -t raw -D PREROUTING -i "$interface" -p "$proto" --dport "$port" -j "$opposite_action" 2>/dev/null
    iptables -t mangle -D PREROUTING -i "$interface" -p "$proto" --dport "$port" -j "$opposite_action" 2>/dev/null
  fi
}

# Function to apply iptables rules
apply_rules() {
  proto=$1
  port=$2
  action=$3

  iptables -A INPUT -i "$interface" -p "$proto" --dport "$port" -j "$action"
  iptables -A OUTPUT -o "$interface" -p "$proto" --sport "$port" -j "$action"
  iptables -A FORWARD -i "$interface" -p "$proto" --dport "$port" -j "$action"
  iptables -t raw -A PREROUTING -i "$interface" -p "$proto" --dport "$port" -j "$action"
  iptables -t mangle -A PREROUTING -i "$interface" -p "$proto" --dport "$port" -j "$action"

  echo "$protocol traffic on $proto port $port is now $action."
}

# Set opposite action (if applying ACCEPT, remove DROP rules first and vice versa)
if [ "$action" = "ACCEPT" ]; then
  opposite_action="DROP"
else
  opposite_action="ACCEPT"
fi

# Define protocol-port mappings
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
  *)
    echo "Error: Unsupported protocol '$protocol'."
    usage
    ;;
esac

# Apply rules for ESP separately
if [ "$protocol" = "esp" ]; then
  delete_existing_rules "esp" "" "$opposite_action"
  apply_rules "esp" "" "$action"
else
  # Apply rules for protocols with both TCP and UDP ports
  if [ -n "$tcp_ports" ]; then
    for port in $tcp_ports; do
      delete_existing_rules "$proto_tcp" "$port" "$opposite_action"
      apply_rules "$proto_tcp" "$port" "$action"
    done
  fi

  if [ -n "$udp_ports" ]; then
    for port in $udp_ports; do
      delete_existing_rules "$proto_udp" "$port" "$opposite_action"
      apply_rules "$proto_udp" "$port" "$action"
    done
  fi

  # Apply rules for single protocol (e.g., ftp, http, etc.)
  if [ -n "$ports" ]; then
    for port in $ports; do
      delete_existing_rules "$proto" "$port" "$opposite_action"
      apply_rules "$proto" "$port" "$action"
    done
  fi
fi


################################################################################################################33
##############################################################################################################################
###################################################################################################################################################
############################################################################################################################################



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

# Function to manage iptables rules
manage_rules() {
  operation=$1  # -A for add, -D for delete
  proto=$2
  port=$3
  
  if [ "$proto" = "esp" ]; then
    iptables $operation INPUT -i "$interface" -p esp -j "$action"
    iptables $operation OUTPUT -o "$interface" -p esp -j "$action"
    iptables $operation FORWARD -i "$interface" -p esp -j "$action"
    iptables -t raw $operation PREROUTING -i "$interface" -p esp -j "$action"
    iptables -t mangle $operation PREROUTING -i "$interface" -p esp -j "$action"
  else
    iptables $operation INPUT -i "$interface" -p "$proto" --dport "$port" -j "$action"
    iptables $operation OUTPUT -o "$interface" -p "$proto" --sport "$port" -j "$action"
    iptables $operation FORWARD -i "$interface" -p "$proto" --dport "$port" -j "$action"
    iptables -t raw $operation PREROUTING -i "$interface" -p "$proto" --dport "$port" -j "$action"
    iptables -t mangle $operation PREROUTING -i "$interface" -p "$proto" --dport "$port" -j "$action"
  fi
}

# Collect SSIDs and interfaces
fetch_ssids() {
  index=0
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
      
      # Generate unique SSID list for display
      unique_ssids=$(echo "$ssid_map" | cut -d: -f1 | sort -u | awk '{print NR ") " $1}')
      echo "Available SSIDs:" >&2
      echo "$unique_ssids" >&2
      
      read -p "Enter the SSID number: " ssid_num </dev/tty >&2
      # Validate numeric input
      if ! echo "$ssid_num" | grep -qE '^[0-9]+$'; then
        echo "Invalid SSID number!" >&2
        exit 1
      fi
      
      # Extract selected SSID name
      selected_ssid=$(echo "$unique_ssids" | sed -n "${ssid_num}p" | awk '{print $2}')
      if [ -z "$selected_ssid" ]; then
        echo "Invalid SSID number!" >&2
        exit 1
      fi
      
      # Get all interfaces for the SSID
      interfaces=$(echo "$ssid_map" | grep "^${selected_ssid}:" | cut -d: -f2 | tr '\n' ' ')
      [ -z "$interfaces" ] && echo "No interfaces found for SSID: $selected_ssid" >&2 && exit 1
      ;;
    2)
      read -p "Enter interface name: " interfaces </dev/tty >&2
      ;;
    *)
      echo "Invalid choice!" >&2
      exit 1
      ;;
  esac
  
  echo "$interfaces"
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
interfaces=$(select_interface)
configure_protocol

# Apply rules to all selected interfaces
for interface in $interfaces; do
  # Verify interface exists
  if ! ip link show dev "$interface" >/dev/null 2>&1; then
    echo "Interface $interface does not exist!" >&2
    continue
  fi

  # Delete existing rules first
  case "$protocol" in
    esp)
      manage_rules -D "esp" ""
      manage_rules -A "esp" ""
      ;;
    *)
      # Process TCP ports
      if [ -n "$tcp_ports" ]; then
        for port in $tcp_ports; do
          manage_rules -D "tcp" "$port"
          manage_rules -A "tcp" "$port"
        done
      fi
      
      # Process UDP ports
      if [ -n "$udp_ports" ]; then
        for port in $udp_ports; do
          manage_rules -D "udp" "$port"
          manage_rules -A "udp" "$port"
        done
      fi
      
      # Process generic ports
      if [ -n "$ports" ]; then
        for port in $ports; do
          manage_rules -D "$proto" "$port"
          manage_rules -A "$proto" "$port"
        done
      fi
      ;;
  esac
done

echo "Firewall rules successfully applied to: $interfaces"

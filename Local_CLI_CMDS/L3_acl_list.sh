#!/bin/sh

# Function to get interface information (SSID and ifname)
get_iface_info() {
    # Get unique names without suffix
    iface_names=$(uci show wireless | grep -Eo "wireless\.[^=]+\.name='WLAN[^']+'" | cut -d= -f2 | tr -d "'" | sed 's/_[0-9]*$//' | sort | uniq)

    echo "$iface_names" | while read -r name; do
        # Use grep to find matching blocks
        matching_block=$(uci show wireless | grep -A5 -E "name='$name(_[0-9]*)?'")

        # Extract SSID and ifname for the matching block
        ssid=$(echo "$matching_block" | grep -Eo "ssid='[^']+'" | cut -d= -f2 | tr -d "'")
        ifname=$(echo "$matching_block" | grep -Eo "ifname='[^']+'" | cut -d= -f2 | tr -d "'")

        # Only process interfaces with non-empty SSID and ifname
        if [ -n "$ssid" ] && [ -n "$ifname" ]; then
            # Output interface information
            echo "$name"
        fi
    done
}

print_ssids() {
    # Check if an argument is provided (interface name)
    if [ -z "$1" ]; then
        echo "Error: No interface name provided"
        return 1
    fi

    interface_name="$1"
    
    # Fetch the block of details for the specific interface
    matching_block=$(uci show wireless | grep -A5 -E "name='$interface_name(_[0-9]*)?'")

    # Check if the matching block is found
    if [ -z "$matching_block" ]; then
        echo "Error: Interface $interface_name not found"
        return 1
    fi

    # Extract the SSID for the interface
    ssid=$(echo "$matching_block" | grep -Eo "ssid='[^']+'" | cut -d= -f2 | tr -d "'" | sort | uniq )

    # Check if SSID was found
    if [ -z "$ssid" ]; then
        echo "Error: No SSID found for interface $interface_name"
        return 1
    fi

    # Output the SSID associated with the given interface
    echo "$ssid"
}

# Function to decode and print each rule
decode_rule() {
    local rule="$1"
    local priority="$2"  # Pass the priority to the function
    
    # Initialize variables
    protocol=""
    dport=""
    sport=""
    src_ip=""
    dst_ip=""
    ip_type=""
    action=""
    
    # Extract protocol (udp, tcp, or none)
    if echo "$rule" | grep -q -- "--ip-proto udp"; then
        protocol="udp"
    elif echo "$rule" | grep -q -- "--ip-proto tcp"; then
        protocol="tcp"
    elif echo "$rule" | grep -q -- "--ip-proto icmp"; then
        protocol="ICMPV4"
    elif echo "$rule" | grep -q -- "--ip-proto igmp"; then
        protocol="IGMP"
    elif echo "$rule" | grep -q -- "--ip-proto esp"; then
        protocol="ESP"
    elif echo "$rule" | grep -q -- "--ip-proto ah"; then
        protocol="AH"   
    fi
    
    # Extract source or destination port
    if echo "$rule" | grep -q -- "--ip-dport"; then
        dport=$(echo "$rule" | sed -n 's/.*--ip-dport \([0-9]*\(:[0-9]*\)\?\).*/\1/p')
    fi
    if echo "$rule" | grep -q -- "--ip-sport"; then
        sport=$(echo "$rule" | sed -n 's/.*--ip-sport \([0-9]*\(:[0-9]*\)\?\).*/\1/p')
    fi
    
    # Extract IP addresses, subnet and determine type (IPv4 or IPv6)
    if echo "$rule" | grep -q -- "--ip-src"; then
        src_ip=$(echo "$rule" | sed -n 's/.*--ip-src \([0-9.]*\/[0-9]*\).*/\1/p')
        if [ -z "$src_ip" ]; then
            src_ip=$(echo "$rule" | sed -n 's/.*--ip-src \([0-9.]*\).*/\1/p')
        fi
        ip_type="IPv4"
    fi
    if echo "$rule" | grep -q -- "--ip-dst"; then
        dst_ip=$(echo "$rule" | sed -n 's/.*--ip-dst \([0-9.]*\/[0-9]*\).*/\1/p')
        if [ -z "$dst_ip" ]; then
            dst_ip=$(echo "$rule" | sed -n 's/.*--ip-dst \([0-9.]*\).*/\1/p')
        fi
        ip_type="IPv4"
    fi
    if echo "$rule" | grep -q -- "-p IPv4"; then
        ip_type="IPv4"
    fi
    if echo "$rule" | grep -q -- "-p IPv6"; then
        ip_type="IPv6"
    fi
    
    # Extract action (ACCEPT, DROP, RETURN, etc.)
    if echo "$rule" | grep -q -- "-j ACCEPT"; then
        action="ACCEPT"
    elif echo "$rule" | grep -q -- "-j DROP"; then
        action="DROP"
    elif echo "$rule" | grep -q -- "-j RETURN"; then
        action="RETURN"
    fi

    # Replace empty fields with "ANY"
    protocol="${protocol:-ANY}"
    sport="${sport:-ANY}"
    dport="${dport:-ANY}"
    src_ip="${src_ip:-ANY}"
    dst_ip="${dst_ip:-ANY}"
    ip_type="${ip_type:-ANY}"
    action="${action:-ANY}"

    # Output the decoded rule in tabular format with the new Priority column
    # Adjust column widths with printf for proper alignment
    printf "%-10s | %-10s | %-8s | %-10s | %-14s | %-18s | %-16s | %-16s | %-10s\n" "$priority" "$ssid" "$ip_type" "$protocol" "$sport" "$dport" "$src_ip" "$dst_ip" "$action"
}

# Main script

# Print table header with the new "Priority" column
echo "-----------------------------------------------------------------------------------------------------------------------------------" 
printf "%-10s | %-10s | %-8s | %-10s | %-14s | %-18s | %-16s | %-16s | %-10s\n" "Priority" "SSID" "IP-Type" "Protocol" "Source Port" "Destination Port" "Source IP" "Destination IP" "Action"


# Track last SSID to reset priority
last_ssid=""
priority=1

get_iface_info | while read -r name; do
    ssid=$(print_ssids "$name")
echo "-----------------------------------------------------------------------------------------------------------------------------------" 
    if [ -z "$ssid" ]; then
        continue
    fi
    
    # Reset priority if SSID has changed
    if [ "$ssid" != "$last_ssid" ]; then
        priority=1
    fi
    last_ssid="$ssid"

    chain_name="UserTrafficACL_${name}"

    # Get the rules from ebtables command
    rules=$(ebtables -t broute -L "$chain_name")

    # Check if any rules were retrieved
    if [ -z "$rules" ]; then
        echo "No rules found in the chain: $chain_name SSID: $ssid"
    fi

    rule_count=1
    echo "$rules" | while read -r rule; do
        # Skip empty lines or lines that don't start with a valid rule
        if [ -n "$rule" ] && echo "$rule" | grep -q "^-" ; then
            # Call decode_rule for each valid rule and print the result in table format
            decode_rule "$rule" "$priority"
            # Increment priority after each rule
            priority=$((priority + 1))
        fi
    done
done

echo "-----------------------------------------------------------------------------------------------------------------------------------" 
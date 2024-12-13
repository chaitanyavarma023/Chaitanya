#!/bin/sh

Isolation_info() {
    # Get unique names without suffix
    iface_names=$(uci show wireless | grep -Eo "wireless\.[^=]+\.name='WLAN[^']+'" | cut -d= -f2 | tr -d "'" | sed 's/_[0-9]*$//' | sort | uniq)

    echo "$iface_names" | while read -r name; do
        # Use grep to find matching blocks for the given interface name
        matching_block=$(uci show wireless | grep -A10 -E "name='$name(_[0-9]*)?'")

        # Extract SSID, ifname, isolate, intra_vlan, and inter_vlan for the matching block
        ssid=$(echo "$matching_block" | grep -Eo "ssid='[^']+'" | cut -d= -f2 | tr -d "'" | sort | uniq )
        isolate=$(echo "$matching_block" | grep -Eo "isolate='[^']+'" | cut -d= -f2 | tr -d "'" | sort | uniq )
        intra_vlan=$(echo "$matching_block" | grep -Eo "intra_vlan='[^']+'" | cut -d= -f2 | tr -d "'" | sort | uniq )
        inter_vlan=$(echo "$matching_block" | grep -Eo "inter_vlan='[^']+'" | cut -d= -f2 | tr -d "'" | sort | uniq )
	
	echo "--------------------------------------------------------------------------------"
        # Only process interfaces with non-empty SSID, ifname, and relevant isolation values
        if [ "$isolate" = "1" ] || [ "$inter_vlan" = "1" ] || [ "$intra_vlan" = "1" ]; then
            # Output interface information
            echo  -n "SSID: $ssid "
		if [[ "$isolate" == "1" ]]; then
            echo -n "  Full Isolation=1"
        fi
        if [[ "$intra_vlan" == "1" ]]; then
            echo -n "  Deny Intra Vlan Traffic=1"
        fi
        if [[ "$inter_vlan" == "1" ]]; then
            echo -n "  Deny Inter User Bridging=1"
        fi
	echo ""
	echo "--------------------------------------------------------------------------------"
        fi

	whitelist_file="/usr/lib/lua/luci/L3/Client_Isolation_whitelist"

    # Check if file exists
    if [[ ! -f "$whitelist_file" ]]; then
        echo "Whitelist file not found: $whitelist_file"
        return 1
    fi
	
	entry=$(grep "$name" "$whitelist_file")

	# If found, parse and print MAC-IP pairs
    if [[ -n "$entry" ]]; then
        echo "| Exception MAC address           |     Exception IP address"
        echo "--------------------------------------------------------------------------------"
        # Loop through the MAC-IP pairs and print them
        echo "$entry" | tr ',' '\n' | while IFS='=' read -r mac ip; do
            # Remove the 'WLAN5682#' prefix from the MAC address if present
            #mac=$(echo "$mac" | sed 's/^WLAN5682#//')
           mac=$(echo "$mac" | sed 's/^WLAN[0-9]*#//') 
            # Print the MAC and IP with proper formatting
            printf "| %-30s  |    %s\n" "$mac" "$ip"
        done
    else
        echo "No matching SSID entry found in the whitelist for SSID: $ssid"
    fi
    done
}

Isolation_info
echo "--------------------------------------------------------------------------------"

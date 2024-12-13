
#!/bin/sh

# Function to get wireless interface names and their associated SSIDs
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
            echo "$name $ssid"
        fi
    done
}

# Main script to display WPA PSK contents for each wireless interface
display_wpa_psk() {
    get_iface_info | while read -r name ssid; do
        # Define the path to the WPA PSK file based on the interface name
        wpa_psk_file="/etc/WPA_PSK/wpa_psk_$name"

        # Check if the WPA PSK file exists
        if [ -f "$wpa_psk_file" ]; then
	echo "--------------------------------------------------------------"
        echo "|                 SSID: $ssid "
	echo "--------------------------------------------------------------"
                        # Header for mac and password
            printf "| %-25s | %-30s\n" "mac list" "password"
            echo "--------------------------------------------------------------"
            
            # Extract MAC addresses and passwords
            while read -r line; do
                # Split the line into MAC and password
                mac=$(echo "$line" | cut -d' ' -f1)
                pass=$(echo "$line" | cut -d' ' -f2)

                # Print the mac and password aligned
                printf "| %-25s | %-30s\n" "$mac" "$pass"
            done < "$wpa_psk_file"

        fi
    done
}

# Execute the display function
display_wpa_psk

echo "--------------------------------------------------------------"

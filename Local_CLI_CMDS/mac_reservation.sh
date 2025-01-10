#!/bin/sh

# Path to the dhcp configuration file
CONFIG_FILE="/etc/config/dhcp"

# Function to extract and print information for each host block under a given VLAN section
extract_vlan_info() {
    vlan_id="$1"
    in_vlan_section=0

    # Print a header for the table
    echo "-----------------------------------------------------------------------------------"
    printf "%-15s %-25s %-20s %-15s\n" "VLAN ID" "Name" "MAC" "IP"
    echo "-----------------------------------------------------------------------------------"

    # Loop through each line in the configuration file
    while IFS= read -r line; do
        # Check for the start of a VLAN section
        echo "$line" | grep -q "config dhcp '$vlan_id'"
        if [ $? -eq 0 ]; then
            in_vlan_section=1
            continue
        fi

        # If we're in the VLAN section and encounter a host section, extract its information
        if [ $in_vlan_section -eq 1 ]; then
            echo "$line" | grep -q "config host"
            if [ $? -eq 0 ]; then
                # Extract the name, MAC, and IP address
                name=""
                mac=""
                ip=""

                # Read the next few lines to get the host information
                while IFS= read -r host_line; do
                    echo "$host_line" | grep -q "option name"
                    if [ $? -eq 0 ]; then
                        name=$(echo "$host_line" | awk -F"'" '{print $2}')
                    fi
                    echo "$host_line" | grep -q "option mac"
                    if [ $? -eq 0 ]; then
                        mac=$(echo "$host_line" | awk -F"'" '{print $2}')
                    fi
                    echo "$host_line" | grep -q "option ip"
                    if [ $? -eq 0 ]; then
                        ip=$(echo "$host_line" | awk -F"'" '{print $2}')
                    fi

                    # Once we have all the details for a host, print them and exit the loop
                    if [ -n "$name" ] && [ -n "$mac" ] && [ -n "$ip" ]; then
                        # Print the data in a table row
                        printf "%-15s %-25s %-20s %-15s\n" "$vlan_id" "$name" "$mac" "$ip"
                        break
                    fi

                    # Exit the loop if we encounter the next section or the end of the file
                    echo "$host_line" | grep -q "config dhcp"
                    if [ $? -eq 0 ]; then
                        break
                    fi
                done
            fi
        fi
        # Exit the VLAN section if we encounter the next section
        echo "$line" | grep -q "config dhcp"
        if [ $? -eq 0 ]; then
            in_vlan_section=0
        fi
    done < "$CONFIG_FILE"
echo "-----------------------------------------------------------------------------------"
        echo ""
}

# Extract and display information for all VLAN sections in the configuration file
extract_all_vlans() {
    current_vlan=""

    # Loop through each line of the configuration file to find all VLAN sections
    while IFS= read -r line; do
        echo "$line" | grep -q "config dhcp 'vlan[0-9]*'"
        if [ $? -eq 0 ]; then
            # Extract the VLAN ID from the line
            current_vlan=$(echo "$line" | sed -n "s/.*config dhcp '\(vlan[0-9]*\)'.*/\1/p")
            # Call the function to extract info for the current VLAN
            extract_vlan_info "$current_vlan"
        fi
    done < "$CONFIG_FILE"
}

# Start the extraction process for all VLANs
extract_all_vlans

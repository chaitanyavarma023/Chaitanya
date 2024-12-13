#!/bin/sh

# Initialize an empty string to track processed SSIDs
processed_ssids=""

# Loop through each wifi-iface configuration
uci show wireless | grep "wifi-iface" | while read line; do
    # Extract the interface name (e.g., wireless.@wifi-iface[1])
    iface=$(echo $line | cut -d'=' -f1)

    # Get the SSID, macfilter, and maclist values
    ssid=$(uci get $iface.ssid 2>/dev/null)
    macfilter=$(uci get $iface.macfilter 2>/dev/null)
    maclist=$(uci get $iface.maclist 2>/dev/null)

    # Check if SSID, macfilter, and maclist are not empty
    if [ "$ssid" != "" ] && [ "$macfilter" != "" ] && [ "$maclist" != "" ]; then
        # Check if this SSID has already been printed
        if ! echo "$processed_ssids" | grep -q "$ssid"; then
            # Add the SSID to the processed list
            processed_ssids="$processed_ssids $ssid"

            # Print the SSID, MAC filter, and MAC list
            echo "SSID: $ssid"
            echo "MAC Filter: $macfilter"
            echo "MAC List: $maclist"
            echo "-----------------------------------"
        fi
    fi
done













################################################################################################
################################################################################################
################################################################################################



#!/bin/bash

# Function to print a consistent length colored separator line (single line separator)
print_separator() {
    echo -e "\033[1;34m=========================================================\033[0m"
}

# Function to print a consistent length colored double separator line (for section distinction) in red
print_double_separator() {
    echo -e "\033[1;31m==========================================================\033[0m"
}

# Function to print headings with simulated larger size (bold, black, and triple size with more framing)
print_heading() {
    echo -e "\033[1;30m############################ $1 ############################\033[0m"
}

echo
echo

# Print heading for configuration section
print_heading "CONFIGURATION"
print_separator

# Initialize an empty string to track processed SSIDs
processed_ssids=""

# Loop through each wifi-iface configuration to fetch SSID, MAC filter, and MAC list
uci show wireless | grep "wifi-iface" | while read line; do
    # Extract the interface name (e.g., wireless.@wifi-iface[1])
    iface=$(echo $line | cut -d'=' -f1)

    # Get the SSID, macfilter, and maclist values
    ssid=$(uci get $iface.ssid 2>/dev/null)
    macfilter=$(uci get $iface.macfilter 2>/dev/null)
    maclist=$(uci get $iface.maclist 2>/dev/null)

    # Check if SSID, macfilter, and maclist are not empty
    if [ "$ssid" != "" ] && [ "$macfilter" != "" ] && [ "$maclist" != "" ]; then
        # Check if this SSID has already been printed
        if ! echo "$processed_ssids" | grep -q "$ssid"; then
            # Add the SSID to the processed list
            processed_ssids="$processed_ssids $ssid"

            # Print the SSID, MAC filter, and MAC list
            echo "SSID: $ssid"
            echo "MAC Filter: $macfilter"
            echo "MAC List: $maclist"
            print_separator
        fi
    fi
done

# Print double separator to distinguish sections with red color
print_double_separator
echo
echo

# Print heading for applied section
print_heading "APPLIED"


# Loop through each wireless interface from iw dev and get the associated SSID
iw dev | grep -B 4 "ssid" | while read line; do
    # Extract the interface name (it should be a line starting with "Interface")
    if echo "$line" | grep -q "Interface"; then
        iface=$(echo "$line" | awk '{print $2}')
    fi
    
    # Check if the line contains "ssid" to get the SSID line
    if echo "$line" | grep -q "ssid"; then
        # Extract the SSID name from the output
        ssid=$(echo $line | awk '{print $2}')
        
        # Check if iface and ssid are not empty
        if [ -n "$iface" ] && [ -n "$ssid" ]; then
            # Check if SSID has been processed already
            if ! echo "$processed_ssids" | grep -q "$ssid"; then
                # Mark this SSID as processed by adding it to the list
                processed_ssids="$processed_ssids $ssid"

                print_separator
                # Print the interface and SSID
                echo -e "Checking SSID: \033[1;32m$ssid\033[0m on interface: $iface"
                
                # Add a short delay before executing hostapd_cli
                sleep 1

                # Check accept_acl for the interface
                accept_output=$(hostapd_cli -i "$iface" -p /var/run/hostapd accept_acl SHOW)
                if [ -n "$accept_output" ]; then
                    echo "$ssid"
                    echo "accept"
                    print_separator
                    # Remove VLAN_ID=0 word, leave the rest of the line intact
                    echo "$accept_output" | sed 's/VLAN_ID=0//g' | sed '/^$/d' # Remove VLAN_ID=0
                fi

                ###Check deny_acl for the interface
                deny_output=$(hostapd_cli -i "$iface" -p /var/run/hostapd deny_acl SHOW)
                if [ -n "$deny_output" ]; then
                    echo "$ssid"
                    echo "deny"
                    print_separator
                    ####Remove VLAN_ID=0 word, leave the rest of the line intact#
                    echo "$deny_output" | sed 's/VLAN_ID=0//g' | sed '/^$/d' # Remove VLAN_ID=0
                fi
            fi
        fi
    fi
done

# Final double separator with red color
print_double_separator











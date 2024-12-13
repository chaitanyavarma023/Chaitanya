#!/bin/sh

# Initialize an empty string to track processed SSIDs
processed_ssids=""

# Print the heading for the configuration section
echo "------------------------------------------ CONFIGURATION ------------------------------------------"

# Print the table headers for the configuration section with proper alignment
printf "%-25s | %-20s |  %-60s \n" "SSID" "MAC Filter" "MAC List"
echo "----------------------------------------------------------------------------------------------------"

# Fetch all wifi-iface configurations in one go to avoid calling `uci` multiple times
wifi_ifaces=$(uci show wireless | grep "wifi-iface")

# Loop through each wifi-iface configuration to fetch SSID, MAC filter, and MAC list
echo "$wifi_ifaces" | while read line; do
    iface=$(echo $line | cut -d'=' -f1)
    ssid=$(uci get $iface.ssid 2>/dev/null)
    macfilter=$(uci get $iface.macfilter 2>/dev/null)
    maclist=$(uci get $iface.maclist 2>/dev/null)

    # Proceed only if all fields are present and not previously processed
    if [ -n "$ssid" ] && [ -n "$macfilter" ] && [ -n "$maclist" ] && ! echo "$processed_ssids" | grep -q "$ssid"; then
        processed_ssids="$processed_ssids $ssid"
        
        # Print SSID, MAC Filter and MAC List in tabular format with alignment
        printf "%-25s | %-20s |  %-60s \n" "$ssid" "$macfilter" "$(echo $maclist)"
    fi
done

# Print the heading for the applied section
echo "------------------------------------------- APPLIED -----------------------------------------------"

# Print the table headers for the applied section with proper alignment
printf "%-25s | %-20s |  %-60s \n" "SSID" "MAC Filter" "MAC List"
echo "----------------------------------------------------------------------------------------------------"

device_model=$(cat /etc/model 2>/dev/null || echo "unknown")

# Check if device is QN-I-210*
if [[ $device_model == *QN-I-210* ]]; then
    # Logic for QN-I-210* models
    iw dev | grep -B 4 "ssid" | while read line; do
        if echo "$line" | grep -q "Interface"; then
            iface=$(echo "$line" | awk '{print $2}')
        fi
        if echo "$line" | grep -q "ssid"; then
            ssid=$(echo $line | awk '{print $2}')
            if [ -n "$iface" ] && [ -n "$ssid" ] && ! echo "$processed_ssids" | grep -q "$ssid"; then
                processed_ssids="$processed_ssids $ssid"
                
                # Combine hostapd output fetches into one block
                accept_output=$(hostapd_cli -i "$iface" -p /var/run/hostapd accept_acl SHOW)
                deny_output=$(hostapd_cli -i "$iface" -p /var/run/hostapd deny_acl SHOW)

                if [ -n "$accept_output" ]; then
                    # Print accept MAC Filter and List in tabular format with alignment
                    printf "%-25s | %-20s |  %-60s \n" "$ssid" "accept" "$(echo "$accept_output" | sed 's/VLAN_ID=0//g' | sed '/^$/d' | tr '\n' ',')"
                fi
                if [ -n "$deny_output" ]; then
                    # Print deny MAC Filter and List in tabular format with alignment
                    printf "%-25s | %-20s |  %-60s \n" "$ssid" "deny" "$(echo "$deny_output" | sed 's/VLAN_ID=0//g' | sed '/^$/d' | tr '\n' ',')"
                fi
            fi
        fi
    done
else
    # Logic for other models (doesn't use iw dev)
    wifi_ifaces=$(uci show wireless | grep "wifi-iface")

    echo "$wifi_ifaces" | while read line; do
        iface=$(echo $line | cut -d'=' -f1)
        ssid=$(uci get $iface.ssid 2>/dev/null)
        ifname=$(uci get $iface.ifname 2>/dev/null)
        device=$(uci get $iface.device 2>/dev/null)

        if [ -n "$ssid" ] && [ -n "$ifname" ] && [ -n "$device" ] && ! echo "$processed_ssids" | grep -q "$ssid"; then
            processed_ssids="$processed_ssids $ssid"
            
            hostapd_path="/var/run/hostapd-$device/"

            accept_output=$(hostapd_cli -i "$ifname" -p "$hostapd_path" accept_acl SHOW)
            deny_output=$(hostapd_cli -i "$ifname" -p "$hostapd_path" deny_acl SHOW)

            if [ -n "$accept_output" ]; then
                # Print accept MAC Filter and List in tabular format with alignment
                printf "%-25s | %-20s |  %-60s \n" "$ssid" "accept" "$(echo "$accept_output" | sed 's/VLAN_ID=0//g' | sed '/^$/d' | tr '\n' ',')"
            fi
            if [ -n "$deny_output" ]; then
                # Print deny MAC Filter and List in tabular format with alignment
                printf "%-25s | %-20s |  %-60s \n" "$ssid" "deny" "$(echo "$deny_output" | sed 's/VLAN_ID=0//g' | sed '/^$/d' | tr '\n' ',')"
            fi
        fi
    done
fi
echo "----------------------------------------------------------------------------------------------------"


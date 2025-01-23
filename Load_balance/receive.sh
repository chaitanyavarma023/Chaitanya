#!/bin/sh

# Define your MQTT connection details
BROKER_HOST="rudder.dev.qntmnet.com"
USER="quantum"
PASSWORD="C0r0u0ntum"
TOPIC="ld"

# Retrieve the own AP MAC address
own_ap_mac=$( /bin/sh /usr/lib/lua/luci/wan_find/find_mac.sh | /usr/bin/cut -d ":" -f 4,5,6 )
echo "[INFO] Own AP MAC address: $own_ap_mac"

# Start MQTT subscription and process the incoming messages
mosquitto_sub -h "$BROKER_HOST" -u "$USER" -P "$PASSWORD" -t "$TOPIC" | while read -r line
do
    # Check if the line contains "AP MAC Address"
    if echo "$line" | grep -q "AP MAC Address"; then
        ap_mac=$(echo "$line" | sed -E 's/.*AP MAC Address: ([0-9a-fA-F:]+).*/\1/')

        # Log the detected AP MAC address
        echo "[INFO] Found AP MAC address: $ap_mac"

        # If the AP MAC is not the same as own AP MAC, start collecting content for that AP
        if [ "$ap_mac" != "$own_ap_mac" ]; then
            # Check if file for this AP MAC exists
            output_file="${ap_mac}.txt"

            if [ -f "$output_file" ]; then
                # File exists, appending content
                echo "[INFO] File for $ap_mac already exists, appending content."
            else
                # File does not exist, creating new
                echo "[INFO] Creating new file for $ap_mac."
                touch "$output_file"
            fi

            # Process and save the content collected so far if there's any
            if [ -n "$content" ]; then
                echo "$content" >> "$output_file"
                echo "[INFO] Content saved to $output_file"
            fi

            # Start collecting content for this AP MAC
            collecting=true
            content=""
        else
            collecting=false
        fi
    elif [ "$collecting" = true ] && [ -n "$line" ]; then
        # Collect content from clients (skip empty lines)
        content="$content$line"$'\n'
    fi
done

#!/bin/bash

# Define the AP MAC address and weak_signal_clients file location
AP_MAC_ADDRESS_FILE="00:22:0F.txt"
WEAK_SIGNAL_FILE="/tmp/weak_signal_clients.txt"
SCANLIST_FILE="scanlist"

# Run wids_tool to generate scanlist
wids_tool -i mon01 > $SCANLIST_FILE
wids_tool -i mon11 >> $SCANLIST_FILE

# Read the number of clients in the weak_signal_clients.txt
num_clients_weak_signal=$(wc -l < "$WEAK_SIGNAL_FILE")

# Read the number of clients in the AP MAC address file
num_clients_ap_mac=$(wc -l < "$AP_MAC_ADDRESS_FILE")

# Compare the number of clients in both files
if [ $num_clients_ap_mac -le $num_clients_weak_signal ]; then
    echo "No clients greater than weak_signal_clients.txt"

    # Check RSSI values from the AP MAC address file and compare them with the scanlist
    while IFS=" " read -r client_mac interface rssi timestamp; do
        # Search for the client_mac in the scanlist file
        scanlist_rssi=$(grep -i "$client_mac" "$SCANLIST_FILE" | awk '{print $3}')

        if [ -n "$scanlist_rssi" ]; then
            # Compare the RSSI values
            if [ "$rssi" -gt "$scanlist_rssi" ]; then
                echo "Client $client_mac has a weaker RSSI in scanlist: $scanlist_rssi (AP file RSSI: $rssi)"
            fi
        fi
    done < "$AP_MAC_ADDRESS_FILE"
fi

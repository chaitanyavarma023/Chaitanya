#!/bin/sh

# Path where the files are stored
path="/tmp/connected_client/*"

# Function to process each client file
process_client() {
    # Read the client MAC, interface, and signal strength from the JSON file
    client_mac=$(grep -o '"Client_MAC": "[^"]*' "$1" | sed 's/"Client_MAC": "//')
    interface=$(grep -o '"interface": "[^"]*' "$1" | sed 's/"interface": "//')
    signal_strength=$(grep -o '"Signalstrength": "[^"]*' "$1" | sed 's/"Signalstrength": "//')

    # Check if signal strength is available
    if [ -z "$client_mac" ] || [ -z "$interface" ] || [ -z "$signal_strength" ]; then
        return
    fi

    # Check if signal strength is a valid number
    if ! echo "$signal_strength" | grep -q '^[0-9]\{1,3\}$'; then
        return
    fi

    # Calculate signal strength adjusted by subtracting 90
    adjusted_signal=$((signal_strength - 90))

    # Check the adjusted signal strength and take action
    if [ "$adjusted_signal" -le -50 ]; then
        # Signal strength is good (adjusted signal >= -50 dBm)
        echo "Client MAC $client_mac has a good signal strength: $signal_strength dBm"
    elif [ "$adjusted_signal" -le -70 ]; then
        # Signal strength is between -50 dBm and -70 dBm
        echo "Signal strength for Client MAC $client_mac ($signal_strength dBm) is weak. Kicking client..."
        iwpriv "$interface" kickmac "$client_mac"
    else
        # Signal strength is very poor (< -70 dBm)
        echo "Client MAC $client_mac has very poor signal strength: $signal_strength dBm"
    fi
}

# Main loop to process the files every 10 seconds
while true; do
    for file in $path; do
        if [ -f "$file" ]; then
            process_client "$file"
        fi
    done
    sleep 10
done

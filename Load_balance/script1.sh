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
        echo "Client MAC $client_mac has a good signal strength: $adjusted_signal dBm"
    elif [ "$adjusted_signal" -le -70 ]; then
        # Signal strength is between -50 dBm and -70 dBm
        echo "Signal strength for Client MAC $client_mac ($adjusted_signal dBm) is weak. Kicking client..."
        iwpriv "$interface" kickmac "$client_mac"
    else
        # Signal strength is very poor (< -70 dBm)
        echo "Client MAC $client_mac has very poor signal strength: $adjusted_signal dBm"
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


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


#!/bin/sh

# Path where the files are stored
path="/tmp/connected_client/*"
# File to store clients that have weak signal for 90 seconds
output_file="/tmp/weak_signal_clients.txt"

# Duration to track the signal strength in seconds
track_duration=90
# Signal strength range to monitor (-60 to -80 dBm)
signal_range_start=-40
signal_range_end=-10

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
    
    # Check if the adjusted signal is in the range of -60 to -80
    if [ "$adjusted_signal" -ge "$signal_range_start" ] && [ "$adjusted_signal" -le "$signal_range_end" ]; then
        # Log to a temporary file to track the signal strength
        echo "$client_mac $interface $adjusted_signal $(date +'%Y-%m-%d %H:%M:%S')" >> "/tmp/temp_client_signals_$client_mac.txt"
        
        # Count how many times the signal has been in the range over the track duration
        count=$(grep -c "$client_mac" "/tmp/temp_client_signals_$client_mac.txt")
        
        # If the signal is in range for 90 seconds (approximately 90 checks per 1-second interval)
        if [ "$count" -ge "$track_duration" ]; then
            # Check if the client is already in the output file
            if grep -q "$client_mac" "$output_file"; then
                # If client exists, update the entry by removing the old one and appending the new one
                sed -i "/$client_mac/d" "$output_file"
            fi
            # Store the client details in the output file
            echo "$client_mac $interface $adjusted_signal $(date +'%Y-%m-%d %H:%M:%S')" >> "$output_file"
            # Clean up temporary file for the client
            rm "/tmp/temp_client_signals_$client_mac.txt"
        fi
    else
        # Remove any previous records if the signal goes outside the range
        rm -f "/tmp/temp_client_signals_$client_mac.txt"
    fi
}

# Main loop to process the files every 1 second
while true; do
    for file in $path; do
        if [ -f "$file" ]; then
            process_client "$file"
        fi
    done
    sleep 1  # Check every second
done

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@2

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


#!/bin/sh

# Path where the files are stored
path="/tmp/connected_client/*"
# File to store clients that have weak signal for 90 seconds
output_file="/tmp/weak_signal_clients.txt"

# Duration to track the signal strength in seconds
track_duration=90
# Signal strength range to monitor (-60 to -80 dBm)
signal_range_start=-40
signal_range_end=-10

# Fetch AP MAC address
ownmac=$( /bin/sh /usr/lib/lua/luci/wan_find/find_mac.sh | /usr/bin/cut -d ":" -f 4,5,6 )

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
    
    # Check if the adjusted signal is in the range of -60 to -80
    if [ "$adjusted_signal" -ge "$signal_range_start" ] && [ "$adjusted_signal" -le "$signal_range_end" ]; then
        # Log to a temporary file to track the signal strength
        echo "$client_mac $interface $adjusted_signal $(date +'%Y-%m-%d %H:%M:%S')" >> "/tmp/temp_client_signals_$client_mac.txt"
        
        # Count how many times the signal has been in the range over the track duration
        count=$(grep -c "$client_mac" "/tmp/temp_client_signals_$client_mac.txt")
        
        # If the signal is in range for 90 seconds (approximately 90 checks per 1-second interval)
        if [ "$count" -ge "$track_duration" ]; then
            # Check if the client is already in the output file
            if grep -q "$client_mac" "$output_file"; then
                # If client exists, update the entry by removing the old one and appending the new one
                sed -i "/$client_mac/d" "$output_file"
            fi
            # Store the client details in the output file
            echo "$client_mac $interface $adjusted_signal $(date +'%Y-%m-%d %H:%M:%S')" >> "$output_file"
            # Clean up temporary file for the client
            rm "/tmp/temp_client_signals_$client_mac.txt"
        fi
    else
        # Remove any previous records if the signal goes outside the range
        rm -f "/tmp/temp_client_signals_$client_mac.txt"
    fi
}

# Function to publish the output file to the MQTT broker
publish_mqtt() {
    mosquitto_pub -h rudder.dev.qntmnet.com -u quantum -P C0r0u0ntum -t ld -f "$output_file"
}

# Check if the output file exists, if not, create it
if [ ! -f "$output_file" ]; then
    touch "$output_file"
fi

# Store the initial modification time of the output file
last_mod_time=$(stat -c %Y "$output_file")

ownmac_written=0  # Flag to track whether the AP MAC address has been written

# Before entering the loop, ensure the AP MAC address is written once in the output file
echo "AP MAC Address: $ownmac" > "$output_file"
ownmac_written=1

# Main loop to process the files every 1 second and monitor file changes
while true; do
    # Check for file changes by comparing the last modification time
    current_mod_time=$(stat -c %Y "$output_file")
    
    # If the modification time has changed, publish to MQTT
    if [ "$current_mod_time" -ne "$last_mod_time" ]; then
        # Publish the updated file to the MQTT broker
        publish_mqtt
        # Update the last modification time to avoid multiple publishings
        last_mod_time="$current_mod_time"
    fi

    # Process each connected client file
    for file in $path; do
        if [ -f "$file" ]; then
            process_client "$file"
        fi
    done

    sleep 1  # Check every second
done



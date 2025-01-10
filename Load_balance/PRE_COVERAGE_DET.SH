#!/bin/sh

# Function to check and store connected client details with required signal strength range
PRE_COVERAGE_DET() {
    # Output file to store data
    output_file="pre_coverage_db"
    
    # Create or clear the file before writing new data
    > "$output_file"
    echo "Started the PRE_COVERAGE_DET script."

    # Loop to continuously fetch and process data every 10 seconds
    while true; do
        echo "Fetching client data..."
        
        # Loop through all connected clients in /tmp/connected_client/*
        for client_file in /tmp/connected_client/*; do
            # Check if it's a regular file
            if [ -f "$client_file" ]; then
                echo "Processing file: $client_file"
                
                # Print the content of the client file for debugging
                echo "Content of $client_file:"
                cat "$client_file"
                
                # Extract the MAC, interface, signal strength, and SSID using awk
                mac=$(awk -F'"Client_MAC":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')
                interface=$(awk -F'"interface":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')
                signal_strength=$(awk -F'"Signalstrength":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')
                ssid=$(awk -F'"ssid":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')

                # Check if signal_strength is available
                if [ -n "$signal_strength" ]; then
                    # Calculate signal_dbm
                    signal_dbm=$((signal_strength - 90))

                    # Check if the signal strength is within the required range (-60 to -80 dBm)
                    if [ "$signal_dbm" -ge -80 ] && [ "$signal_dbm" -le -60 ]; then
                        echo "Valid signal for MAC: $mac, Signal Strength: $signal_strength dBm."

                        # Check if the MAC address already exists in the output file
                        existing_entry=$(grep -i "MAC: $mac" "$output_file")

                        if [ -n "$existing_entry" ]; then
                            # If the MAC exists, update the entry with the latest values
                            echo "MAC $mac already exists. Updating entry."
                            sed -i "/MAC: $mac/c\MAC: $mac, Interface: $interface, Signal Strength: $signal_strength dBm, SSID: $ssid" "$output_file"
                        else
                            # If MAC does not exist, append the new entry to the file
                            echo "MAC $mac not found. Adding new entry."
                            echo "MAC: $mac, Interface: $interface, Signal Strength: $signal_strength dBm, SSID: $ssid" >> "$output_file"
                        fi
                    else
                        echo "MAC: $mac signal strength ($signal_strength dBm) out of required range (-80 to -60 dBm). Skipping."
                    fi
                else
                    echo "Signal strength not found for MAC: $mac. Skipping."
                fi
            fi
        done

        echo "Waiting 10 seconds before fetching data again..."
        # Sleep for 10 seconds before fetching data again
        sleep 10
    done
}

# Start the script
echo "Script execution started."
PRE_COVERAGE_DET
echo "Script execution completed."

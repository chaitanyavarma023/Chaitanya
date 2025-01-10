#!/bin/sh

# Lock file path
LOCK_FILE="/tmp/merge2_script.lock"

# Output files
PRE_COVERAGE_FILE="pre_coverage_db"
FAILED_CLIENTS_FILE="failed_clients"

# Function to handle signal interruption gracefully (Ctrl+C)
trap 'echo "Script interrupted. Exiting..."; remove_lock_file; exit 1' SIGINT

# Function to create a lock file to prevent multiple script instances
create_lock_file() {
    if [ -e "$LOCK_FILE" ]; then
        echo "Script is already running. Exiting."
        exit 1
    fi
    touch "$LOCK_FILE"
}

# Function to remove the lock file after script completion
remove_lock_file() {
    if [ -e "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
    fi
}

# Function to check and store connected client details with required signal strength range
PRE_COVERAGE_DET() {
    echo "Started the PRE_COVERAGE_DET script."
    
    # Create or clear output file
    > "$PRE_COVERAGE_FILE"
    
    while true; do
        echo "Fetching client data..."
        
        # Loop through all connected clients in /tmp/connected_client/*
        for client_file in /tmp/connected_client/*; do
            if [ -f "$client_file" ]; then
                echo "Processing file: $client_file"
                
                # Extract the MAC, interface, signal strength, and SSID using awk
                mac=$(awk -F'"Clien0t_MAC":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')
                interface=$(awk -F'"interface":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')
                signal_strength=$(awk -F'"Signalstrength":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')
                ssid=$(awk -F'"ssid":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')

                if [ -n "$signal_strength" ]; then
                    signal_dbm=$((signal_strength - 90))

                    # Check if the signal strength is within the required range (-80 to -60 dBm)
                    if [ "$signal_dbm" -ge -80 ] && [ "$signal_dbm" -le -15 ]; then
                        echo "Valid signal for MAC: $mac, Signal Strength: $signal_strength dBm."

                        # Check if the MAC address already exists in the output file
                        existing_entry=$(grep -i "MAC: $mac" "$PRE_COVERAGE_FILE")

                        if [ -n "$existing_entry" ]; then
                            # If the MAC exists, update the entry with the latest values
                            sed -i "/MAC: $mac/c\MAC: $mac, Interface: $interface, Signal Strength: $signal_strength dBm, SSID: $ssid" "$PRE_COVERAGE_FILE"
                        else
                            # If MAC does not exist, append the new entry to the file
                            echo "MAC: $mac, Interface: $interface, Signal Strength: $signal_strength dBm, SSID: $ssid" >> "$PRE_COVERAGE_FILE"
                        fi
                    else
                        echo "MAC: $mac signal strength ($signal_strength dBm) out of range."
                    fi
                else
                    echo "Signal strength not found for MAC: $mac. Skipping."
                fi
            fi
        done

        echo "Waiting 10 seconds before fetching data again..."
        sleep 10
    done
}

# Function to monitor failed clients based on signal strength
monitor_failed_clients() {
    echo "Started the Failed Client Monitoring script."
    
    # Create or clear the failed clients file
    > "$FAILED_CLIENTS_FILE"

    total_clients=$(ls /tmp/connected_client | wc -l)
    echo "Total clients from connected_clients directory: $total_clients"

    if [ "$total_clients" -eq 0 ]; then
        echo "No clients connected. Exiting script."
        return 1
    fi

    # 25% of total clients is the threshold for failed clients
    failed_clients_threshold=$((total_clients * 25 / 100))
    echo "Failed clients threshold (25%): $failed_clients_threshold"

    failed_clients_count=0

    # Loop through each client in pre_coverage_db and monitor their signal for 90 seconds
    while IFS=',' read -r mac interface signal_strength ssid; do
        valid_signal_count=0
        end_time=$((SECONDS + 90))

        while [ $(($SECONDS)) -lt $end_time ]; do
            current_signal_strength=$(echo "$signal_strength" | sed 's/[^0-9-]*//g')
            signal_dbm=$((current_signal_strength - 90))

            if [ "$signal_dbm" -ge -80 ] && [ "$signal_dbm" -le -15 ]; then
                valid_signal_count=$((valid_signal_count + 1))
            fi

            sleep 1
        done

        if [ "$valid_signal_count" -eq 90 ]; then
            echo "Failed client: MAC: $mac, Interface: $interface, Signal Strength: $signal_strength, SSID: $ssid" >> "$FAILED_CLIENTS_FILE"
            failed_clients_count=$((failed_clients_count + 1))
        fi

    done < "$PRE_COVERAGE_FILE"

    # Check if the failed clients exceed the threshold
    if [ "$failed_clients_count" -ge "$failed_clients_threshold" ]; then
        echo "Failed clients threshold exceeded. Clients stored in $FAILED_CLIENTS_FILE."
    else
        echo "Failed clients count ($failed_clients_count) is below the threshold."
    fi
}

# Main execution
main() {
    # Create lock file to prevent multiple instances of the script
    create_lock_file

    echo "Script execution started."
    
    # Run the PRE_COVERAGE_DET and monitor_failed_clients functions
    PRE_COVERAGE_DET &
    monitor_failed_clients
    
    wait
    echo "Script execution completed."
    
    # Remove lock file after script completion
    remove_lock_file
}

# Run the main function
main


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



#!/bin/sh

# Lock file path
LOCK_FILE="/tmp/merge2_script.lock"

# Output files
PRE_COVERAGE_FILE="pre_coverage_db"
FAILED_CLIENTS_FILE="failed_clients"

# Function to handle signal interruption gracefully (Ctrl+C)
trap 'echo "Script interrupted. Exiting..."; remove_lock_file; exit 1' SIGINT

# Function to create a lock file to prevent multiple script instances
create_lock_file() {
    if [ -e "$LOCK_FILE" ]; then
        echo "Script is already running. Exiting."
        exit 1
    fi
    touch "$LOCK_FILE"
}

# Function to remove the lock file after script completion
remove_lock_file() {
    if [ -e "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
    fi
}

# Function to check and store connected client details with required signal strength range
PRE_COVERAGE_DET() {
    echo "Started the PRE_COVERAGE_DET script."
    
    # Create or clear output file
    > "$PRE_COVERAGE_FILE"
    
    while true; do
        echo "Fetching client data..."
        
        # Loop through all connected clients in /tmp/connected_client/*
        for client_file in /tmp/connected_client/*; do
            if [ -f "$client_file" ]; then
                echo "Processing file: $client_file"
                
                # Extract the MAC, interface, signal strength, and SSID using awk
                mac=$(awk -F'"Client_MAC":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')
                interface=$(awk -F'"interface":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')
                signal_strength=$(awk -F'"Signalstrength":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')
                ssid=$(awk -F'"ssid":' '{print $2}' "$client_file" | awk -F'"' '{print $2}')

                if [ -n "$signal_strength" ]; then
                    signal_dbm=$((signal_strength - 90))

                    # Check if the signal strength is within the required range (-80 to -60 dBm)
                    if [ "$signal_dbm" -ge -80 ] && [ "$signal_dbm" -le -15 ]; then
                        echo "Valid signal for MAC: $mac, Signal Strength: $signal_strength dBm."

                        # Check if the MAC address already exists in the output file
                        existing_entry=$(grep -i "MAC: $mac" "$PRE_COVERAGE_FILE")

                        if [ -n "$existing_entry" ]; then
                            # If the MAC exists, update the entry with the latest values
                            sed -i "/MAC: $mac/c\MAC: $mac, Interface: $interface, Signal Strength: $signal_strength dBm, SSID: $ssid" "$PRE_COVERAGE_FILE"
                        else
                            # If MAC does not exist, append the new entry to the file
                            echo "MAC: $mac, Interface: $interface, Signal Strength: $signal_strength dBm, SSID: $ssid" >> "$PRE_COVERAGE_FILE"
                        fi
                    else
                        echo "MAC: $mac signal strength ($signal_strength dBm) out of range."
                    fi
                else
                    echo "Signal strength not found for MAC: $mac. Skipping."
                fi
            fi
        done

        echo "Waiting 10 seconds before fetching data again..."
        sleep 10
    done
}

# Function to monitor failed clients based on signal strength
# Function to monitor failed clients based on signal strength
monitor_failed_clients() {
    echo "Started the Failed Client Monitoring script."
    
    # Create or clear the failed clients file
    > "$FAILED_CLIENTS_FILE"

    total_clients=$(ls /tmp/connected_client | wc -l)
    echo "Total clients from connected_clients directory: $total_clients"

    if [ "$total_clients" -eq 0 ]; then
        echo "No clients connected. Exiting script."
        return 1
    fi

    # 25% of total clients is the threshold for failed clients
    failed_clients_threshold=$((total_clients * 25 / 100))
    echo "Failed clients threshold (25%): $failed_clients_threshold"

    # Count the number of clients in the PRE_COVERAGE_FILE
    pre_coverage_clients_count=$(wc -l < "$PRE_COVERAGE_FILE")
    echo "Clients in PRE_COVERAGE_FILE: $pre_coverage_clients_count"

    # Compare the number of clients in PRE_COVERAGE_FILE with the threshold
    if [ "$pre_coverage_clients_count" -ge "$failed_clients_threshold" ]; then
        echo "PRE_COVERAGE_FILE has reached or exceeded the 25% threshold. Storing failed clients."

        failed_clients_count=0

        # Loop through each client in pre_coverage_db and monitor their signal for 90 seconds
        while IFS=',' read -r mac interface signal_strength ssid; do
            valid_signal_count=0
            end_time=$((SECONDS + 90))

            while [ $(($SECONDS)) -lt $end_time ]; do
                current_signal_strength=$(echo "$signal_strength" | sed 's/[^0-9-]*//g')
                signal_dbm=$((current_signal_strength - 90))

                if [ "$signal_dbm" -ge -80 ] && [ "$signal_dbm" -le -15 ]; then
                    valid_signal_count=$((valid_signal_count + 1))
                fi

                sleep 1
            done

            # If the client has a valid signal for the entire 90 seconds, mark as failed
            if [ "$valid_signal_count" -eq 90 ]; then
                echo "Failed client: MAC: $mac, Interface: $interface, Signal Strength: $signal_strength, SSID: $ssid" >> "$FAILED_CLIENTS_FILE"
                failed_clients_count=$((failed_clients_count + 1))
            fi

        done < "$PRE_COVERAGE_FILE"

        # Check if the failed clients exceed the threshold
        if [ "$failed_clients_count" -ge "$failed_clients_threshold" ]; then
            echo "Failed clients threshold exceeded. Clients stored in $FAILED_CLIENTS_FILE."
        else
            echo "Failed clients count ($failed_clients_count) is below the threshold."
        fi
    else
        echo "PRE_COVERAGE_FILE does not meet the 25% threshold. Skipping failed client storage."
    fi
}


# Main execution
main() {
    # Create lock file to prevent multiple instances of the script
    create_lock_file

    echo "Script execution started."
    
    # Run the PRE_COVERAGE_DET and monitor_failed_clients functions
    PRE_COVERAGE_DET &
    monitor_failed_clients
    
    wait
    echo "Script execution completed."
    
    # Remove lock file after script completion
    remove_lock_file
}

# Run the main function
main
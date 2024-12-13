#!/bin/sh

###############################################################################################
# JSON Data - '{"wlan": "WLAN1", "wmm": "0/1", "Background": {"aifs": "7", "cwmin": "4", "cwmax": "10", "txop": "0", "acm": "0"}, "Besteffort": {"aifs": "3", "cwmin": "4", "cwmax": "10", "txop": "0", "acm": "0"}, "Video": {"aifs": "2", "cwmin": "3", "cwmax": "4", "txop": "94", "acm": "0"}, "Voice": {"aifs": "2", "cwmin": "2", "cwmax": "3", "txop": "47", "acm": "0"},"RevisionNo":365,"DeviceRevisionNo":""}'
###############################################################################################

model=$(cat /etc/model)

# Define the bandwidth threshold (in kbps)
max_bandwidth=1000  # Maximum allowable bandwidth
threshold=800  # Threshold after which new calls will be blocked

# Function to check bandwidth usage

check_bandwidth_usage() {
    interface="wlan0"
    
    # Get current bandwidth stats for the interface
    bandwidth=$(vnstat --oneline -i $interface | awk -F ';' '{print $11}')
    bandwidth_kbps=$(echo "$bandwidth" | awk '{print $1}')
    
    echo "Current Bandwidth: $bandwidth_kbps kbps"
    
    if [ "$bandwidth_kbps" -gt "$threshold" ]; then
        echo "Bandwidth limit exceeded. Blocking new calls."
        return 1
    else
        echo "Sufficient bandwidth. Allowing new call."
        return 0
    fi
}



# Logic to process new call request
process_call_request() {
    if check_bandwidth_usage; then
        # Allow the call and set WMM configuration
        configure_wmm "$1"
    else
        # Block the call due to insufficient bandwidth
        echo "New call blocked due to low bandwidth."
        exit 1
    fi
}


}

# Entry point of the script
input_data=$1

# Process call request with bandwidth check and WMM configuration
process_call_request "$input_data"

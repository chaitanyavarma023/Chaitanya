#!/bin/sh

max_bandwidth=1000  # Maximum allowable bandwidth
threshold=800  # Threshold after which new calls will be blocked


    interface="wlan0"
    
    # Get current bandwidth stats for the interface
    bandwidth=$(vnstat --oneline -i $interface | awk -F ';' '{print $11}')
    bandwidth_kbps=$(echo "$bandwidth" | awk '{print $1}')
    
    echo "Current Bandwidth: $bandwidth_kbps kbps"
    
    if [ "$bandwidth_kbps" -gt "$threshold" ]; then
        echo "Bandwidth limit exceeded. Blocking new calls."
        
    else
        echo "Sufficient bandwidth. Allowing new call."
         
    fi

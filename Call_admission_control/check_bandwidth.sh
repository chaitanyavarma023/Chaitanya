check_bandwidth_usage() {
    interface="wlan0"
    
    # Read current RX and TX bytes
    rx_bytes_before=$(cat /sys/class/net/$interface/statistics/rx_bytes)
    tx_bytes_before=$(cat /sys/class/net/$interface/statistics/tx_bytes)
    
    # Wait for 1 second
    sleep 1
    
    # Read RX and TX bytes again after 1 second
    rx_bytes_after=$(cat /sys/class/net/$interface/statistics/rx_bytes)
    tx_bytes_after=$(cat /sys/class/net/$interface/statistics/tx_bytes)
    
    # Calculate bandwidth usage in bytes per second
    rx_bandwidth=$((rx_bytes_after - rx_bytes_before))
    tx_bandwidth=$((tx_bytes_after - tx_bytes_before))
    
    # Convert to kbps
    rx_kbps=$((rx_bandwidth * 8 / 1000))
    tx_kbps=$((tx_bandwidth * 8 / 1000))
    
    total_bandwidth=$((rx_kbps + tx_kbps))
    echo "Current Bandwidth: $total_bandwidth kbps"
    
    if [ "$total_bandwidth" -gt "$threshold" ]; then
        echo "Bandwidth limit exceeded. Blocking new calls."
        return 1
    else
        echo "Sufficient bandwidth. Allowing new call."
        return 0
    fi
}

##################################################################################################


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


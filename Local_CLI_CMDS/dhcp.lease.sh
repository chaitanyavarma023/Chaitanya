#!/bin/sh
#|===============================================================================
#|      FILE            :  DHCP Pool config
#|      PATH            :  /usr/CMD/
#|      USAGE           :  Displays DHCP Pool configuration
#|      ARGUMENTS       :  No arguments required
#|      RETURN VALUE    :  NULL
#|===============================================================================

# Convert Unix timestamp to a human-readable format
convert_timestamp() {
    seconds=$1
    if [ $seconds -ge 86400 ]; then
        # 86400 seconds in a day
        days=$((seconds / 86400))
        echo "${days} day(s)"
    elif [ $seconds -ge 3600 ]; then
        # 3600 seconds in an hour
        hours=$((seconds / 3600))
        echo "${hours} hour(s)"
    elif [ $seconds -ge 60 ]; then
        # 60 seconds in a minute
        minutes=$((seconds / 60))
        echo "${minutes} minute(s)"
    else
        echo "${seconds} second(s)"
    fi
}

# Print the table header and separators
echo "--------------------------------------------------------------------------------------------------------------------------------------"
echo "| Lease Expiry            | MAC Address          | IP Address           | Client ID            | Hostname                            |"
echo "--------------------------------------------------------------------------------------------------------------------------------------"

# Read the DHCP lease file and format the output
while read -r line; do
    expiry=$(echo $line | awk '{print $1}')
    mac=$(echo $line | awk '{print $2}')
    ip=$(echo $line | awk '{print $3}')
    client_id=$(echo $line | awk '{print $5}')
    hostname=$(echo $line | awk '{print $4}')
    # Convert the lease expiry timestamp to a human-readable format
    expiry_formatted=$(convert_timestamp "$expiry")

    # Format and display each line of the DHCP lease information
    printf "| %-23s | %-20s | %-20s | %-20s | %-20s \n" "$expiry_formatted" "$mac" "$ip" "$client_id" "$hostname" 
done < /tmp/dhcp.leases

# Print the closing separator
echo "--------------------------------------------------------------------------------------------------------------------------------------"


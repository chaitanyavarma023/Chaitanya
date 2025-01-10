#!/bin/sh

# Check if the syslog value of wifi0 or wifi1 is '1'
syslog_wifi0=$(uci show wireless | grep "wireless.wifi0.syslog='1'")
syslog_wifi1=$(uci show wireless | grep "wireless.wifi1.syslog='1'")

# If either condition is true, proceed to check the syslog-ng.conf file
if [ -n "$syslog_wifi0" ] || [ -n "$syslog_wifi1" ]; then
    # Path to syslog-ng.conf
    syslog_conf="/etc/syslog-ng.conf"

    # Check if the file exists
    if [ -f "$syslog_conf" ]; then
        # Extract the line containing both IP and port
        config_line=$(grep -o 'udp("[^"]*" port([0-9]*))' "$syslog_conf")

        # Extract the server IP using sed (handling the part inside udp("..."))
        server_ip=$(echo "$config_line" | sed -n 's/.*udp("\([0-9\.]*\)".*/\1/p')
echo ""
        # Extract the port using sed (handling the part inside port(...))
        port=$(echo "$config_line" | sed -n 's/.*port(\([0-9]*\)).*/\1/p')
	echo "|-----------------------------|"
        # Print the extracted details in a table format
        printf "|%-15s | %-5s\n" "Server IP" "Port"
        printf "|%-15s | %-5s\n" "---------------" "-----"
        printf "|%-15s | %-5s\n" "$server_ip" "$port"
    else
        echo "Error: $syslog_conf not found."
        exit 1
    fi
else
    echo "Neither wifi0.syslog nor wifi1.syslog is set to '1'. No action taken."
    exit 0
fi
echo "|-----------------------------|" 
echo ""

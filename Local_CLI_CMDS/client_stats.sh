#!/bin/bash

# Prompt for MAC address
echo -n "Enter the MAC address of the client (e.g., 0c:7a:15:36:de:e5): "
read mac_address

# Validate MAC address format
if ! echo "$mac_address" | grep -Eq '^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$'; then
    echo -e "\nError: Invalid MAC address format."
    exit 1
fi

# Fetch stats using apstats
echo -e "\nFetching client stats for MAC address $mac_address...\n"
client_stats=$(apstats -s -m "$mac_address")

# Check if stats were found
if [[ -z "$client_stats" ]]; then
    echo "Error: No stats found for MAC address $mac_address."
    exit 1
fi

# Print the client stats header
#echo -e "\nClient Stats for MAC Address: $mac_address\n"
echo "------------------------------------------------------"

# Print the Node Level Stats
#echo -e "Node Level Stats"
echo "------------------------------------------------------"
echo "$client_stats" | grep -E "Node Level Stats|Tx Data Packets|Tx Data Bytes|Tx Success Data Packets|Tx Success Data Bytes" | \
awk -F: '{printf "%-30s%-20s\n", $1, $2}'

# Print Tx Data Packets per AC section and its subfields (Best Effort, Background, Video, Voice)
#echo -e "\nTx Data Packets per AC"
echo "------------------------------------------------------"
echo "$client_stats" | grep -E "Tx Data Packets per AC" -A 4 | grep -v "Tx Success Unicast Data Packets" | sed '/^$/d' | \
awk -F: '{printf "%-30s%-20s\n", $1, $2}'

# Print Rx Data Packets per AC section and its subfields (Best Effort, Background, Video, Voice)
#echo -e "\nRx Data Packets per AC"
echo "------------------------------------------------------"
echo "$client_stats" | grep -E "Rx Data Packets per AC" -A 4 | sed '/^$/d' | \
awk -F: '{printf "%-30s%-20s\n", $1, $2}'

# Print Tx Success Unicast Data Packets (only once)
#echo -e "\nTx Success Unicast Data Packets"
echo "------------------------------------------------------"
echo "$client_stats" | grep -m 1 "Tx Success Unicast Data Packets" | \
awk -F: '{printf "%-30s%-20s\n", $1, $2}'

echo "------------------------------------------------------"




@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



#!/bin/sh
#|===============================================================================
#|      FILE            :  Client Statistics
#|      PATH            :  /usr/CMD/
#|      USAGE           :  Displays client stats
#|      ARGUMENTS       :  No arguments required
#|      RETURN VALUE    :  NULL
#|===============================================================================

# Ask the user to input the MAC address on the same line
echo -ne "Enter the MAC address of the client (e.g., 0c:7a:15:36:de:e5):  "
read mac_address

# Validate the MAC address format using grep
if ! echo "$mac_address" | grep -Eq '^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$'; then
    echo -e "\nError: Invalid MAC address format."
    exit 1
fi

# Run the apstats command with the provided MAC address
     echo -e "\n|-----------------------------------------------------------|"
echo -e "|Fetching client stats for MAC address $mac_address... |"
client_stats=$(apstats -s -m "$mac_address")

# Check if the command was successful
if [[ -z "$client_stats" ]]; then
    echo "Error: No stats found for MAC address $mac_address."
    exit 1
fi

# Print the first 16 lines of the client stats output with | at the start and end, total width 60
echo "|-----------------------------------------------------------|"
echo "$client_stats" | head -n 16 | while IFS= read -r line; do
    # Calculate the number of spaces required between the start and end `|`
    # The total width is 60, subtract 2 for the start and end `|`
    total_length=60
    line_length=${#line}
    spaces=$((total_length - line_length - 2))  # Subtract 2 for the start and end pipe

    # Print the line with `|` at the start, followed by the line content, and then spaces, and finally `|` at the end
    printf "| %-*s%*s|\n" "$line_length" "$line" "$spaces" ""
done
echo "|-----------------------------------------------------------|"

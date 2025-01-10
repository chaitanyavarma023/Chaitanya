#!/bin/bash
###|=================================================================================================================================================================================================
###|SCRIPT_PATH                          :  /usr/CMD/getap_connectedclients_advstats
###|USAGE                                :  This provides detailed diagnostic information about the AP-Level Metrics.
###|SUPPORT                              :  Only work/tested for qsdk model aps ~[H-245.*|O-230.*|I-240.*|O-240.*|H-250.*|I-270.*|I-280.*|I-290.*|O-290.*|I-470.*|I-480.*|O-480.*|I-490.*|O-490.*]
###|ARGUMENTS                            :  getap_connectedclients_advstats
###|==================================================================================================================================================================================================
######################################################################################################################################################################################################

# Directory containing JSON files
input_directory="/tmp/connected_client"

# Check if input_directory exists and is not empty
if [ ! -d "$input_directory" ] || [ -z "$(ls -A $input_directory)" ]; then
    echo "----------------------------------------------------------"
    echo "NO CONNECTED CLIENT DETECTED"
    echo "----------------------------------------------------------"
    exit 1
fi

# Output file
output_file="/tmp/formatted_table.txt"

# Clear output file
> "$output_file"

# Counter for clients
client_number=1

# Process each JSON file in the directory
for file in "$input_directory"/*; do
    # Read the JSON content from the file
    while IFS= read -r line; do
        # Check if line is not empty
        if [ -n "$line" ]; then
            # Add a heading for the client
            echo "|---------------------------------------------------------------------------------------------|" >> "$output_file"
            echo "Connected_Client- $client_number :" >> "$output_file"
            echo "|---------------------------------------------------------------------------------------------|" >> "$output_file"
            echo "USECASE: Advance Connected-Clients Statistics" >> "$output_file"
            
            # Print the table header with lines
            echo "|-----------------------------|---------------------------------------------------------------|" >> "$output_file"
            echo "|             KEY             |                       VALUE                                   |" >> "$output_file"
	    echo "|             ---             |                       -----                                   |" >> "$output_file"	
            echo "|-----------------------------|---------------------------------------------------------------|" >> "$output_file"

            # Process the JSON object and format it into a table for all values
            echo "$line" | jq -r 'to_entries | map("\(.key)\t\(.value)") | .[]' | awk -F'\t' '
            {
                key = sprintf("|%-29s|", $1);
                value = sprintf("%-60s |", $2);

                # Print the key-value pair with a separator line after each row
                print key "  " value;
                print "|-----------------------------|---------------------------------------------------------------|";
            }' >> "$output_file"

            # Increment client number
            client_number=$((client_number + 1))
        fi
    done < "$file"
done

# Output the formatted table
cat "$output_file"



@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

#!/bin/sh
#|===============================================================================
#|      FILE            :  wclient
#|      PATH            :  /usr/CMD/
#|      USAGE           :  Lists the clients connected to the Wireless
#|      ARGUMENTS       :  0 arguments
#|                         used by admin login
#|                          e.g. :  /usr/CMD/wclient
#|      RETURN VALUE    :  NULL
#|===============================================================================

# List connected clients in a formatted table
/bin/echo "|-------|--------------------------------|-------------------|----------|----------------|-------------------------|-----|"
format="|%-7s|%-32s|%-19s|%-10s|%-16s|%-25s|%-5s|\n"
/usr/bin/printf "$format" "RADIO" "SSID" "MAC" "CONN-SINCE" "IP" "HOSTNAME" "RSSI"
/bin/echo "|-------|--------------------------------|-------------------|----------|----------------|-------------------------|-----|"

# Check if there are connected clients
if [ -n "$(/bin/ls -A /tmp/connected_client/)" ]; then
    # Process each client JSON file
    for a in `/bin/ls /tmp/connected_client/`; do
        b=`/bin/cat /tmp/connected_client/$a`
        radio=`/bin/echo $b | /usr/bin/jsonfilter -e @.radio | /usr/bin/tr -d '"'`
        ssid=`/bin/echo $b | /usr/bin/jsonfilter -e @.ssid | /usr/bin/tr -d '"'`
        Client_MAC=`/bin/echo $b | /usr/bin/jsonfilter -e @.Client_MAC | /usr/bin/tr -d '"'`
        ConnectedSince=`/bin/echo $b | /usr/bin/jsonfilter -e @.ConnectedSince | /usr/bin/tr -d '"'`
        ip=`/bin/echo $b | /usr/bin/jsonfilter -e @.ip | /usr/bin/tr -d '"'`
        host=`/bin/echo $b | /usr/bin/jsonfilter -e @.host | /usr/bin/tr -d '"'`
        signal=`/bin/echo $b | /usr/bin/jsonfilter -e @.Signalstrength | /usr/bin/tr -d '"'`
        format="|%-7s|%-32s|%-19s|%-10s|%-16s|%-25s|%-5s|\n"
        /usr/bin/printf "$format" "$radio" "$ssid" "$Client_MAC" "$ConnectedSince" "$ip" "$host" "$signal"
    done
else
    /bin/echo "No connected clients detected."
    exit 1
fi

/bin/echo "|-------|--------------------------------|-------------------|----------|----------------|-------------------------|-----|"

# Ask the user if they want more detailed information
echo "Do you want more detailed information about any client? (yes/no): "
read user_choice

if [ "$user_choice" = "yes" ]; then
    # Ask the user to enter the MAC address of the client
     echo "Please enter the MAC address of the client: "
     read input_mac
    # Check if MAC address exists in the /tmp/connected_client directory
    client_found=0
    for a in `/bin/ls /tmp/connected_client/`; do
        b=`/bin/cat /tmp/connected_client/$a`
        Client_MAC=`/bin/echo $b | /usr/bin/jsonfilter -e @.Client_MAC | /usr/bin/tr -d '"'`
        if [ "$Client_MAC" = "$input_mac" ]; then
            client_found=1
            break
        fi
    done

    if [ $client_found -eq 0 ]; then
        echo "No client found with the MAC address $input_mac."
        exit 1
    fi

    # Print detailed client information
    echo "Fetching detailed information for MAC address: $input_mac..."

    # Directory containing JSON files
    input_directory="/tmp/connected_client"

    # Output file for detailed info
    output_file="/tmp/formatted_table.txt"

    # Clear output file
    > "$output_file"

    # Counter for clients
    client_number=1

    # Process each JSON file in the directory and generate detailed information
    for file in "$input_directory"/*; do
        # Read the JSON content from the file
        while IFS= read -r line; do
            # Add a heading for the client
            echo "|---------------------------------------------------------------------------------------------|" >> "$output_file"
            echo "Connected_Client- $client_number :" >> "$output_file"
            echo "|---------------------------------------------------------------------------------------------|" >> "$output_file"
            echo "USECASE: Advanced Connected-Clients Statistics" >> "$output_file"
            
            # Print the table header with lines
            echo "|-----------------------------|---------------------------------------------------------------|" >> "$output_file"
            echo "|             KEY             |                       VALUE                                   |" >> "$output_file"
            echo "|             ---             |                       -----                                   |" >> "$output_file"    
            echo "|-----------------------------|---------------------------------------------------------------|" >> "$output_file"

            # Process the JSON object and format it into a table for all values
            echo "$line" | jq -r 'to_entries | map("\(.key)\t\(.value)") | .[]' | awk -F'\t' '
            {
                key = sprintf("|%-29s|", $1);
                value = sprintf("%-60s |", $2);

                # Print the key-value pair with a separator line after each row
                print key "  " value;
                print "|-----------------------------|---------------------------------------------------------------|";
            }' >> "$output_file"

            # Increment client number
            client_number=$((client_number + 1))
        done < "$file"
    done

    # Now, check if the MAC address exists in the detailed report and print the results
    # Instead of just using "grep -A", let's search for the MAC address in the detailed output
    if grep -q "$input_mac" "$output_file"; then
        echo "Found detailed information for MAC address $input_mac:"
        echo "|-----------------------------|---------------------------------------------------------------|"
        grep -A 60 "$input_mac" "$output_file"   # Show 20 lines after the MAC address
    else
        echo "No detailed information found for MAC address $input_mac."
    fi
else
    echo "Exiting the script."
    exit 0
fi



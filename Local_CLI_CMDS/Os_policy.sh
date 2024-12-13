#!/bin/sh

# Initialize variables
ssid=""
os_per=""
last_ssid=""
last_os_per=""

# Print the header of the table
echo "-------------------------------------------------------------------------------------------------------------------------------"

# Extract SSID and os_per
uci show wireless | grep -E 'ssid|os_per' | while read line; do
    # Extract SSID and os_per values using basic shell tools
    case "$line" in
        *ssid=*)
            ssid=$(echo "$line" | sed "s/.*ssid='\([^']*\)'.*/\1/" | sort | uniq)
            ;;
        *os_per=*)
            os_per=$(echo "$line" | sed "s/.*os_per='\([^']*\)'.*/\1/" | sort | uniq)

            # Skip if the SSID and os_per combination has already been processed
            if [ "$ssid" = "$last_ssid" ] && [ "$os_per" = "$last_os_per" ]; then
                continue
            fi

            # Update the last SSID and os_per
            last_ssid=$ssid
            last_os_per=$os_per

            # Print SSID and associated os_per
            profile_name=$os_per
            profile_file="/usr/lib/lua/luci/os_policy/profile/$profile_name"

            if [ -r "$profile_file" ]; then
                # Read profile content
                content=$(cat "$profile_file")

                # Extract relevant fields using 'grep' and 'cut'
                profile_action=$(echo "$content" | grep -o '"ProfileAction":"[^"]*"' | cut -d'"' -f4)
                os_list=$(echo "$content" | grep -o '"OS_list":"[^"]*"' | cut -d'"' -f4)
                mac_list=$(echo "$content" | grep -o '"mac_list":"[^"]*"' | cut -d'"' -f4)
                mac_action=$(echo "$content" | grep -o '"mac_action":"[^"]*"' | cut -d'"' -f4)

                # Format OS list
                os_names=""
                if [ -n "$os_list" ]; then
                    for os in $(echo "$os_list" | tr ',' ' '); do
                        case $os in
                            1) os_names="$os_names Linux, " ;;
                            2) os_names="$os_names Windows, " ;;
                            3) os_names="$os_names Printer / Scanner, " ;;
                            4) os_names="$os_names Apple, " ;;
                            5) os_names="$os_names Android, " ;;
                            6) os_names="$os_names macOS, " ;;
                            7) os_names="$os_names iOS, " ;;
                            *) os_names="$os_names $os - Unknown OS, " ;;
                        esac
                    done
                    # Remove the trailing comma and space, then add a period
                    #os_names=$(echo "$os_names" | sed 's/, $/./')
                    os_names=$(echo "$os_names" | sed 's/[,\ ]*$//')
                else
                    os_names="No OS list found"
                fi

                # If the mac_list is not empty, format it as a comma-separated list
                if [ -n "$mac_list" ]; then
                    mac_list=$(echo "$mac_list" | tr ',' ' ')
                else
                    mac_list="No MAC list found"
                fi

                # Print the SSID information in a structured format
	#	echo "-------------------------------------------------------------------------------------------------------------------------------"
		
                printf "| %-20s     | %-95s |\n" "SSID" "$ssid"
                printf "| %-20s     | %-95s |\n" "Profile Name" "$profile_name"
                printf "| %-20s     | %-95s |\n" "ProfileAction" "$profile_action"
                printf "| %-20s     | %-95s |\n" "OS_list" "$os_names"
                printf "| %-20s     | %-95s |\n" "mac_Exception" "$mac_list"
                printf "| %-20s     | %-95s |\n" "Exception_action" "$mac_action"
echo "-------------------------------------------------------------------------------------------------------------------------------"
            else
                echo "Error: Profile \"$profile_name\" not found or not readable in /usr/lib/lua/luci/os_policy/profile/"
            fi
            ;;
    esac
done

# Print the table footer
echo "-------------------------------------------------------------------------------------------------------------------------------"


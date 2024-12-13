#!/bin/sh

App_filter() {
    # Get unique SSIDs from the wireless configuration
    ssids=$(uci show wireless | grep -Eo "ssid='[^']+'" | cut -d= -f2 | tr -d "'" | sort | uniq)
    # Load the JSON data once into a variable
    json_data=$(cat /usr/lib/lua/luci/filtering/data.json)

    # Initialize a string to track processed SSIDs
    processed_ssids=""
    filter_applied=false  # Flag to check if any app_filter is applied

    # Loop through the SSIDs
    for ssid in $ssids; do
        # Check if this SSID has already been processed
#        echo "$processed_ssids" | grep -q " $ssid " && continue

        # Print the SSID for debugging
#        echo "Processing SSID: $ssid"

        # Find all section indexes corresponding to the SSID in the wireless configuration
        section_indexes=$(uci show wireless | grep "ssid='$ssid'" | awk -F'.' '{print $2}' | awk -F'[' '{print $2}' | awk -F']' '{print $1}')

        # Initialize the flag for printing once per SSID
        processed_ssid_info=""

        # Loop through the section indexes
        for section_index in $section_indexes; do
            # Retrieve the app_filter value for this section using the section index
            app_filter=$(uci get wireless.@wifi-iface[$section_index].app_filter 2>/dev/null)

            # Only proceed if app_filter is not empty and not equal to "0"
            if [ "$app_filter" != "0" ] && [ -n "$app_filter" ]; then
                # Use jq to find the matched filter configuration in the JSON data
                matched_name=$(echo "$json_data" | jq -r --arg app_filter "$app_filter" '.AppFilter[] | select(.Name == $app_filter) | .Name')

                if [ "$matched_name" = "$app_filter" ]; then
                    # Extract the required fields for the matched app_filter
                    wlan_list=$(echo "$json_data" | jq -r --arg app_filter "$app_filter" '.AppFilter[] | select(.Name == $app_filter) | .wlan_list // "N/A"')
                    policy=$(echo "$json_data" | jq -r --arg app_filter "$app_filter" '.AppFilter[] | select(.Name == $app_filter) | .Groups[0].Policy // "N/A"')
                    app_list=$(echo "$json_data" | jq -r --arg app_filter "$app_filter" '.AppFilter[] | select(.Name == $app_filter) | .Groups[0].AppList // "N/A"')

                    # Accumulate the details for the SSID
                    processed_ssid_info="SSID     |     $ssid\nFilter   |     $policy\nAppList  |     $app_list"

                    # Once processed, break the loop for the SSID (only print once)
                    break
                fi
            fi
            
        done

        # Print the accumulated SSID info if it's not empty
        if [ -n "$processed_ssid_info" ]; then
            echo "-----------------------------------------------------------------------------"
            echo -e "$processed_ssid_info"
            # Mark SSID as processed by appending to the list
            processed_ssids="$processed_ssids $ssid"
            filter_applied=true  # Set flag to true if any filter is applied
        fi
    done

    # If no filter was applied to any SSID, print the appropriate message
    if [ "$filter_applied" = false ]; then
        echo "Application filtering not applied to any SSID."
    fi

    echo "-----------------------------------------------------------------------------"
}

App_filter


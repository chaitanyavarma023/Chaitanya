#!/bin/sh

Url_filter() {
    # Get unique SSIDs from the wireless configuration
    ssids=$(uci show wireless | grep -Eo "ssid='[^']+'" | cut -d= -f2 | tr -d "'" | sort | uniq)

    # Load the JSON data once into a variable
    json_data=$(cat /usr/lib/lua/luci/filtering/data.json)

    # Initialize a string to track processed SSIDs
    processed_ssids=""
    filter_applied=false  # Flag to check if any url_filter is applied

    # Set a maximum number of URLs per line for better formatting
    max_urls_per_line=10  # Adjust this value based on your desired line length

    # Loop through the SSIDs
    for ssid in $ssids; do
        # Find all section indexes corresponding to the SSID in the wireless configuration
        section_indexes=$(uci show wireless | grep "ssid='$ssid'" | awk -F'.' '{print $2}' | awk -F'[' '{print $2}' | awk -F']' '{print $1}')

        # Initialize the flag for printing once per SSID
        processed_ssid_info=""

        # Loop through the section indexes
        for section_index in $section_indexes; do
            # Retrieve the url_filter value for this section using the section index
            url_filter=$(uci get wireless.@wifi-iface[$section_index].url_filter 2>/dev/null)

            if [ "$url_filter" != "0" ] && [ -n "$url_filter" ]; then
                # Use jq to find the matched filter configuration in the JSON data
                matched_name=$(echo "$json_data" | jq -r --arg url_filter "$url_filter" '.UrlFilter[] | select(.Name == $url_filter) | .Name')

                if [ "$matched_name" = "$url_filter" ]; then
                    # Extract the required fields for the matched url_filter
                    wlan_list=$(echo "$json_data" | jq -r --arg url_filter "$url_filter" '.UrlFilter[] | select(.Name == $url_filter) | .wlan_list // "N/A"')
                    policy=$(echo "$json_data" | jq -r --arg url_filter "$url_filter" '.UrlFilter[] | select(.Name == $url_filter) | .Policy // "N/A"')
                    url_list=$(echo "$json_data" | jq -r --arg url_filter "$url_filter" '.UrlFilter[] | select(.Name == $url_filter) | .UrlList // "N/A"')

                    # Split the URL list into an array by commas using a simple loop
                    url_array=$(echo "$url_list" | tr ',' '\n')

                    # Start accumulating the SSID information
                    processed_ssid_info="SSID       |    $ssid\nFilter     |    $policy"

                    # Break the URL list into multiple lines if needed
                    url_line=""
                    url_count=0
                    for url in $url_array; do
                        # Add the URL to the current line
                        url_line="$url_line$url, "
                        url_count=$((url_count + 1))

                        # If the line exceeds the max URLs per line, print and start a new line
                        if [ "$url_count" -ge "$max_urls_per_line" ]; then
                            processed_ssid_info="$processed_ssid_info\nUrlList    |    $url_line"
                            url_line=""
                            url_count=0
                        fi
                    done

                    # Print any remaining URLs in the last line
                    if [ -n "$url_line" ]; then
                        processed_ssid_info="$processed_ssid_info\nUrlList    |    $url_line"
                    fi

                    # Once processed, break the loop for the SSID (only print once)
                    break
                fi
            fi
        done

        # Print the accumulated SSID info if it's not empty
        if [ -n "$processed_ssid_info" ]; then
            echo "----------------------------------------------------------------------------------------------------------"
            echo -e "$processed_ssid_info"
            # Mark SSID as processed by appending to the list
            processed_ssids="$processed_ssids $ssid"
            filter_applied=true  # Set flag to true if any filter is applied
        fi
    done

    # If no filter was applied to any SSID, print the appropriate message
    if [ "$filter_applied" = false ]; then
        echo "URL filtering not applied to any SSID."
    fi

    echo "-----------------------------------------------------------------------------------------------------------"
}

Url_filter

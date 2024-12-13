#!/bin/bash
###|=================================================================================================================================================================================================
###|SCRIPT_PATH                          :  /usr/CMD/get_allowed_channels
###|USAGE                                :  To Display Supported channels that can be configured in AP.
###|SUPPORT                              :  Only work/tested for qsdk model aps ~[H-245.*|O-230.*|I-240.*|O-240.*|H-250.*|I-270.*|I-280.*|I-290.*|O-290.*|I-470.*|I-480.*|O-480.*|I-490.*|O-490.*]
###|ARGUMENTS                            :  get_allowed_channels
###|==================================================================================================================================================================================================
######################################################################################################################################################################################################

# Function to print a well-defined table with the provided data
print_table() {
  local title=$1
  local data=$2
  local separator="|-------------------------------------------------------------------------|"
  
  echo "$separator"
  echo "$title"
  echo "$separator"
  echo "$data"
  echo "$separator"
}

# Function to check if interface exists and print channel list
fire_command() {
  local interface=$1
  local title=$2
  
  if iw dev | grep -q "$interface"; then
    # Capture apstats output
    local data=$(apstats -r -i "$interface")
    
    if [[ -z "$data" ]]; then
      echo "No data available for $interface."
      return
    fi

    # Process and format the data for tabular output
    formatted_data=$(echo "$data" | awk '
      BEGIN {
        # Print table headers
        printf "|%-50s|     %-17s|\n", "    Parameter", "Value"
        printf "|%-50s     %-17s\n", "--------------------------------------------------|----------------------|"
      }
      {
        # Handle lines that contain key-value pairs (e.g., "Tx Data Packets = 900")
        if ($0 ~ / = /) {
          split($0, arr, " = ")  # Split line by " = "
          metric = arr[1]
          value = arr[2]
          gsub(/^ +| +$/, "", metric)  # Trim spaces from metric and value
          gsub(/^ +| +$/, "", value)
          
          # Print the key-value pair in tabular format
          printf "|%-50s|     %-17s|\n", metric, value
        }
        # Handle special cases like lithium_cycle_cnt and similar multi-line values
        else if ($0 ~ /lithium_cycle_cnt|Chan NF/) {
          print $0  # Print the full line as is without further processing
        }
        # Print any other lines (e.g., titles, headers)
        else {
          print $0
        }
      }
    ')

    # Print the formatted table
    print_table "|             AP DEBUG RADIO-LEVEL STATISTICS FOR $interface" "$formatted_data  "

  else
    echo "Interface $interface not available"
    echo ""
  fi
}

# Check for wifi1 (2.4GHz or 5GHz)
if iw dev | grep -q "wifi1"; then
  fire_command wifi1 "2.4GHz"
else
  echo "[Warn]: Interface for 2.4GHz not present"
  echo ""
fi # End of the if block for wifi1

# Check for wifi0 (5GHz)
if iw dev | grep -q "wifi0"; then
  fire_command wifi0 "5GHz"
else
  echo "[Warn]: Interface for 5GHz not present"
  echo ""
fi # End of the if block for wifi0


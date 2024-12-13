#!/bin/sh
###|=================================================================================================================================================================================================
###|SCRIPT_PATH                          :  /usr/CMD/get_allowed_channels
###|USAGE                                :  To Display Supported channels that can be configured in AP.
###|SUPPORT                              :  Only work/tested for qsdk model aps ~[H-245.*|O-230.*|I-240.*|O-240.*|H-250.*|I-270.*|I-280.*|I-290.*|O-290.*|I-470.*|I-480.*|O-480.*|I-490.*|O-490.*]
###|ARGUMENTS                            :  get_allowed_channels
###|==================================================================================================================================================================================================
######################################################################################################################################################################################################

# Function to print text in a table format with a full border
print_table() {
  local title="$1"
  local content="$2"
  local line_length=98  # Adjust the length of the border


  # Title Header
  echo "|$(printf '%-98s' "-------------------------------------------------------------------- $title Channels ---------------------------------------------------------------------|")"


  # Table Header
  echo "|$(printf '%-98s' "---------------------------------------------- Supported channels that can be configured in AP for $title ------------------------------------------------|")"

  # Middle Border
echo "|$(printf '%-98s' "--------------------------------------------------------------------------------------------------------------------------------------------------------|")"

  # Table Content (inside border)
  # Use a pipe to pass the content line-by-line to the while loop
  echo "$content" | while IFS= read -r line; do
    # Print the content inside the border, ensuring the right border is printed too
    echo "| $(printf '%-93s' "$line") "
  done
  
  # Bottom Border
echo "|$(printf '%-98s' "--------------------------------------------------------------------------------------------------------------------------------------------------------|")"

}

# Function to check if interface exists and print channel list
fire_command() {
  local interface="$1"
  local title="$2"
  if iwconfig "$interface" &> /dev/null; then
    channel_list=$(wlanconfig "$interface" list chan)
    print_table "$title" "$channel_list"
  else
    echo "Interface $interface not available"
    echo ""
  fi
}

# Get list of all interfaces
interfaces=$(iwconfig 2>/dev/null | grep -oE '^ath[0-9]+' || true)

# Check for ath00 (2.4GHz)
if echo "$interfaces" | grep -q "ath00"; then
  fire_command ath00 "2.4GHz"
else
  echo "[Warn]: Interface for 2.4GHz not present"
  echo ""
fi

# Check for ath10 (5GHz)
if echo "$interfaces" | grep -q "ath10"; then
  fire_command ath10 "5GHz"
else
  echo "[Warn]: Interface for 5GHz not present"
  echo ""
fi


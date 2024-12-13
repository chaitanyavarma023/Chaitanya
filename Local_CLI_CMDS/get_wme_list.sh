#!/bin/sh
###|=================================================================================================================================================================================================
###|SCRIPT_PATH                          :  /usr/CMD/get_allowed_channels
###|USAGE                                :  To Display Supported channels that can be configured in AP.
###|SUPPORT                              :  Only work/tested for qsdk model aps ~[H-245.*|O-230.*|I-240.*|O-240.*|H-250.*|I-270.*|I-280.*|I-290.*|O-290.*|I-470.*|I-480.*|O-480.*|I-490.*|O-490.*]
###|ARGUMENTS                            :  get_allowed_channels
###|==================================================================================================================================================================================================
######################################################################################################################################################################################################

# Function to print text
print_text() {
  local text=$1
  echo "$text"
}

# Function to check if interface exists and print channel list
fire_command() {
  local interface=$1
  local title=$2
  if iwconfig "$interface" &> /dev/null; then
    print_text "|---------------------------------------------------|"
    print_text "|                $title Channels                      |"
    print_text "|---------------------------------------------------|"
    print_text "|  AC Type   | cwmin | cwmax | aifs | txopLimit     |"
    print_text "|---------------------------------------------------|"
    # Parse and display WME list in a tabular format
    wlanconfig "$interface" list wme | while read line; do
      # Match only lines that start with a valid AC Type (AC_BE, AC_BK, AC_VI, AC_VO)
      if echo "$line" | grep -qE '^(AC_[A-Z]+)'; then
        ac_type=$(echo "$line" | awk '{print $1}')
        cwmin=$(echo "$line" | awk '{print $3}')
        cwmax=$(echo "$line" | awk '{print $5}')
        aifs=$(echo "$line" | awk '{print $7}')
        txopLimit=$(echo "$line" | awk '{print $9}')
        printf "| %-10s | %-5s | %-5s | %-4s | %-13s |\n" "$ac_type" "$cwmin" "$cwmax" "$aifs" "$txopLimit"
      fi
    done
    print_text "|---------------------------------------------------|"
  else
    print_text "Interface $interface not available"
    echo ""
  fi
}

# Get list of all interfaces
interfaces=$(iwconfig 2>/dev/null | grep -oE '^ath[0-9]+' || true)

# Check for ath00 (2.4GHz)
if echo "$interfaces" | grep -q "ath00"; then
  fire_command ath00 "2.4GHz"
else
  print_text "[Warn]: Interface for 2.4GHz not present"
  echo ""
fi

# Check for ath10 (5GHz)
if echo "$interfaces" | grep -q "ath10"; then
  fire_command ath10 "5GHz"
else
  print_text "[Warn]: Interface for 5GHz not present"
  echo ""
fi


#!/bin/bash

# Function to print text with proper column formatting
print_text() {
  local text=$1
  echo "$text"
}

# Function to check if interface exists and print channel list in table format
fire_command() {
  local interface=$1
  local title=$2
  if iwconfig "$interface" &> /dev/null; then
    print_text "---------------- $title Channels ---------------"
    print_text "------------------------------------------------"
    print_text "| Channel |   Band  |    Selection Time        |"
    print_text "------------------------------------------------"
    wifitool "$interface" tr069_chanhist | tail -n +3 | awk '{ printf "| %-7s | %-7s | %-24s |\n", $1, $2, $3 " " $4 }'

    print_text "------------------------------------------------"
    echo ""
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


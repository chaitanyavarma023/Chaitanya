#!/bin/sh

######################################################################################################################################################################################################
###SCRIPT_PATH                          :  /usr/CMD/get_ap_neighbours_list
###|USAGE                                :  Show Neighbour APs Statistics for 2.4/5GHz.
###|SUPPORT                              :  Only work/tested for qsdk model aps ~[H-245.*|O-230.*|I-240.*|O-240.*|H-250.*|I-270.*|I-280.*|I-290.*|O-290.*|I-470.*|I-480.*|O-480.*|I-490.*|O-490.*]
###|ARGUMENTS                            :  get_ap_neighbours_list
###|==================================================================================================================================================================================================
######################################################################################################################################################################################################

# Function to print text
print_text() {
  local text="$1"
  echo "$text"
}

# Function to check if interface exists and print neighbour APs list
check_interface() {
  local interface="$1"
  local title="$2"
  local output_file="neighbor_aps_output.txt"

  # Check if the interface exists
  if iwconfig "$interface" > /dev/null 2>&1; then
    
    print_text " --------------------------------------- $title Neighbour APs ----------------------------------------------"
    print_text "|------------------------------------------------------------------------------------------------------------|"
    print_text "|   $(iwconfig "$interface" channel 0)                                                                                                         |"

    # Print the initial message
    print_text "|PLEASE WAIT FOR 10S [AP IS IN SCANNING-MODE]                                                                |"
    sleep 6
    # Store the output of wlanconfig in a file
    wlanconfig "$interface" list ap > "$output_file"

    # Process the output file using awk to format it into a table
    awk '
    BEGIN {
        # Print the header and separator lines at the start
        print "|------------------------------------------------------------------------------------------------------------|"
        print "|SSID                                               | BSSID                               | CHAN    | RATE   |"
        print "|------------------------------------------------------------------------------------------------------------|"
    }
    # Process each line of the file
    $0 ~ /[0-9]+:[0-9]+/ {
        # Skip header lines or lines with "S:N", "INT", or "CAPS"
        if ($1 != "S:N" && $1 != "INT" && $1 != "CAPS" && $3 != "CHAN") {
            # Initialize variables for SSID, BSSID, Channel, and Rate
            ssid = ""
            bssid = ""
            channel = ""
            rate = ""

            # Loop to capture SSID (everything before BSSID)
            for (i = 1; i <= NF; i++) {
                # Identify BSSID (expected to be in MAC address format, e.g., xx:xx:xx:xx:xx:xx)
                if ($i ~ /^[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}$/) {
                    bssid = $i
                    channel = $(i+1)
                    rate = $(i+2)
                    break
                } else {
                    # Append all fields before BSSID as part of SSID
                    if (ssid != "") {
                        ssid = ssid " " $i
                    } else {
                        ssid = $i
                    }
                }
            }

            # Print SSID, BSSID, Channel, and Rate in a formatted table
            printf "|%-50s | %-35s | %-7s | %-7s|\n", ssid, bssid, channel, rate
        }
    }
	END {
        print "|------------------------------------------------------------------------------------------------------------|"
    }
' "$output_file"


  else
    print_text "Interface $interface not available"
    echo ""
  fi
}

# Get list of all interfaces
interfaces=$(iwconfig 2>/dev/null | grep -oE '^ath[0-9]+' || true)

# Check for ath00 (2.4GHz)
if echo "$interfaces" | grep -q "ath00"; then
  check_interface "ath00" "2.4GHz"
else
  print_text "[Warn]: Interface for 2.4GHz not present"
  echo ""
fi

# Check for ath10 (5GHz)
if echo "$interfaces" | grep -q "ath10"; then
  check_interface "ath10" "5GHz"
else
  print_text "[Warn]: Interface for 5GHz not present"
  echo ""
fi


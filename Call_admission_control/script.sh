#!/bin/bash

######./script.sh 04:ea:56:23:74:70 2c:be:eb:97:45:45 DROP wlan1 (example to run script)

# Check if correct number of arguments are passed
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <sourcemac> <destinationmac> <drop|accept> <interface>"
  echo "For dual-band (2.4G and 5G) block/accept, the script will apply the rules to both wlan0 and wlan1."
  exit 1
fi

# Assign arguments to variables
SOURCEMAC=$1
DESTMAC=$2
ACTION=$3
INTERFACE=$4

# Check if the action is either drop or accept
if [[ "$ACTION" != "DROP" && "$ACTION" != "ACCEPT" ]]; then
  echo "Error: Action must be either 'DROP' or 'ACCEPT'"
  exit 1
fi

# Apply ebtables rules for both directions on both interfaces (wlan0 for 2.4GHz and wlan1 for 5GHz)
for iface in wlan0 wlan1; do
  ebtables -A FORWARD -i $iface -s $SOURCEMAC -d $DESTMAC -j $ACTION
  ebtables -A FORWARD -i $iface -s $DESTMAC -d $SOURCEMAC -j $ACTION
done

# Check if the rules were added successfully
if [ $? -eq 0 ]; then
  echo "Ebtables rules applied successfully for $SOURCEMAC and $DESTMAC on both wlan0 (2.4GHz) and wlan1 (5GHz)."
else
  echo "Failed to apply ebtables rules."
  exit 1
fi


#!/bin/sh

#===================================================================
# CMD            : tcpdump					   #
# PATH           : /usr/CMD/					   #
# USAGE          : Used to capture network traffic using tcpdump   #
# ARGUMENTS      : Takes runtime arguments			   #
#                 Used by admin login				   #
#                 e.g. : /usr/CMD/tcpdump			   #
# RETURN VALUE   : Prints the output of tcpdump capture		   #
#===================================================================

P1="/usr/bin/"
P2="/bin/"
P3="/usr/sbin/"
P4="/sbin/"

######################## Function to check if a network interface is valid########################################


is_valid_interface() {
    if ! ip link show "$1" &>/dev/null; then
        echo "Invalid interface: $1"
        exit 1
    fi
}


######################## If no arguments are passed, prompt user for input#########################################


if [[ "$#" -lt 1 ]]; then
    printf "\e[1;91m%-15s\e[m" "Input Interface(s) (e.g., eth0 or 'any' for all): "
    read Interfaces
    printf "\e[1;91m%-15s\e[m" "Input Capture Duration (seconds, Default 10): "
    read Duration
    [[ ! "$Duration" ]] && Duration=10
    printf "\e[1;91m%-15s\e[m" "Input Packet Count (Default 50): "
    read PacketCount
    [[ ! "$PacketCount" ]] && PacketCount=50
    printf "\e[1;91m%-15s\e[m" "Input Filter (e.g., port 80 or 'port 80 or port 443'): "
    read Filter

######################### Check if the interfaces are valid, or 'any' is provided##################################

    if [[ "$Interfaces" != "any" ]]; then
        for Interface in $Interfaces; do
            is_valid_interface "$Interface"
        done
    fi

########################## Set the tcpdump command options for multiple ports #######################################

    if [[ "$Filter" ]]; then
        FilterOption="port $Filter"
    else
        FilterOption=""
    fi

########################### Run tcpdump for the provided interfaces##################################################

    if [[ "$Interfaces" == "any" ]]; then
        ${P3}tcpdump -i any -c "$PacketCount" -G "$Duration" $FilterOption
    else
        for Interface in $Interfaces; do
            ${P3}tcpdump -i "$Interface" -c "$PacketCount" -G "$Duration" $FilterOption &
        done
        wait
    fi


########################## If arguments are passed, use them to capture packets#######################################

else
    Interfaces=$1
    PacketCount=${2:-50}  # Default to 50 if no packet count is passed
    Duration=${3:-10}     # Default to 10 seconds if no duration is passed
    Filter=$4             # Filter, e.g., port 80

######################### Check if the interfaces are valid, or 'any' is provided#####################################

    if [[ "$Interfaces" != "any" ]]; then
        for Interface in $Interfaces; do
            is_valid_interface "$Interface"
        done
    fi

########################## Set the tcpdump command options############################################################

    if [[ "$Filter" ]]; then
        FilterOption="port $Filter"
    else
        FilterOption=""
    fi

############################# Run tcpdump for the provided interfaces#################################################

    if [[ "$Interfaces" == "any" ]]; then
        ${P3}tcpdump -i any -c "$PacketCount" -G "$Duration" $FilterOption
    else
        for Interface in $Interfaces; do
            ${P3}tcpdump -i "$Interface" -c "$PacketCount" -G "$Duration" $FilterOption &
        done
        wait
    fi
fi

################################################## END ######################################################################







@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@2
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



# script with Ip address option below


#!/bin/sh

#===================================================================
# CMD            : tcpdump					    #
# PATH           : /usr/CMD/					    #
# USAGE          : Used to capture network traffic using tcpdump    #
# ARGUMENTS      : Takes runtime arguments			    #
#                 Used by admin login				    #
#                 e.g. : /usr/CMD/tcpdump				    #
# RETURN VALUE   : Prints the output of tcpdump capture		    #
#===================================================================

P1="/usr/bin/"
P2="/bin/"
P3="/usr/sbin/"
P4="/sbin/"

######################## Function to check if a network interface is valid #######################################

is_valid_interface() {
    if ! ip link show "$1" &>/dev/null; then
        echo "Invalid interface: $1"
        exit 1
    fi
}

######################## Function to handle IP-based filtering (Source or Destination IP) #######################

get_ip_filter() {
    # Ask for IP address input
    printf "\e[1;91m%-15s\e[m" "Enter IP Address: "
    read IpAddress

    # Ask if it is a source or destination IP
    printf "\e[1;91m%-15s\e[m" "Is this IP the Source or Destination? (s/d): "
    read IpType

    # Construct the IP filter
    if [[ "$IpType" == "s" || "$IpType" == "S" ]]; then
        IpFilter="src $IpAddress"
    elif [[ "$IpType" == "d" || "$IpType" == "D" ]]; then
        IpFilter="dst $IpAddress"
    else
        echo "Invalid option. Please enter 's' for source or 'd' for destination."
        exit 1
    fi
}

######################## If no arguments are passed, prompt user for input #######################################

if [[ "$#" -lt 1 ]]; then
    # If no parameters provided, ask the user for IP filter
    printf "\e[1;91m%-15s\e[m" "Do you want to filter by IP address? (y/n): "
    read UseIpFilter
    if [[ "$UseIpFilter" == "y" || "$UseIpFilter" == "Y" ]]; then
        get_ip_filter
    fi

    ########################## Ask for Interface, Duration, and Packet Count if needed #####################

    printf "\e[1;91m%-15s\e[m" "Input Interface(s) (e.g., eth0 or 'any' for all): "
    read Interfaces
    [[ ! "$Interfaces" ]] && Interfaces="any"  # Default to 'any' if no interface is provided.

    printf "\e[1;91m%-15s\e[m" "Input Capture Duration (seconds, Default 10): "
    read Duration
    [[ ! "$Duration" ]] && Duration=10

    printf "\e[1;91m%-15s\e[m" "Input Packet Count (Default 50): "
    read PacketCount
    [[ ! "$PacketCount" ]] && PacketCount=50

    printf "\e[1;91m%-15s\e[m" "Input Filter (e.g., port 80 or 'port 80 or port 443'): "
    read Filter

    ########################## Check if the interfaces are valid, or 'any' is provided #########################

    if [[ "$Interfaces" != "any" ]]; then
        for Interface in $Interfaces; do
            is_valid_interface "$Interface"
        done
    fi

    ########################## Set the tcpdump command options for multiple ports ##############################

    if [[ "$Filter" ]]; then
        FilterOption="port $Filter"
    else
        FilterOption=""
    fi

    ########################## Add IP filter if provided #############################################

    if [[ "$IpFilter" ]]; then
        if [[ "$FilterOption" ]]; then
            FilterOption="$FilterOption and $IpFilter"
        else
            FilterOption="$IpFilter"
        fi
    fi

    ########################## Run tcpdump for the provided interfaces ##################################

    if [[ "$Interfaces" == "any" ]]; then
        ${P3}tcpdump -i any -c "$PacketCount" -G "$Duration" $FilterOption
    else
        for Interface in $Interfaces; do
            ${P3}tcpdump -i "$Interface" -c "$PacketCount" -G "$Duration" $FilterOption &
        done
        wait
    fi

    ########################## If arguments are passed, handle them here ###################################
else
    Interfaces=$1
    PacketCount=${2:-50}  # Default to 50 if no packet count is passed
    Duration=${3:-10}     # Default to 10 seconds if no duration is passed
    Filter=$4             # Filter, e.g., port 80

    ########################## Check if the interfaces are valid, or 'any' is provided #####################

    if [[ "$Interfaces" != "any" ]]; then
        for Interface in $Interfaces; do
            is_valid_interface "$Interface"
        done
    fi

    ########################## Set the tcpdump command options for multiple ports ##############################

    if [[ "$Filter" ]]; then
        FilterOption="port $Filter"
    else
        FilterOption=""
    fi

    ########################## Add IP filter if provided #############################################

    if [[ "$IpFilter" ]]; then
        if [[ "$FilterOption" ]]; then
            FilterOption="$FilterOption and $IpFilter"
        else
            FilterOption="$IpFilter"
        fi
    fi

    ########################## Run tcpdump for the provided interfaces ##################################

    if [[ "$Interfaces" == "any" ]]; then
        ${P3}tcpdump -i any -c "$PacketCount" -G "$Duration" $FilterOption
    else
        for Interface in $Interfaces; do
            ${P3}tcpdump -i "$Interface" -c "$PacketCount" -G "$Duration" $FilterOption &
        done
        wait
    fi
fi



################################################## END ########################################################


#!/bin/bash

mcast=1

INTERFACE="ath10"




apply_rules() {
    echo "Applying multicast filter rules..."
    # Example rules to drop multicast and broadcast traffic
    ebtables --concurrent -t broute -A BROUTING --in-interface ath10 -p IPv4 --ip-proto udp --ip-dport 67 -j ACCEPT
    ebtables --concurrent -t broute -A BROUTING --in-interface ath10 -p IPv4 --ip-proto udp --ip-sport 68 -j ACCEPT
    ebtables --concurrent -A FORWARD -i "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type neighbor-solicitation -j ACCEPT
    ebtables --concurrent -A FORWARD -o "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type neighbor-solicitation -j ACCEPT
    ebtables --concurrent -A FORWARD -i "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type neighbor-advertisement -j ACCEPT
    ebtables --concurrent -A FORWARD -o "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type neighbor-advertisement -j ACCEPT
    ebtables --concurrent -A FORWARD -i "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type router-solicitation -j ACCEPT
    ebtables --concurrent -A FORWARD -o "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type router-solicitation -j ACCEPT
    ebtables --concurrent -A FORWARD -i "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type router-advertisement -j ACCEPT
    ebtables --concurrent -A FORWARD -o "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type router-advertisement -j ACCEPT
    ebtables --concurrent -t broute -A BROUTING --in-interface "$INTERFACE" -p IPv4 --ip-proto igmp -j ACCEPT
    ebtables --concurrent -t broute -A BROUTING --in-interface "$INTERFACE" -d ! 33:33:00:00:00:00/FF:FF:00:00:00:00 -j ACCEPT
    ebtables --concurrent -t broute -I BROUTING --in-interface "$INTERFACE" -d ! 01:00:5E:00:00:00/FF:FF:FF:80:00:00 -j ACCEPT

    ebtables --concurrent -t broute -A BROUTING --in-interface "$INTERFACE" -d 01:00:5E:00:00:00/FF:FF:FF:80:00:00 -j DROP
    ebtables --concurrent -t broute -A BROUTING --in-interface "$INTERFACE" -d ff:ff:ff:ff:ff:ff -j DROP
    ebtables --concurrent -t broute -A BROUTING --in-interface "$INTERFACE" -d 33:33:00:00:00:00/FF:FF:00:00:00:00 -j DROP
    echo "Rules applied successfully."
}




clear_rules() {
    echo "Clearing multicast filter rules..."
    # Example commands to remove the previously added rules
    ebtables --concurrent -t broute -D BROUTING --in-interface "$INTERFACE" -p IPv4 --ip-proto udp --ip-dport 67 -j ACCEPT
    ebtables --concurrent -t broute -D BROUTING --in-interface "$INTERFACE" -p IPv4 --ip-proto udp --ip-sport 68 -j ACCEPT
    ebtables --concurrent -D FORWARD -i "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type neighbor-solicitation -j ACCEPT
    ebtables --concurrent -D FORWARD -o "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type neighbor-solicitation -j ACCEPT
    ebtables --concurrent -D FORWARD -i "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type neighbor-advertisement -j ACCEPT
    ebtables --concurrent -D FORWARD -o "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type neighbor-advertisement -j ACCEPT
    ebtables --concurrent -D FORWARD -i "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type router-solicitation -j ACCEPT
    ebtables --concurrent -D FORWARD -o "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type router-solicitation -j ACCEPT
    ebtables --concurrent -D FORWARD -i "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type router-advertisement -j ACCEPT
    ebtables --concurrent -D FORWARD -o "$INTERFACE" -p IPv6 --ip6-proto ipv6-icmp --ip6-icmp-type router-advertisement -j ACCEPT
    ebtables --concurrent -t broute -D BROUTING --in-interface "$INTERFACE" -p IPv4 --ip-proto igmp -j ACCEPT
    ebtables --concurrent -t broute -D BROUTING --in-interface "$INTERFACE" -d ! 33:33:00:00:00:00/FF:FF:00:00:00:00 -j ACCEPT
    ebtables --concurrent -t broute -D BROUTING --in-interface "$INTERFACE" -d ! 01:00:5E:00:00:00/FF:FF:FF:80:00:00 -j ACCEPT

    ebtables --concurrent -t broute -D BROUTING --in-interface "$INTERFACE" -d 01:00:5E:00:00:00/FF:FF:FF:80:00:00 -j DROP
    ebtables --concurrent -t broute -D BROUTING --in-interface "$INTERFACE" -d ff:ff:ff:ff:ff:ff -j DROP
    ebtables --concurrent -t broute -D BROUTING --in-interface "$INTERFACE" -d 33:33:00:00:00:00/FF:FF:00:00:00:00 -j DROP
    
    echo "Rules cleared successfully."
}




# Main logic
if [[ $mcast -eq 1 ]]; then
    apply_rules
else
    clear_rules
fi
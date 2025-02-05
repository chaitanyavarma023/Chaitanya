
iptables -A INPUT -i eth0 -p esp -j ACCEPT
iptables -A INPUT -i eth0 -p esp -j DROP


ebtables -A FORWARD -i eth0 -p IPv4 --ip-proto 50 -j DROP
ebtables -t broute -A BROUTING -i eth0 -p IPv4 --ip-proto 50 -j DROP


ebtables -t broute -A BROUTING -i br-wan -p IPv4 --ip-proto tcp --ip-dport 21 -j DROP
ebtables -A FORWARD -i br-wan -p IPv4 --ip-proto tcp --ip-dport 21 -j DROP
ebtables -A INPUT -i br-wan -p IPv4 --ip-proto tcp --ip-dport 21 -j DROP

iptables -A FORWARD -i br-wan -p tcp --dport 21 -j DROP
iptables -A INPUT -i br-wan -p tcp --dport 21 -j DROP
iptables -A OUTPUT -o br-wan -p tcp --sport 21 -j DROP
iptables -t raw -A PREROUTING -i br-wan -p tcp --dport 21 -j DROP
iptables -t mangle -A PREROUTING -i br-wan -p tcp --dport 21 -j DROP

iptables -A FORWARD -i br-wan -p esp -j DROP
iptables -A INPUT -i br-wan -p esp -j DROP
iptables -A OUTPUT -o br-wan -p esp -j DROP
iptables -t raw -A PREROUTING -i br-wan -p esp -j DROP
iptables -t mangle -A PREROUTING -i br-wan -p esp  -j DROP

iptables -A FORWARD -i eth0 -p 50 -j DROP
iptables -A INPUT -i eth0 -p 50 -j DROP
iptables -A OUTPUT -o eth0 -p 50 -j DROP
iptables -t raw -A PREROUTING -i eth0 -p 50 -j DROP
iptables -t mangle -A PREROUTING -i eth0 -p 50  -j DROP


h323 tcp

iptables -A INPUT -i br-wan -p tcp --dport 1720 -j DROP
iptables -A OUTPUT -o br-wan -p tcp --sport 1720 -j DROP
iptables -A FORWARD -i br-wan -p tcp --dport 1720 -j DROP
iptables -t raw -A PREROUTING -i br-wan -p tcp --dport 1720 -j DROP
iptables -t mangle -A PREROUTING -i br-wan -p tcp --dport 1720 -j DROP


h323 udp

iptables -D INPUT -i br-wan -p udp --dport 1719 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 1719 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 1719 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 1719 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 1719 -j DROP
iptables -D INPUT -i br-wan -p udp --dport 1720 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 1720 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 1720 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 1720 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 1720 -j DROP


http proxy2 

iptables -D INPUT -i br-wan -p tcp --dport 8080 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 8080 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 8080 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 8080 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 8080 -j DROP



http proxy3

iptables -D INPUT -i br-wan -p tcp --dport 3128 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 3128 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 3128 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 3128 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 3128 -j DROP


http

iptables -D INPUT -i br-wan -p tcp --dport 80 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 80 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 80 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 80 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 80 -j DROP

https


iptables -D INPUT -i br-wan -p tcp --dport 443 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 443 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 443 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 443 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 443 -j DROP


iptables -D INPUT -i br-wan -m physdev --physdev-in eth0 -p tcp --dport 443 -j DROP
iptables -D OUTPUT -o br-wan -m physdev --physdev-out eth0 -p tcp --sport 443 -j DROP
iptables -D FORWARD -i br-wan -m physdev --physdev-in eth0 -p tcp --dport 443 -j DROP
iptables -t raw -D PREROUTING -i br-wan -m physdev --physdev-in eth0 -p tcp --dport 443 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -m physdev --physdev-in eth0 -p tcp --dport 443 -j DROP

iptables -A INPUT -i br-wan -m physdev --physdev-in eth0 -p tcp --dport 443 -j DROP
iptables -A OUTPUT -o br-wan -m physdev --physdev-out eth0 -p tcp --sport 443 -j DROP
iptables -A FORWARD -i br-wan -m physdev --physdev-in eth0 -p tcp --dport 443 -j DROP
iptables -t raw -A PREROUTING -i br-wan -m physdev --physdev-in eth0 -p tcp --dport 443 -j DROP
iptables -t mangle -A PREROUTING -i br-wan -m physdev --physdev-in eth0 -p tcp --dport 443 -j DROP


ike udp 

iptables -A INPUT -i br-wan -p udp --dport 500 -j DROP
iptables -A OUTPUT -o br-wan -p udp --sport 500 -j DROP
iptables -A FORWARD -i br-wan -p udp --dport 500 -j DROP
iptables -t raw -A PREROUTING -i br-wan -p udp --dport 500 -j DROP
iptables -t mangle -A PREROUTING -i br-wan -p udp --dport 500 -j DROP

iptables -A INPUT -i br-wan -p udp --dport 4500 -j DROP
iptables -A OUTPUT -o br-wan -p udp --sport 4500 -j DROP
iptables -A FORWARD -i br-wan -p udp --dport 4500 -j DROP
iptables -t raw -A PREROUTING -i br-wan -p udp --dport 4500 -j DROP
iptables -t mangle -A PREROUTING -i br-wan -p udp --dport 4500 -j DROP


Kerberos 

# Block TCP port 88
iptables -D INPUT -i br-wan -p tcp --dport 88 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 88 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 88 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 88 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 88 -j DROP

# Block UDP port 88
iptables -D INPUT -i br-wan -p udp --dport 88 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 88 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 88 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 88 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 88 -j DROP

# Block UDP port 464 (Kerberos password change)
iptables -D INPUT -i br-wan -p udp --dport 464 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 464 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 464 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 464 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 464 -j DROP

L2tp udp 1701   and   Block IPsec (UDP ports 500 and 4500 for L2TP over IPsec):


iptables -D INPUT -i br-wan -p udp --dport 1701 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 1701 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 1701 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 1701 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 1701 -j DROP



iptables -D INPUT -i br-wan -p udp --dport 500 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 500 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 500 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 500 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 500 -j DROP
iptables -D INPUT -i br-wan -p udp --dport 4500 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 4500 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 4500 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 4500 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 4500 -j DROP

Lpd tcp

iptables -D INPUT -i br-wan -p tcp --dport 515 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 515 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 515 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 515 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 515 -j DROP

Lpd tcp

iptables -D INPUT -i br-wan -p udp --dport 515 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 515 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 515 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 515 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 515 -j DROP



msrpc tcp and udp

iptables -D INPUT -i br-wan -p tcp --dport 135 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 135 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 135 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 135 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 135 -j DROP

iptables -D INPUT -i br-wan -p udp --dport 135 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 135 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 135 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 135 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 135 -j DROP


natt 


iptables -D INPUT -i br-wan -p udp --dport 4500 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 4500 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 4500 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 4500 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 4500 -j DROP



netbios dgm 



iptables -D INPUT -i br-wan -p udp --dport 138 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 138 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 138 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 138 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 138 -j DROP


netbios ns 



iptables -D INPUT -i br-wan -p udp --dport 137 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 137 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 137 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 137 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 137 -j DROP



netbios ssn 



iptables -D INPUT -i br-wan -p tcp --dport 139 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 139 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 139 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 139 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 139 -j DROP


NTP 

iptables -D INPUT -i br-wan -p udp --dport 123 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 123 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 123 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 123 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 123 -j DROP


POP3 



iptables -D INPUT -i br-wan -p tcp --dport 110 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 110 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 110 -j DROP
iptables -D INPUT -i br-wan -p tcp --dport 995 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 995 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 995 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 110 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 995 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 110 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 995 -j DROP



PPTP 



iptables -D INPUT -i br-wan -p tcp --dport 1723 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 1723 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 1723 -j DROP
iptables -D INPUT -i br-wan -p 47 -j DROP
iptables -D OUTPUT -o br-wan -p 47 -j DROP
iptables -D FORWARD -i br-wan -p 47 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 1723 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p 47 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 1723 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p 47 -j DROP


RTSP

iptables -D INPUT -i br-wan -p tcp --dport 554 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 554 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 554 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 554 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 554 -j DROP


iptables -D INPUT -i br-wan -p udp --dport 6970:6999 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 6970:6999 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 6970:6999 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 6970:6999 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 6970:6999 -j DROP



SCCP



iptables -D INPUT -i br-wan -p tcp --dport 2000 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 2000 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 2000 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 2000 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 2000 -j DROP

iptables -D INPUT -i br-wan -p tcp --dport 2443 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 2443 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 2443 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 2443 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 2443 -j DROP

iptables -D INPUT -i br-wan -p udp --dport 16384:32767 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 16384:32767 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 16384:32767 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 16384:32767 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 16384:32767 -j DROP





SIPS

iptables -D INPUT -i br-wan -p tcp --dport 5061 -j DROP
iptables -D INPUT -i br-wan -p udp --dport 5061 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 5061 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 5061 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 5061 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 5061 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 5061 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 5061 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 5061 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 5061 -j DROP


SIP

iptables -D INPUT -i br-wan -p tcp --dport 5060 -j DROP
iptables -D INPUT -i br-wan -p udp --dport 5060 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 5060 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 5060 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 5060 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 5060 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 5060 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 5060 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 5060 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 5060 -j DROP


SMB

iptables -D INPUT -i br-wan -p tcp --dport 445 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 445 -j DROP
iptables -D INPUT -i br-wan -p udp --dport 137 -j DROP
iptables -D INPUT -i br-wan -p udp --dport 138 -j DROP
iptables -D INPUT -i br-wan -p tcp --dport 139 -j DROP
iptables -D INPUT -i br-wan -p udp --dport 139 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 137 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 138 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 139 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 139 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 445 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 137 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 138 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 139 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 139 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 445 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 137 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 138 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 139 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 139 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 445 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 137 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 138 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 139 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 139 -j DROP


smtp


iptables -D INPUT -i br-wan -p tcp --dport 25 -j DROP
iptables -D INPUT -i br-wan -p tcp --dport 465 -j DROP
iptables -D INPUT -i br-wan -p tcp --dport 587 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 25 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 465 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 587 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 25 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 465 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 587 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 25 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 465 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 587 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 25 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 465 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 587 -j DROP


snmp

iptables -D INPUT -i br-wan -p tcp --dport 161 -j DROP
iptables -D INPUT -i br-wan -p udp --dport 161 -j DROP
iptables -D INPUT -i br-wan -p udp --dport 162 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 161 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 161 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 162 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 161 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 161 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 162 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 161 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 161 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 162 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 161 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 161 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 161 -j DROP

ssh

iptables -D INPUT -i br-wan -p tcp --dport 22 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 22 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 22 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 22 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 22 -j DROP


svp

iptables -D INPUT -i br-wan -p udp --dport 5060 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 5060 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 5060 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 5060 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 5060 -j DROP
iptables -D INPUT -i br-wan -p udp --dport 16384:32767 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 16384:32767 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 16384:32767 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 16384:32767 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 16384:32767 -j DROP

syslog

iptables -D INPUT -i br-wan -p udp --dport 514 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 514 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 514 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 514 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 514 -j DROP                      


telnet

iptables -D INPUT -i br-wan -p tcp --dport 23 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 23 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 23 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 23 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 23 -j DROP        


tftp

iptables -D INPUT -i br-wan -p udp --dport 69 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 69 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 69 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 69 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 69 -j DROP



vocera


iptables -D INPUT -i br-wan -p udp --dport 5000 -j DROP
iptables -D INPUT -i br-wan -p tcp --dport 5100 -j DROP
iptables -D INPUT -i br-wan -p udp --dport 16666 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 5000 -j DROP
iptables -D OUTPUT -o br-wan -p tcp --sport 5100 -j DROP
iptables -D OUTPUT -o br-wan -p udp --sport 16666 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 5000 -j DROP
iptables -D FORWARD -i br-wan -p tcp --dport 5100 -j DROP
iptables -D FORWARD -i br-wan -p udp --dport 16666 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 5000 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p tcp --dport 5100 -j DROP
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 16666 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 5000 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p tcp --dport 5100 -j DROP
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 16666 -j DROP



iptables -D INPUT -i br-wan -p udp --dport 5060 -j ACCEPT
iptables -D OUTPUT -o br-wan -p udp --sport 5060 -j ACCEPT
iptables -D FORWARD -i br-wan -p udp --dport 5060 -j ACCEPT
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 5060 -j ACCEPT
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 5060 -j ACCEPT
iptables -D INPUT -i br-wan -p udp --dport 16384:32767 -j ACCEPT
iptables -D OUTPUT -o br-wan -p udp --sport 16384:32767 -j ACCEPT
iptables -D FORWARD -i br-wan -p udp --dport 16384:32767 -j ACCEPT
iptables -t raw -D PREROUTING -i br-wan -p udp --dport 16384:32767 -j ACCEPT
iptables -t mangle -D PREROUTING -i br-wan -p udp --dport 16384:32767 -j ACCEPT




iptables -A INPUT -m physdev --physdev-in br-wan -p udp --dport 5060 -j DROP
iptables -A OUTPUT -m physdev --physdev-out br-wan -p udp --sport 5060 -j DROP
iptables -A FORWARD -m physdev --physdev-in br-wan -p udp --dport 5060 -j DROP
iptables -t raw -A PREROUTING -m physdev --physdev-in br-wan -p udp --dport 5060 -j DROP
iptables -t mangle -A PREROUTING -m physdev --physdev-in br-wan -p udp --dport 5060 -j DROP
iptables -A INPUT -m physdev --physdev-in br-wan -p udp --dport 16384:32767 -j DROP
iptables -A OUTPUT -m physdev --physdev-out br-wan -p udp --sport 16384:32767 -j DROP
iptables -A FORWARD -m physdev --physdev-in br-wan -p udp --dport 16384:32767 -j DROP
iptables -t raw -A PREROUTING -m physdev --physdev-in br-wan -p udp --dport 16384:32767 -j DROP
iptables -t mangle -A PREROUTING -m physdev --physdev-in br-wan -p udp --dport 16384:32767 -j DROP



iptables -A INPUT -m physdev --physdev-in ath00 -p udp --dport 5060 -j DROP
iptables -A OUTPUT -m physdev --physdev-out ath00 -p udp --sport 5060 -j DROP
iptables -A FORWARD -m physdev --physdev-in ath00 -p udp --dport 5060 -j DROP
iptables -t raw -A PREROUTING -m physdev --physdev-in ath00 -p udp --dport 5060 -j DROP
iptables -t mangle -A PREROUTING -m physdev --physdev-in ath00 -p udp --dport 5060 -j DROP
iptables -A INPUT -m physdev --physdev-in ath00 -p udp --dport 16384:32767 -j DROP
iptables -A OUTPUT -m physdev --physdev-out ath00 -p udp --sport 16384:32767 -j DROP
iptables -A FORWARD -m physdev --physdev-in ath00 -p udp --dport 16384:32767 -j DROP
iptables -t raw -A PREROUTING -m physdev --physdev-in ath00 -p udp --dport 16384:32767 -j DROP
iptables -t mangle -A PREROUTING -m physdev --physdev-in ath00 -p udp --dport 16384:32767 -j DROP


iptables -A INPUT -m physdev --physdev-in ath10 -p udp --dport 5060 -j DROP
iptables -A OUTPUT -m physdev --physdev-out ath10 -p udp --sport 5060 -j DROP
iptables -A FORWARD -m physdev --physdev-in ath10 -p udp --dport 5060 -j DROP
iptables -t raw -A PREROUTING -m physdev --physdev-in ath10 -p udp --dport 5060 -j DROP
iptables -t mangle -A PREROUTING -m physdev --physdev-in ath10 -p udp --dport 5060 -j DROP
iptables -A INPUT -m physdev --physdev-in ath10 -p udp --dport 16384:32767 -j DROP
iptables -A OUTPUT -m physdev --physdev-out ath10 -p udp --sport 16384:32767 -j DROP
iptables -A FORWARD -m physdev --physdev-in ath10 -p udp --dport 16384:32767 -j DROP
iptables -t raw -A PREROUTING -m physdev --physdev-in ath10 -p udp --dport 16384:32767 -j DROP
iptables -t mangle -A PREROUTING -m physdev --physdev-in ath10 -p udp --dport 16384:32767 -j DROP
 #!/bin/bash

IPLANR="192.168.0.254"
IPLANH="192.168.0.1"
IPDMZR="172.16.0.6"
IPDMZH="172.16.0.5"
IPDNS="192.168.15.1"
IINT=eth0
ILAN=eth1
IDMZ=eth2

iptables -F

iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT

iptables -t nat -A POSTROUTING -o $IINT -s $IPLANH -j MASQUERADE
#iptables -t nat -A POSTROUTING -o $IINT -s $IPDMZH -j MASQUERADE


iptables -A FORWARD -i $ILAN -o $IINT -s $IPLANH -p tcp -m multiport --dport 80,443 -j ACCEPT
iptables -A FORWARD -i $IINT -o $ILAN -d $IPLANH -p tcp -m multiport --sport 80,443 -j ACCEPT

iptables -A INPUT -i $ILAN -s $IPLANH -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -o $ILAN -d $IPLANH -p tcp --sport 22 -j ACCEPT

#iptables -A INPUT -p udp --dport 22 -j ACCEPT
#iptables -A OUTPUT -p udp --sport 22 -j ACCEPT

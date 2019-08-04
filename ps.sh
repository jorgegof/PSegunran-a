#!/bin/bash

#Endereços IP
IPLANR="192.168.10.254"
IPLANH="192.168.10.1"
IPDMZR="172.16.10.6"
IPDMZH="172.16.10.5"
IPDNS="192.168.15.1"
#IPDNS="200.129.79.61"

#Interfaces
IINT=enp0s3
ILAN=enp0s8
IDMZ=enp0s9
#IINT=eth0
#ILAN=eth1
#IDMZ=eth2

#Endereços MAC
MACH="08:00:27:81:41:4e"
MACD="08:00:27:04:8c:d7"

iptables -F

iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

iptables -A FORWARD -p udp --dport 53 -d $IPDNS -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -s $IPDNS -j ACCEPT

iptables -t nat -A POSTROUTING -o $IINT -s $IPLANH -j MASQUERADE
iptables -t nat -A POSTROUTING -o $IINT -s $IPDMZH -j MASQUERADE

iptables -A FORWARD -i $ILAN -o $IINT -s $IPLANH -p tcp -m multiport --dport 80,443 -j ACCEPT
iptables -A FORWARD -i $IINT -o $ILAN -d $IPLANH -p tcp -m multiport --sport 80,443 -j ACCEPT

iptables -A FORWARD -i $IDMZ -o $IINT -s $IPDMZH -p tcp -m multiport --dport 80,443 -j ACCEPT
iptables -A FORWARD -i $IINT -o $IDMZ -d $IPDMZH -p tcp -m multiport --sport 80,443 -j ACCEPT

#iptables -A INPUT -p tcp --dport 22 -m mac ! --mac-source $MACH -j LOG --log-level info --log-prefix "SSH: "
iptables -A INPUT -p tcp --dport 22 -m mac ! --mac-source $MACD -j LOG --log-level info --log-prefix "SSH: "

iptables -A INPUT  -p tcp --dport 22 -m mac --mac-source $MACH -j ACCEPT
iptables -A INPUT  -p tcp --dport 22 -m mac --mac-source $MACD -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT


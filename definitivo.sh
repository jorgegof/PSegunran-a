#!/bin/bash

#REDE
REDE_LAN='192.168.10.0/24'
REDE_DMZ='172.16.10.4/30'
DNS='192.168.15.1'
#DNS='200.129.79.61'
GATEWAY_LAN='192.168.10.254'
SRV_DMZ='172.16.10.5'
CLIENT='192.168.10.1'
MAC='08:00:27:81:41:4e'
#VARIAVEL
INT_WAN='enp0s3'
INT_LAN='enp0s8'
INT_DMZ='enp0s9'

#LIMPANDO AS REGRAS 
iptables -F
iptables -F -t nat
iptables -X DMZ

#DEFININDO A POLITICA PADRAO
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#CHAIN

iptables -N DMZ
#iptables -P FWDDMZ DROP


#NAT DA LAN PARA INTERNET

iptables -t nat -A POSTROUTING -o $INT_WAN -s $REDE_LAN -j MASQUERADE
iptables -t nat -A POSTROUTING -o $INT_WAN -s $REDE_DMZ -j MASQUERADE

#LIBERAR TRAFEGO DA LAN PARA INTERNET P22, 88, 443 e 53
#IDA TCP
  iptables -A FORWARD -i $INT_LAN -o $INT_WAN -s $REDE_LAN -p tcp -m multiport --dports 22,80,443 -j ACCEPT
#VOLTA TCP
  iptables -A FORWARD -i $INT_WAN -o $INT_LAN -d $REDE_LAN -p tcp -m multiport --sports 22,80,443 -j ACCEPT

#IDA TCP
  iptables -A FORWARD -i $INT_LAN -o $INT_WAN -s $REDE_LAN -d $DNS -p udp --dport 53 -j ACCEPT
#VOLTA TCP
  iptables -A FORWARD -i $INT_WAN -o $INT_LAN -s $DNS -d $REDE_LAN -p udp --sport 53 -j ACCEPT


#LIBERAR SSH DE UM HOST 

iptables -A INPUT -i $INT_LAN -s $CLIENT -d $GATEWAY_LAN -p tcp --dport 22 -m mac --mac-source $MAC -j ACCEPT
iptables -A OUTPUT -s $GATEWAY_LAN -d $CLIENT -p tcp --sport 22 -j ACCEPT

#LOG SSH

#iptables -A INPUT -i $INT_LAN ! -s $CLIENT -d $GATEWAY_LAN -p tcp --dport 22 -j LOG  --log-prefix "SSH FORA DO PERMITIDO"


#PORT KNOCK 55500

iptables -A INPUT -i $INT_WAN -p tcp --dport 55500 -m recent --set --name SSH_OK
iptables -A INPUT -i $INT_WAN -p tcp --dport 22 -m recent --rcheck --name SSH_OK --seconds 120  -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT

#LIBERAR PING PELA WAN

iptables -A INPUT -i $INT_WAN -p icmp -j ACCEPT
iptables -A OUTPUT -o $INT_WAN -p icmp -j ACCEPT

#FORWARD WEB_DMZ CHAIN FWDDMZ | SSH ROUTER
	#SSH WAN->DMZ->ROUTER
iptables -t nat -A PREROUTING  -i $INT_WAN -p tcp --dport 12345 -j DNAT --to 172.16.10.5:22
	#FORWARD WAN->DMZ
#iptables -t nat -A PREROUTING  -i $INT_WAN -p tcp -j DNAT --to 172.16.10.5
iptables -A FORWARD -i $INT_WAN -o $INT_DMZ -j DMZ
iptables -A FORWARD -i $INT_DMZ -o $INT_WAN -j DMZ
iptables -A DMZ  -i $INT_WAN -o $INT_DMZ -d $SRV_DMZ -p tcp -m multiport --dports 443,80,22 -j ACCEPT
iptables -A DMZ  -i $INT_DMZ -o $INT_WAN -s $SRV_DMZ -p tcp -m multiport --sports 443,80,22 -j ACCEPT
	#SSH DMZ->ROUTER
iptables -A INPUT -i $INT_DMZ -s $SRV_DMZ -d 172.16.10.6 -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -s 172.16.10.6 -d $SRV_DMZ -p tcp --sport 22 -j ACCEPT

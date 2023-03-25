#! /usr/bin/env bash
#
# Generic Firewall config for simple client host
#

WIFI=wlp166s0
ETHERNET=eth2
VPN=tun0

WIRELESS="192.168.10.0/24"
WIRED="192.168.24.0/24"

SSH="ssh,6666"
RDP="3389"

# Wi-Fi

icmp_core $WIFI

icmp_block_broadcast $WIFI
icmp_block_strange $WIFI
icmp_ping_throttle $WIFI

tcp_core $WIFI
tcp_drop_broadcast $WIFI

tcp_any_out $WIFI

udp_core $WIFI
udp_drop_broadcast $WIFI

udp_any_out $WIFI

open_dhcp $WIFI

# public servers

open_tcp_server $WIRELESS $SSH 10
open_tcp_server $WIRELESS 80 10

# Ethernet

icmp_core $ETHERNET

icmp_block_broadcast $ETHERNET
icmp_block_strange $ETHERNET
icmp_ping_throttle $ETHERNET

tcp_core $ETHERNET
tcp_drop_broadcast $ETHERNET
tcp_any_out $ETHERNET

udp_core $ETHERNET
udp_drop_broadcast $ETHERNET

udp_any_out $ETHERNET

#
# VPN
#

icmp_core $VPN

icmp_block_broadcast $VPN
icmp_block_strange $VPN
icmp_ping_throttle $VPN

tcp_core $VPN
tcp_drop_broadcast $VPN
tcp_any_out $VPN

udp_core $VPN
udp_drop_broadcast $VPN
udp_any_out $VPN

open_dhcp $VPN

# local servers

open_tcp_server $WIRED $SSH 10
open_tcp_server $WIRED 80 10
open_tcp_server $WIRED $RDP 10

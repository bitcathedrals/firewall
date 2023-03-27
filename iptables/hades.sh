#! /usr/bin/env bash
#
# Generic Firewall config for simple client host
#

wifi=wlan0
ethernet=eth2
VPN=tun0

wirelessIP="192.68.10.169"
wirelessNet="192.168.10.0/24"

wiredIP="192.168.24.7"
wiredNet="192.168.24.0/24"

SSH="ssh,6666"
RDP="3389"

# universal

icmp_core
icmp_block_strange
icmp_block_broadcast

tcp_core
udp_core

# Wi-Fi

icmp_trusted $wirelessIP

tcp_drop_broadcast $wifi
tcp_any_out $wirelessIP

udp_any_out $wirelessIP

open_dhcp $wifi

open_tcp_server $wirelessIP $wirelessNet $SSH 10

# Ethernet

icmp_trusted $wiredIP

tcp_drop_broadcast $ethernet
tcp_any_out $wiredIP

udp_drop_broadcast $ethernet
udp_any_out $wiredIP

open_tcp_server $wiredIP $wiredNet $SSH 10
open_tcp_server $wiredIP $wiredNet $RDP 10

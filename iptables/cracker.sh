#! /usr/bin/env bash

#
# cracker configuration
#

wifi=wlp4s0
ethernet=enx0826ae3af2e5

wirelessNet="192.168.10.0/24"
wiredNet="192.168.24.0/24"

wirelessIP="192.168.10.141"
wiredIP="192.168.24.4"

SSH="ssh,6666"

# universal

icmp_core
icmp_block_strange
icmp_block_broadcast

tcp_core
udp_core

# Wi-Fi

icmp_ping_throttle $wirelessIP
icmp_trusted $wirelessIP

tcp_drop_broadcast $wifi
tcp_any_out $wirelessIP

udp_any_out $wirelessIP

open_dhcp $wifi

open_tcp_server $wirelessNet $SSH 10

# Ethernet

icmp_ping_throttle $wiredIP
icmp_trusted $wiredIP

tcp_drop_broadcast $ethernet
tcp_any_out $wiredIP

udp_drop_broadcast $ethernet
udp_any_out $wiredIP

open_tcp_server $wiredNet $SSH 10

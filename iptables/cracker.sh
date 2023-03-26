#! /usr/bin/env bash

#
# cracker configuration
#

WIFI=wlp4s0
ETHERNET=enx0826ae3af2e5

WIRELESS="192.168.10.0/24"
WIRED="192.168.24.0/24"

wirelessIP="192.168.10.141"
wiredIP="192.168.24.4"

SSH="ssh,6666"

#
# universal
#

tcp_core
udp_core

#
# Wi-Fi
#

icmp_core $wirelessIP

icmp_block_broadcast $WIFI
icmp_block_strange $wirelessIP
icmp_ping_throttle $wirelessIP

tcp_drop_broadcast $WIFI
tcp_any_out $wirelessIP

udp_drop_broadcast $WIFI
udp_any_out $wirelessIP

open_dhcp $WIFI

open_tcp_server $wirelessIP $SSH 10

#
# Ethernet
#

icmp_core $wiredIP

icmp_block_broadcast $ETHERNET
icmp_block_strange $wiredIP
icmp_ping_throttle $wiredIP

tcp_drop_broadcast $ETHERNET
tcp_any_out $wiredIP

udp_drop_broadcast $ETHERNET
udp_any_out $wiredIP

open_tcp_server $wiredIP $SSH 10






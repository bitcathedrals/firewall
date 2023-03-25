#! /usr/bin/env bash
#
# Generic Firewall config for simple client host
#

WIFI=wlp166s0
ETHERNET=enx0826ae3af2e5

WIRELESS="192.168.10.0/24"
WIRED="192.168.24.0/24"

SSH="ssh,6666"

icmp_core $WIFI

icmp_block_broadcast $WIFI
icmp_block_strange $WIFI
icmp_ping_throttle $WIFI

icmp_core $ETHERNET

icmp_block_broadcast $ETHERNET
icmp_block_strange $ETHERNET
icmp_ping_throttle $ETHERNET

tcp_core $WIFI
tcp_drop_broadcast $WIFI
tcp_any_out $WIFI

tcp_core $ETHERNET
tcp_drop_broadcast $ETHERNET
tcp_any_out $ETHERNET

udp_core $WIFI
udp_drop_broadcast $WIFI
udp_any_out $WIFI

open_dhcp $WIFI

udp_core $ETHERNET
udp_drop_broadcast $ETHERNET
udp_any_out $ETHERNET

open_tcp_server $WIRELESS $SSH 10
open_tcp_server $WIRED $SSH 10









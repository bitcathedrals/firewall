#! /usr/bin/env bash
#
# Generic Firewall config for simple client host
#

WIFI=wlp166s0
WIRED=enx0826ae33d126

icmp_core $WIFI

icmp_block_broadcast $WIFI
icmp_block_strange $WIFI
icmp_ping_throttle $WIFI

icmp_core $WIRED

icmp_block_broadcast $WIRED
icmp_block_strange $WIRED
icmp_ping_throttle $WIRED

tcp_core $WIFI
tcp_drop_broadcast $WIFI
tcp_any_out $WIFI


tcp_core $WIRED
tcp_drop_broadcast $WIRED
tcp_any_out $WIRED

udp_core $WIFI
udp_drop_broadcast $WIFI
udp_any_out $WIFI

open_dhcp $WIFI

udp_core $WIRED
udp_drop_broadcast $WIRED
udp_any_out $WIRED











#! /usr/bin/env bash
#
# Generic Firewall config for simple client host
#

WIFI=wlp166s0

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











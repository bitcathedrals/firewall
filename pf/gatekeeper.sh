#! /usr/bin/env bash

pf_firewall=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"

NTP=123
IRCD=6667

source $pf_firewall

#
# basics policy
#

default_policy

#
# WiFi (local)
#

# low level

open_icmp $wifi
open_dhcp $wifi

# basic services

open_out $wifi udp domain
open_out $wifi udp $NTP

# needed for updates and packages

open_out $wifi tcp "{ 80, 443 , 8080 }"

# security

open_out $wifi tcp ssh
open_out $wifi tcp 6666

# ssh server

open_server_throttle $wifi tcp 6666 10 "5/10"
open_server_throttle $wifi tcp $IRCD 10 "5/10"


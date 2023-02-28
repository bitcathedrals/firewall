#! /usr/bin/env bash

pf_openbsd=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"

SSH=6666
NTP=123
IRC=6667
RSYNC=873

source $pf_openbsd

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
open_out $wifi tcp $SSH

# ssh server

open_server_throttle $wifi tcp $SSH 10 "5/10"
open_server_throttle $wifi tcp $IRC 10 "5/10"

open_server_from $wifi tcp $RSYNC "{ 192.168.10.141 , 192.168.10.127 }" 10 "5/10"

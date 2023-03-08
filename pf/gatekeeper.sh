#! /usr/bin/env bash

pf_openbsd=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"

SSH=6666
NTP=123
IRC=6667
RSYNC=873

PORTMAP=111

STATUS_UDP=736
STATUS_TCP=905

LOCK_UDP=626
LOCK_TCP=849

MOUNT_UDP=793
MOUNT_TCP=866

MOUNT_NFS=2049

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

open_server_from $wifi tcp $RSYNC "{192.168.10.141,192.168.10.127,192.168.10.169, 192.168.10.138}" 10 "5/10"

open_server_from $wifi "{tcp,udp}" $PORTMAP "192.168.10.0/24" 20 "5/10"

open_server_from $wifi udp $STATUS_UDP "192.168.10.0/24" 20 "5/10"
open_server_from $wifi tcp $STATUS_TCP "192.168.10.0/24" 20 "5/10"

open_server_from $wifi udp $LOCK_UDP "192.168.10.0/24" 20 "5/10"
open_server_from $wifi tcp $LOCK_TCP "192.168.10.0/24" 20 "5/10"

open_server_from $wifi udp $MOUNT_UDP "192.168.10.0/24" 20 "5/10"
open_server_from $wifi tcp $MOUNT_TCP "192.168.10.0/24" 20 "5/10"

open_server_from $wifi "{tcp,udp}" $MOUNT_NFS "192.168.10.0/24" 20 "5/10"


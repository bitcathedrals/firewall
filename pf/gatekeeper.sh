#! /usr/bin/env bash

pf_openbsd=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"
ethernet="ure0"

wireless="192.168.10.0/24"
wired="192.168.24.1/24"

gatekeeper=192.168.24.1
cracker=192.168.24.4
spartan=192.168.24.5
redbox=192.168.24.6
hades=192.168.24.7

unix="{ $cracker , $hades , $redbox , $spartan }"

SSH=6666
IRC=6667

RSYNC=873

source $pf_openbsd

PORTMAP_UDP=`rpc_port localhost portmapper udp`
PORTMAP_TCP=`rpc_port localhost portmapper tcp`

STATUS_UDP=`rpc_port localhost status udp`
STATUS_TCP=`rpc_port localhost status tcp`

LOCK_UDP=`rpc_port localhost nlockmgr udp`
LOCK_TCP=`rpc_port localhost nlockmgr tcp`

MOUNT_UDP=`rpc_port localhost mountd udp`
MOUNT_TCP=`rpc_port localhost mountd tcp`

NFS_UDP=`rpc_port localhost nfs udp`
NFS_TCP=`rpc_port localhost nfs tcp`

rpc_print

#
# drop policy
#

default_policy

# basic networking

open_icmp $wifi
open_icmp $ethernet

open_dhcp $wifi

# outbound - basic IP services

open_out $wifi udp $DOMAIN
open_out $wifi udp $NTP

# outbound HTTP needed for updates

open_out $wifi tcp "{ 80, 443 , 8080 }"

# SSH

open_out $wifi tcp ssh
open_out $wifi tcp $SSH

open_out $ethernet tcp ssh
open_out $ethernet tcp $SSH

# ssh server

open_server_throttle $wifi tcp $SSH 10 "5/10"
open_server_throttle $ethernet tcp $SSH 10 "5/10"

# DNS server

open_server_from $wifi udp $DOMAIN $wireless "25" "25/1"
open_server_from $ethernet udp $DOMAIN $wired "25" "25/1"

# IRC server

open_server_throttle $wifi tcp $IRC 10 "5/10"
open_server_throttle $ethernet tcp $IRC 10 "5/10"


open_server_from $ethernet tcp $RSYNC $unix 10 "5/10"

open_server_from $ethernet udp $PORTMAP_UDP $wired "25" "30/10"
open_server_from $ethernet tcp $PORTMAP_TCP $wired "25" "30/10"

open_server_from $ethernet udp $STATUS_UDP $wired "25" "30/10"
open_server_from $ethernet tcp $STATUS_TCP $wired "25" "30/10"

open_server_from $ethernet udp $LOCK_UDP $wired "25" "30/10"
open_server_from $ethernet tcp $LOCK_TCP $wired "25" "30/10"

open_server_from $ethernet udp $MOUNT_UDP $wired "25" "30/10"
open_server_from $ethernet tcp $MOUNT_TCP $wired "25" "30/10"

open_server_from $ethernet udp $NFS_UDP $wired "25" "30/10"
open_server_from $ethernet tcp $NFS_TCP $wired "25" "30/10"


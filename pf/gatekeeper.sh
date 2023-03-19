#! /usr/bin/env bash

pf_openbsd=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"
ethernet="ure0"

wireless="192.168.10.0/24"
wired="192.168.24.0/24"

gatekeeper=192.168.24.1
cracker=192.168.24.4
spartan=192.168.24.5
redbox=192.168.24.6
hades=192.168.24.7


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

open_out $wifi tcp "{ 80 , 443 , 8080 }"

# SSH

open_out $wifi tcp ssh
open_out $wifi tcp $SSH

open_out $ethernet tcp ssh
open_out $ethernet tcp $SSH

# ssh server

open_from tcp $SSH $wireless "5/10" 10
open_from tcp $SSH $wired "5/10" 10

# DNS server

open_from udp $DOMAIN $wireless "25/1" 50
open_from udp $DOMAIN $wired "25/1" 50

# IRC server

# open_on $wifi tcp $IRC 10 "5/10"
# open_on $ethernet tcp $IRC 10 "5/10"

# rsync

open_from tcp $RSYNC "{ $cracker , $hades , $redbox , $spartan }" "5/10" 10

# NFS

open_from udp $PORTMAP_UDP $wired "30/10" "25"
open_from tcp $PORTMAP_TCP $wired "30/10" "25"

open_from udp $STATUS_UDP $wired "30/10" "25"
open_from tcp $STATUS_TCP $wired "30/10" "25"

open_from udp $LOCK_UDP $wired "30/10" "25"
open_from tcp $LOCK_TCP $wired "30/10" "25"

open_from udp $MOUNT_UDP $wired "25" "30/10"
open_from tcp $MOUNT_TCP $wired "25" "30/10"

open_from udp $NFS_UDP $wired "30/10" "25"
open_from tcp $NFS_TCP $wired "30/10" "25"


#! /usr/bin/env bash

pf_openbsd=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"
ethernet="ure0"

wireless="192.168.10.0/24"
wireless_myip="192.168.10.189"

wired="192.168.24.0/24"
wired_myip="192.168.24.1"

gatekeeper=192.168.24.1
cracker=192.168.24.4
spartan=192.168.24.5
redbox=192.168.24.6
hades=192.168.24.7

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

# basic network services

open_router $wifi

# trusted services

open_trusted $wifi
open_trusted $ethernet

# outbound HTTP needed for updates

open_out $wifi tcp "$WEB"

# ssh server

open_from tcp "$SSH" $wireless_myip $wireless "5/1" 10
open_from tcp "$SSH" $wired_myip $wired "5/1" 10

# DNS server

open_from "{ udp , tcp }" $DOMAIN $wireless_myip $wireless "50/1" 150
open_from "{ udp , tcp }" $DOMAIN $wired_myip $wired "50/1" 150

# IRC server

# open_in $wifi tcp $IRC 10 "5/10"
# open_in $ethernet tcp $IRC 10 "5/10"

# rsync

open_from tcp $RSYNC $wired_myip "{ $cracker , $hades , $redbox , $spartan }" "5/1" 10

# NFS

open_from udp $PORTMAP_UDP $wired_myip $wired "30/10" "25"
open_from tcp $PORTMAP_TCP $wired_myip $wired "30/10" "25"

open_from udp $STATUS_UDP $wired_myip $wired "30/10" "25"
open_from tcp $STATUS_TCP $wired_myip $wired "30/10" "25"

open_from udp $LOCK_UDP $wired_myip $wired "30/10" "25"
open_from tcp $LOCK_TCP $wired_myip $wired "30/10" "25"

open_from udp $MOUNT_UDP $wired_myip $wired "30/10" "25"
open_from tcp $MOUNT_TCP $wired_myip $wired "30/10" "25"

open_from udp $NFS_UDP $wired_myip $wired "30/10" "25"
open_from tcp $NFS_TCP $wired_myip $wired "30/10" "25"


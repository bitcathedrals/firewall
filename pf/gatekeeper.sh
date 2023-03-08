#! /usr/bin/env bash

pf_openbsd=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"

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

open_out $wifi udp $DOMAIN
open_out $wifi udp $NTP

# needed for updates and packages

open_out $wifi tcp "{ 80, 443 , 8080 }"

# security

open_out $wifi tcp ssh
open_out $wifi tcp $SSH

# ssh server

open_server_throttle $wifi tcp $SSH 10 "5/10"
open_server_throttle $wifi tcp $IRC 10 "5/10"

open_server_from $wifi udp $DOMAIN "192.168.10.0/24" "25" "25/1"

open_server_from $wifi tcp $RSYNC "{192.168.10.141,192.168.10.127,192.168.10.169, 192.168.10.138}" 10 "5/10"

open_server_from $wifi udp $PORTMAP_UDP "192.168.10.0/24" "25" "30/10"
open_server_from $wifi tcp $PORTMAP_TCP "192.168.10.0/24" "25" "30/10"

open_server_from $wifi udp $STATUS_UDP "192.168.10.0/24" "25" "30/10"
open_server_from $wifi tcp $STATUS_TCP "192.168.10.0/24" "25" "30/10"

open_server_from $wifi udp $LOCK_UDP "192.168.10.0/24" "25" "30/10"
open_server_from $wifi tcp $LOCK_TCP "192.168.10.0/24" "25" "30/10"

open_server_from $wifi udp $MOUNT_UDP "192.168.10.0/24" "25" "30/10"
open_server_from $wifi tcp $MOUNT_TCP "192.168.10.0/24" "25" "30/10"

open_server_from $wifi udp $NFS_UDP "192.168.10.0/24" "25" "30/10"
open_server_from $wifi tcp $NFS_TCP "192.168.10.0/24" "25" "30/10"


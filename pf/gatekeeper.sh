#! /usr/bin/env bash

source $HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"
ethernet="ure0"

wireless="192.168.10.0/24"
wireless_myip="192.168.10.189"

wired="192.168.24.0/24"
wired_myip="192.168.24.1"

cracker_wired=`host_lookup cracker.wired`
hades_wired=`host_lookup hades.wired`
redbox_wired=`host_lookup redbox.wired`
spartan_wired=`host_lookup spartan.wired`

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

open_router $wireless_myip $wifi

# trusted services

open_trusted $wireless_myip
open_trusted $wired_myip

# outbound HTTP needed for updates

outbound $wireless_myip tcp "$WEB"

# ssh server

in_from tcp $wireless_myip "$SSH" $wireless "5/1" 10
in_from tcp $wired_myip "$SSH" $wired "5/1" 10

# DNS server

in_from $wireless_myip "{ udp , tcp }" $DOMAIN $wireless "50/1" 150
in_from $wired_myip "{ udp , tcp }" $DOMAIN $wired "50/1" 150

# rsync

in_from $wired_myip tcp $RSYNC "{ $cracker_wired , $hades_wired , $redbox_wired , $spartan_wired }" "5/1" 10

# NFS

in_from $wired_myip udp $PORTMAP_UDP $wired "30/10" "25"
in_from $wired_myip tcp $PORTMAP_TCP $wired "30/10" "25"

in_from $wired_myip udp $STATUS_UDP $wired "30/10" "25"
in_from $wired_myip tcp $STATUS_TCP  $wired "30/10" "25"

in_from $wired_myip udp $LOCK_UDP $wired "30/10" "25"
in_from $wired_myip tcp $LOCK_TCP $wired "30/10" "25"

in_from $wired_myip udp $MOUNT_UDP $wired "30/10" "25"
in_from $wired_myip tcp $MOUNT_TCP  $wired "30/10" "25"

in_from $wired_myip udp $NFS_UDP $wired "30/10" "25"
in_from $wired_myip tcp $NFS_TCP $wired "30/10" "25"


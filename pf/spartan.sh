#! /usr/bin/env bash

macro intWifi iwx0
macro intEthernet ure0

macro_network wireless spartan.local "192.168.10.0/24"
macro_network wired spartan.wired "192.168.24.0/24"

#
# get ips for gatekeeper
#

macro_host gatekeeperWireless "gatekeeper.local"
macro_host gatekeeperWired "gatekeeper.wired"

gatekeeper=`host_lookup gatekeeper.wired`

# NFS related

PORTMAP_UDP=`rpc_port $gatekeeper portmapper udp`
PORTMAP_TCP=`rpc_port $gatekeeper portmapper tcp`

STATUS_UDP=`rpc_port $gatekeeper status udp`
STATUS_TCP=`rpc_port $gatekeeper status tcp`

LOCK_UDP=`rpc_port $gatekeeper nlockmgr udp`
LOCK_TCP=`rpc_port $gatekeeper nlockmgr tcp`

MOUNT_UDP=`rpc_port $gatekeeper mountd udp`
MOUNT_TCP=`rpc_port $gatekeeper mountd tcp`

NFS_UDP=`rpc_port $gatekeeper nfs udp`
NFS_TCP=`rpc_port $gatekeeper nfs tcp`

macro_host hadesWired "hades.wired"

#
# basics policy
#

default_policy

# WiFi/router

open_router \$wirelessIP \$intWifi

#
# trusted services
#

open_trusted \$wirelessIP
open_trusted \$wiredIP

rpc_print

out_to \$wiredIP udp "{ $PORTMAP_UDP , $STATUS_UDP , $LOCK_UDP , $MOUNT_UDP , $NFS_UDP }" \$wiredNet
out_to \$wiredIP tcp "{ $PORTMAP_TCP , $STATUS_TCP , $LOCK_TCP , $MOUNT_TCP , $NFS_TCP }" \$wiredNet

# backup

out_to \$wiredIP tcp $RSYNC \$gatekeeperWired

# RDP

out_to \$wiredIP tcp $RDP \$hadesWired

#
# SERVERS
#

# ssh server

in_from \$wirelessIP tcp "$SSH" \$wirelessNet "5/10" 10
in_from \$wirelessIP tcp "$SSH" \$wirelessNet "5/10" 10

# web,email,IRC on Wi-Fi

outbound \$wirelessIP tcp "$WEB"
outbound \$wirelessIP tcp "$MAIL"

outbound \$wirelessIP tcp "{ 194 , $IRC }"

# block ssh, telnet, ftp, rpc, smb
block_stealth \$wirelessIP tcp "{ 21 , 22 , 23 }"
block_stealth \$wirelessIP "{ tcp , udp }" 111
block_stealth \$wirelessIP "{ tcp , udp }" "{ 137 , 138 , 139 }"

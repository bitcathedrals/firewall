#! /usr/bin/env bash

macro intWifi iwx0
macro intEthernet ure0

macro_network wireless spartan.local "192.168.10.0/24"
macro_network wired spartan.wired "192.168.24.0/24"

#
# get ips for gatekeeper
#

rpc_map `host_lookup gatekeeper.wired`

macro_host gatekeeperWired "gatekeeper.wired"
macro_host hadesWired "hades.wired"

#
# basics policy
#

default_policy

#
# WiFi/router
#

open_risky \$wirelessIP \$wirelessBrd
open_router \$wirelessIP \$intWifi

# clients

outbound \$wirelessIP tcp "$WEB"
outbound \$wirelessIP tcp "$MAIL"

outbound \$wirelessIP tcp "{ 194 , $IRC }"

# servers

in_from \$wirelessIP tcp "$SSH" \$wirelessNet "5/10" 10

#
# Wired
#

open_trusted \$wiredIP \$wiredBrd
outbound \$wiredIP "{ udp , tcp }" domain

# clients

out_to \$wiredIP udp "{ $PORTMAP_UDP , $STATUS_UDP , $LOCK_UDP , $MOUNT_UDP , $NFS_UDP }" \$gatekeeperWired
out_to \$wiredIP tcp "{ $PORTMAP_TCP , $STATUS_TCP , $LOCK_TCP , $MOUNT_TCP , $NFS_TCP }" \$gatekeeperWired

out_to \$wiredIP tcp $RSYNC \$gatekeeperWired
out_to \$wiredIP tcp $RDP \$hadesWired

# servers

in_from \$wirelessIP tcp "$SSH" \$wirelessNet "5/10" 10

#
# block ssh, telnet, ftp, rpc, smb
#

block_stealth \$wirelessIP tcp "{ 21 , 22 , 23 }"
block_stealth \$wirelessIP "{ tcp , udp }" 111
block_stealth \$wirelessIP "{ tcp , udp }" "{ 137 , 138 , 139 }"

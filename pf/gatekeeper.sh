#! /usr/bin/env bash

macro intWifi iwx0
macro intEthernet ure0

macro_network wireless gatekeeper.local "192.168.10.0/24"
macro_network wired gatekeeper.wired "192.168.24.0/24"

macro_host crackerWired "cracker.wired"
macro_host hadesWired "hades.wired"
macro_host redboxWired "redbox.wired"
macro_host spartanWired "spartan.wired"

macro python 8080

rpc_map localhost

#
# drop policy
#

default_policy

# basic network services

open_router \$wirelessIP \$intWifi

# WiFi

open_risky \$wirelessIP

# clients

outbound \$wirelessIP tcp "$WEB"

# servers

in_from \$wirelessIP tcp "$SSH" \$wirelessNet "5/1" 10
in_from \$wirelessIP "{ udp , tcp }" $DOMAIN \$wirelessNet "50/1" 150

in_from \$wirelessIP tcp $HTTPD \$wirelessNet "50/1" 150
in_from \$wirelessIP "tcp" \$python \$wirelessNet "50/1" 10

# Wired

open_trusted \$wiredIP

# servers

in_from \$wiredIP tcp "$SSH" \$wiredNet "5/1" 10
in_from \$wiredIP "{ udp , tcp }" $DOMAIN \$wiredNet "50/1" 150

in_from \$wiredIP tcp $RSYNC "{ \$crackerWired , \$hadesWired , \$redboxWired , \$spartanWired }" "5/1" 10

in_from \$wiredIP udp "{ $PORTMAP_UDP , $STATUS_UDP , $LOCK_UDP , $MOUNT_UDP , $NFS_UDP }" \$wiredNet "30/10" "25"
in_from \$wiredIP tcp "{ $PORTMAP_TCP , $STATUS_TCP , $LOCK_TCP , $MOUNT_TCP , $NFS_TCP }" \$wiredNet "30/10" "25"

in_from \$wirelessIP tcp $HTTPD \$wirelessNet "50/1" 150
in_from \$wiredIP "tcp" \$python \$wirelessNet "50/1" 10



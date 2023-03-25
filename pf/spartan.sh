#! /usr/bin/env bash

source $HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"
ethernet="ure0"
vpn="tun0"

wireless="192.168.10.0/24"
wireless_myip=`host_lookup spartan.local`
wireless_broadcast=`broadcast_lookup $wireless_myip`

echo "spartan wireless net = $wireless" >/dev/stderr
echo "spartan wireless ip = $wireless_myip" >/dev/stderr
echo "spartan wireless broadcast = $wireless_broadcast" >/dev/stderr

wired="192.168.24.0/24"
wired_myip=`host_lookup spartan.wired`
wired_broadcast=`broadcast_lookup $wired_myip`

echo "spartan wired net = $wired" >/dev/stderr
echo "spartan wired ip = $wired_myip" >/dev/stderr
echo "spartan wired broadcast = $wired_broadcast" >/dev/stderr

#
# get ips for gatekeeper
#

gatekeeper_wireless=`host_lookup gatekeeper.local`
gatekeeper_wired=`host_lookup gatekeeper.wired`

echo "gatekeeper wireless ip = $gatekeeper_wireless" >/dev/stderr
echo "gatekeeper wired ip = $gatekeeper_wired" >/dev/stderr

hades_wired=`host_lookup hades.wired`

#
# basics policy
#

default_policy

# WiFi/router

open_router $wireless_myip $wifi

#
# trusted services
#

open_trusted $wireless_myip
open_trusted $wired_myip

#
# CLIENTS
#

# NFS related

PORTMAP_UDP=`rpc_port $gatekeeper_wired portmapper udp`
PORTMAP_TCP=`rpc_port $gatekeeper_wired portmapper tcp`

STATUS_UDP=`rpc_port $gatekeeper_wired status udp`
STATUS_TCP=`rpc_port $gatekeeper_wired status tcp`

LOCK_UDP=`rpc_port $gatekeeper_wired nlockmgr udp`
LOCK_TCP=`rpc_port $gatekeeper_wired nlockmgr tcp`

MOUNT_UDP=`rpc_port $gatekeeper_wired mountd udp`
MOUNT_TCP=`rpc_port $gatekeeper_wired mountd tcp`

NFS_UDP=`rpc_port $gatekeeper_wired nfs udp`
NFS_TCP=`rpc_port $gatekeeper_wired nfs tcp`

rpc_print

out_to $wired_myip udp $PORTMAP_UDP $gatekeeper_wired
out_to $wired_myip tcp $PORTMAP_TCP $gatekeeper_wired

out_to $wired_myip udp $STATUS_UDP $gatekeeper_wired
out_to $wired_myip tcp $STATUS_TCP $gatekeeper_wired

out_to $wired_myip udp $LOCK_UDP $gatekeeper_wired
out_to $wired_myip tcp $LOCK_TCP $gatekeeper_wired

out_to $wired_myip udp $MOUNT_UDP $gatekeeper_wired
out_to $wired_myip tcp $MOUNT_TCP $gatekeeper_wired

out_to $wired_myip udp $NFS_UDP $gatekeeper_wired
out_to $wired_myip tcp $NFS_TCP $gatekeeper_wired


# backup

out_to $wired_myip tcp $RSYNC $gatekeeper_wired

# RDP

out_to $wired_myip tcp $RDP $hades_wired

#
# SERVERS
#

# ssh server

in_from $wireless_myip tcp "$SSH" $wireless "5/10" 10
in_from $wired_myip tcp "$SSH" $wired "5/10" 10

# web,email,IRC on Wi-Fi

outbound $wireless_myip tcp "$WEB"
outbound $wireless_myip tcp "$MAIL"

outbound $wireless_myip tcp "{ 194 , $IRC }"


# block ssh, telnet, ftp, rpc, smb
block_stealth $wireless_myip tcp 21
block_stealth $wireless_myip tcp 22
block_stealth $wireless_myip tcp 23
block_stealth $wireless_myip "{ tcp , udp }" 111
block_stealth $wireless_myip "{ tcp , udp }" "{ 137 , 138 , 139 }"

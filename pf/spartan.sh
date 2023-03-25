#! /usr/bin/env bash

pf_firewall=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"
ethernet="ure0"
vpn="tun0"

wireless="192.168.10.0/24"
wireless_myip="192.168.10.138"

wired="192.168.24.0/24"
wired_myip="192.168.24.5"

source $pf_firewall

#
# get ips for gatekeeper
#

gatekeeper_wireless=`host_lookup gatekeeper.local`
gatekeeper_wired=`host_lookup gatekeeper.wired`


#
# basics policy
#

default_policy

# WiFi/router

open_router $wifi

#
# trusted services
#

open_trusted $wifi
open_trusted $ethernet

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

open_to $gatekeeper_wired udp $PORTMAP_UDP
open_to $gatekeeper_wired tcp $PORTMAP_TCP

open_to $gatekeeper_wired udp $STATUS_UDP
open_to $gatekeeper_wired tcp $STATUS_TCP

open_to $gatekeeper_wired udp $LOCK_UDP
open_to $gatekeeper_wired tcp $LOCK_TCP

open_to $gatekeeper_wired udp $MOUNT_UDP
open_to $gatekeeper_wired tcp $MOUNT_TCP

open_to $gatekeeper_wired udp $NFS_UDP
open_to $gatekeeper_wired tcp $NFS_TCP


# backup

open_to $gatekeeper_wired tcp $RSYNC

# RDP

open_out $ethernet tcp $RDP

#
# SERVERS
#

# ssh server

open_from tcp "$SSH" $wireless_myip $wireless "5/10" 10
open_from tcp "$SSH" $wired_myip $wired "5/10" 10

# VPN

open_out $wifi udp openvpn

# web,email,IRC on Wi-Fi

open_out $wifi tcp "$WEB"
open_out $wifi tcp "$MAIL"

open_out $wifi tcp "{ 194 , $IRC }"


# block ssh, telnet, ftp, rpc, smb
block_stealth $wifi tcp 21
block_stealth $wifi tcp 22
block_stealth $wifi tcp 23
block_stealth $wifi "{ tcp , udp }" 111
block_stealth $wifi "{ tcp , udp }" "{ 137 , 138 , 139 }"

#
# VPN (general)
#

# low level

open_dhcp $vpn

# basic services

open_out $vpn "{ udp , tcp }" domain

# security

open_out $vpn tcp "$SSH"

# web and email and ftp

open_out $vpn tcp "$WEB"
open_out $vpn tcp "$MAIL"

open_out $vpn tcp "$FTP"

# irc

open_out $vpn tcp "{ 194 , $IRC }"




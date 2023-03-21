#! /usr/bin/env bash

pf_firewall=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"
ethernet="ure0"
vpn="tun0"

wireless="192.168.10.0/24"
wireless_myip="192.168.10.138"

wired="192.168.24.0/24"
wired_myip="192.168.24.5"

IRC=6697

MY_SSH=6666

RDP=3389

source $pf_firewall

#
# basics policy
#

default_policy

#
# WiFi (local)
#

# low level

open_icmp $wifi
open_icmp $ethernet

open_dhcp $wifi

# basic services

open_out $wifi udp $NTP

open_out $wifi udp domain
open_out $ethernet udp domain

PORTMAP_UDP=`rpc_port gatekeeper.wired portmapper udp`
PORTMAP_TCP=`rpc_port gatekeeper.wired portmapper tcp`

STATUS_UDP=`rpc_port gatekeeper.wired status udp`
STATUS_TCP=`rpc_port gatekeeper.wired status tcp`

LOCK_UDP=`rpc_port gatekeeper.wired nlockmgr udp`
LOCK_TCP=`rpc_port gatekeeper.wired nlockmgr tcp`

MOUNT_UDP=`rpc_port gatekeeper.wired mountd udp`
MOUNT_TCP=`rpc_port gatekeeper.wired mountd tcp`

NFS_UDP=`rpc_port gatekeeper.wired nfs udp`
NFS_TCP=`rpc_port gatekeeper.wired nfs tcp`

# SSH

open_out $wifi tcp ssh
open_out $wifi tcp $MY_SSH

open_out $ethernet tcp ssh
open_out $ethernet tcp $MY_SSH

# backup

open_out $ethernet tcp $RSYNC

# VPN

open_out $wifi udp openvpn

# web and email

open_out $wifi tcp "{ 80, 443 , 8080 }"
open_out $wifi tcp "{ 25 , 2525 , 587 , 143 , 993 , 465 }"

# irc

open_out $wifi tcp "{ 194 , $IRC }"

# nfs

open_out $ethernet udp $PORTMAP_UDP
open_out $ethernet tcp $PORTMAP_TCP

open_out $ethernet udp $STATUS_UDP
open_out $ethernet tcp $STATUS_TCP

open_out $ethernet udp $LOCK_UDP
open_out $ethernet tcp $LOCK_TCP

open_out $ethernet udp $MOUNT_UDP
open_out $ethernet tcp $MOUNT_TCP

open_out $ethernet udp $NFS_UDP
open_out $ethernet tcp $NFS_TCP

#
# RDP
#

open_out $ethernet tcp $RDP

# ssh server

open_from tcp $MY_SSH $wireless_myip $wireless "5/10" 10
open_from tcp $MY_SSH $wired_myip $wired "5/10" 10

# block ssh, telnet, ftp, rpc, smb
block_stealth $wifi tcp 23
block_stealth $wifi tcp 21
block_stealth $wifi tcp 23
block_stealth $wifi "{ tcp , udp }" 111
block_stealth $wifi "{ tcp , udp }" "{ 137 , 138 , 139 }"

#
# VPN (general)
#

# low level

open_dhcp $vpn

# basic services

open_out $vpn udp domain

# security

open_out $vpn tcp ssh
open_out $vpn tcp $MY_SSH

# web and email and ftp

open_out $vpn tcp "{ 80 , 443 , 8080 }"
open_out $vpn tcp "{ 25 , 2525 , 587 , 143 , 993 , 465 }"
open_out $vpn tcp ftp

# irc

open_out $vpn tcp "{ 194 , $IRC }"




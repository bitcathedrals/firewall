#! /usr/bin/env bash

pf_firewall=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"
vpn="tun0"

NTP=123

IRC=6667

RSYNC=873

MY_SSH=6666

PORTMAP=111

STATUS_UDP=736
STATUS_TCP=905

LOCK_UDP=626
LOCK_TCP=849

MOUNT_UDP=793
MOUNT_TCP=866

MOUNT_NFS=2049


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
open_dhcp $wifi

# basic services

open_out $wifi udp domain
open_out $wifi udp $NTP

# security and backup

open_out $wifi tcp ssh
open_out $wifi tcp $MY_SSH

open_out $wifi tcp $RSYNC

# VPN

open_out $wifi udp openvpn

# web and email

open_out $wifi tcp "{ 80, 443 , 8080 }"
open_out $wifi tcp "{ 25 , 2525 , 587 , 143 , 993 , 465 }"

# irc

open_out $wifi tcp "{ 194 , $IRC }"

# nfs

open_out $wifi "{tcp,udp}" $PORTMAP

open_out $wifi udp $STATUS_UDP
open_out $wifi tcp $STATUS_TCP

open_out $wifi udp $LOCK_UDP
open_out $wifi tcp $LOCK_TCP

open_out $wifi udp $MOUNT_UDP
open_out $wifi tcp $MOUNT_TCP

open_server_from $wifi "{tcp,udp}" $MOUNT_NFS "192.168.10.0/24" 20 "5/10"

# ssh server

open_server_throttle $wifi tcp $MY_SSH 10 "5/10"

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
open_out $vpn udp $NTP

# security

open_out $vpn tcp ssh
open_out $vpn tcp $MY_SSH

# web and email and ftp

open_out $vpn tcp "{ 80 , 443 , 8080 }"
open_out $vpn tcp "{ 25 , 2525 , 587 , 143 , 993 , 465 }"
open_out $vpn tcp ftp

# irc

open_out $vpn tcp "{ 194 , 6697 }"




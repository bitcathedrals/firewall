#! /usr/bin/env bash

pf_firewall=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"
vpn="tun0"

NTP=123
IRC=6667

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

# security

open_out $wifi tcp ssh
open_out $wifi tcp 6666

# VPN

open_out $wifi udp openvpn

# web and email

open_out $wifi tcp "{ 80, 443 , 8080 }"
open_out $wifi tcp "{ 25 , 2525 , 587 , 143 , 993 , 465 }"

# irc

open_out $wifi tcp "{ 194 , $IRC }"

# ssh server

open_server_throttle $wifi tcp 6666 10 "5/10"

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
open_out $vpn tcp 6666

# web and email and ftp

open_out $vpn tcp "{ 80 , 443 , 8080 }"
open_out $vpn tcp "{ 25 , 2525 , 587 , 143 , 993 , 465 }"
open_out $vpn tcp ftp

# irc

open_out $vpn tcp "{ 194 , 6697 }"




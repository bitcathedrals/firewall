#! /usr/bin/env bash

pf_firewall=$HOME/code/firewall/pf/openbsd.sh

wifi="iwx0"
vpn="tun0"

source $pf_firewall

default_policy;

#
# basics for
#

open_icmp $wifi
open_dhcp $wifi

open_out $wifi udp domain
open_out $wifi udp $NTP

open_out $wifi tcp ssh

open_out $wifi udp openvpn

open_server $wifi tcp ssh

open_dhcp $vpn

open_out $wifi tcp "{ 80, 443 , 8080 }"
open_out $wifi tcp "{ 25 , 2525 , 587 , 143 , 993 , 465 }"
# irc
open_out $wifi tcp "{ 194 , 6697 }"

open_out $vpn udp domain
open_out $vpn udp $NTP

open_out $vpn tcp ssh

open_out $vpn tcp "{ 80 , 443 , 8080 }"
open_out $vpn tcp ftp
open_out $vpn tcp "{ 25 , 2525 , 587 , 143 , 993 , 465 }"
# irc
open_out $vpn tcp "{ 194 , 6697 }"




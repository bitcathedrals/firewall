#! /usr/bin/env bash

HOST=`uname -a  | tr -s ' ' | cut -d ' ' -f 2`

echo "firewall.sh: executing for host: $HOST"

if [[ -f $HOME/coding/firewall/pf/$HOST.sh ]]
then
  echo "firewall.sh: generating pf firewall with /home/coding/firewall/pf/$HOST.sh"
  source $HOME/coding/firewall/pf/$HOST.sh
fi

cat <<BASIC
# general
set block policy drop
scrub in all

anchor blacklistd/* in

# loopback
set skip on lo
antispoof for lo

# icmp
pass inet proto icmp keep state

# default deny inbound
block in all
BASIC

if [[ $FIREWALL_OUTBOUND_ALL == "yes" ]]
then
  cat <<OUTBOUND

# allow all outbound traffic
pass out all keep state
OUTBOUND
else
cat <<OUTBOUND

# restrict all outbound traffic
block out all
OUTBOUND
fi

if [[ $FIREWALL_OUTBOUND_DOMAIN == "yes" ]]
then
  cat <<DOMAIN

# allow outbound to domain lookups
pass out proto udp to port domain
DOMAIN
fi

if [[ $FIREWALL_OUTBOUND_ZONE == "yes" ]]
then
  cat <<ZONE

# allow outbound to domain zone transfers
pass out proto tcp to port domain
ZONE
fi

if [[ $FIREWALL_OUTBOUND_SSH == "yes" ]]
then
  cat <<SSH

# allow outbound ssh
pass out proto tcp to port ssh
SSH
fi

if [[ $FIREWALL_OUTBOUND_NTP == "yes" ]]
then
  cat <<NTP

# allow outbound ntp
pass out proto udp to port ntp
NTP
fi

if [[ $FIREWALL_DHCP ==  "yes" ]]
then
  cat <<DHCP
pass out proto udp to port dhcp
pass in proto udp from port dhcp
DHCP
fi

#
# servers
#

if [[ $FIREWALL_SERVER_SSH == "yes" ]]
then
  cat <<SSH

# allow all outbound traffic
pass in proto tcp to port $FIREWALL_SSH_PORT
SSH
fi


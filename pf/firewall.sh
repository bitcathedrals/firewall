#! /usr/bin/env bash

HOST=`uname -a  | tr -s ' ' | cut -d ' ' -f 2`

FIREWALL="$HOME/coding/firewall/pf"
CONFIG="$FIREWALL/${HOST}.sh"

echo >/dev/stderr "firewall.sh: executing for host: $CONFIG"

if [[ -f $CONFIG ]]
then
  source $CONFIG
else
  echo >/dev/stderr "firewall.sh: could not find $CONFIG, exiting 1"
  exit 1
fi

#
# open_client
#
# 1 = enable/disable
# 2 = name
# 3 = origin network
# 4 = proto
# 5 = port

function open_client {
  if [[ $1 == "yes" ]]
  then
    # get the ip from the network portion
    ip=`ifconfig | grep $3 | tr '\t' ' ' | tr -s ' ' | cut -d ' ' -f 3`

    cat <<CLIENT
pass out proto $4 from $ip to any port $5
pass in proto $4 from any port $ip to $ip
CLIENT
fi
}

#
# open_server
#
# 1 = enable/disable
# 2 = name
# 3 = origin network
# 4 = proto
# 5 = port


function open_server {
  if [[ $1 == "yes" ]]
  then
    # get the ip from the network portion
    ip=`ifconfig | grep $3 | tr '\t' ' ' | tr -s ' ' | cut -d ' ' -f 3`

    cat <<SERVER
pass out proto $4 from $ip port $5 to any
pass in proto $4 from any to $ip port $5
SERVER
fi
}

cat <<DEFAULT_POLICY
scrub in all
block in all
DEFAULT_POLICY

cat <<LOOPBACK
pass on lo to 127.0.0.0/8
pass from 127.0.0.0/8 to lo

antispoof for lo
LOOPBACK

cat <<ICMP
pass out proto icmp to any keep state
pass in proto icmp from any
ICMP

if [[ $FIREWALL_BLACKLIST == "yes" ]]
then
  cat <<BLACKLIST
anchor blacklistd/* in
BLACKLIST
fi

if [[ $FIREWALL_OUTBOUND_ALL == "yes" ]]
then
  cat <<OUTBOUND
pass out proto { tcp, udp } keep state
OUTBOUND
else
  cat <<OUTBOUND
block out all proto { tcp, udp }
OUTBOUND
fi

#
# DHCP
#

if [[ $FIREWALL_CLIENT_DHCP ==  "yes" ]]
then
  cat <<DHCP
pass out proto udp to any port { 67, 68 }
pass in proto udp from any port { 67, 68 }
DHCP
fi

#
# clients
#

open_client $FIREWALL_OUTBOUND_DOMAIN \
            DNS \
            $EXTERNAL_NETWORK \
            udp \
            domain

open_client $FIREWALL_OUTBOUND_ZONE \
            domain \
            $EXTERNAL_NETWORK \
            tcp \
            domain

open_client $FIREWALL_OUTBOUND_NTP \
            ntp \
            $EXTERNAL_NETWORK \
            udp \
            ntp
#
# servers
#

open_server $FIREWALL_EXTERNAL_SSH \
            SSH \
            $EXTERNAL_NETWORK \
            tcp \
            $FIREWALL_SSH_PORT

open_server $FIREWALL_INTERNAL_SSH \
            SSH \
            $INTERNAL_NETWORK \
            tcp \
            $FIREWALL_SSH_PORT

open_server $FIREWALL_EXTERNAL_HTTP \
            HTTP:80 \
            $EXTERNAL_NETWORK \
            tcp \
            http

open_server $FIREWALL_INTERNAL_HTTP \
            HTTP:80 \
            $INTERNAL_NETWORK \
            tcp \
            http

open_server $FIREWALL_EXTERNAL_HTTP \
            HTTPS:443 \
            $EXTERNAL_NETWORK \
            tcp \
            https

open_server $FIREWALL_INTERNAL_HTTP \
            HTTPS:443 \
            $INTERNAL_NETWORK \
            tcp \
            https

open_server $FIREWALL_EXTERNAL_HTTP \
            HTTP:8080 \
            $EXTERNAL_NETWORK \
            tcp \
            8080

open_server $FIREWALL_INTERNAL_HTTP \
            HTTP:8080 \
            $INTERNAL_NETWORK \
            tcp \
            8080

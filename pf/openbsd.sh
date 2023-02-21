#! /usr/bin/env bash

NTP=123

#
# default_policy
#

# set default policy for default block, loopback, and icmp out

function default_policy {
  cat <<DEFAULT_POLICY
block drop all

table <blacklist> persist
block quick from <blacklist>

pass on lo to 127.0.0.0/8
pass from 127.0.0.0/8 to lo

antispoof for lo

pass out proto icmp to any keep state
DEFAULT_POLICY
};


#
# open_icmp
#

# open icmp inbound on interface

# $1 = interface

function open_icmp {
  cat <<ICMP
pass in on $1 proto icmp
ICMP
};

#
# open_out
#

# open outbound access

# $1 = interface
# $2 = proto
# $3 = target port

function open_out {
  cat <<CLIENT
pass out on $1 proto $2 from any to any port $3 keep state
CLIENT
};

#
# open_server
#

# open server access from outside

# $1 = interface
# $2 = proto
# $3 = port

function open_server {
  cat <<SERVER
pass in on $1 proto $2 from any to any port $3 keep state
SERVER
};

function open_server_throttle {
  cat <<THROTTLE
pass in on $1 proto $2 from any to any port $3 keep state (max-src-conn $4, max-src-conn-rate $5, overload <blacklist> flush global)
THROTTLE
};

#
# open_dhcp
#

# open dhcp for interface

# $1 = interface

function open_dhcp {
  cat <<DHCP
pass out on $1 proto udp from any to any port { 67, 68 }
pass in on $1 proto udp from any to any port { 67, 68 }
DHCP
};

case $1 in
  "test")
    hostname=`hostname | cut -d . -f 1`
    echo "testing firewall for: $hostname"
    ./${hostname}.sh >${hostname}-test.pf

    pfctl -n -f ${hostname}-test.pf
  ;;
  "update")
    hostname=`hostname | cut -d . -f 1`
    echo "updating firewall for: $hostname"
    ./${hostname}.sh >${hostname}.pf
    doas cp ${hostname}.pf /etc/pf.conf
  ;;
  "flush")
    doas pfctl -F rules
    doas pfctl -F states
  ;;
  "load")
    doas pfctl -f /etc/pf.conf
  ;;
  "enable")
    doas pfctl -e
  ;;
  "enable")
    doas pfctl -d
  ;;
  "rules")
    doas pfctl -P -N -s rules
  ;;
  "stat")
    doas pfctl -P -N -s all
  ;;
  "interfacce")
    doas pfctl -P -N -i $1 -s all
  ;;
  "help")
    cat <<HELP
openbsd.sh firewall

help   = command reference

update    = generate a new firewall
test      = test firewall

flush     = flush rules and state

load      = load the firewall
disable   = disable the firewall
enable    = enable the firewall

rules     = show loaded rules
stat      = show all rules and state
interface = show all rules and state on INTERFACE
HELP
  ;;
esac

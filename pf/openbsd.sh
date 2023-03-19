#! /usr/bin/env bash

# default maximum number of connections for a service
DEFAULT_CON_MAX=100
DEFAULT_RATE_MAX="15/30"

# port assignments
NTP=123
DOMAIN=53

RSYNC=873

LO=`ifconfig | grep lo | head -n 1 | cut -d ':' -f 1`

#
# default_policy
#

# set default policy for default block, loopback, and icmp out

function default_policy {
  cat <<DEFAULT_POLICY
block drop all

table <blacklist> persist
block quick from <blacklist>

pass in on $LO
pass out on $LO

antispoof for $LO

pass out proto icmp to any keep state
DEFAULT_POLICY
};


#
# rpc ports
#

# $1 = host
# $2 = service
# $3 = protocol

function rpc_port {
  rpcinfo -p $1 | grep $2 | grep $3 | head -n 1 | tr -s ' ' | cut -d ' ' -f 5;
}

function rpc_print {
  cat >/dev/stderr <<PORTLIST
rpc ports:

portmap udp = $PORTMAP_UDP tcp = $PORTMAP_TCP
status udp = $STATUS_UDP tcp = $STATUS_TCP
lock udp = $LOCK_UDP tcp = $LOCK_TCP
mount udp = $MOUNT_UDP tcp = $MOUNT_TCP
NFS udp = $NFS_UDP tcp = $NFS_TCP
PORTLIST
}

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
# open_on
#

# open server access from outside

# $1 = interface
# $2 = proto
# $3 = port

function open_on {
  cat <<SERVER
pass in on $1 proto $2 from any to any port $3 keep state
SERVER
};

#
# open_from
#

# $1 = proto
# $2 = port
# $3 = network
# $4 = rate limit
# $5 = max connections

function open_from {
  MAX=$5
  if test -z "$MAX"
  then
    MAX=$DEFAULT_CON_MAX
  fi

  RATE=$4
  if test -z "$RATE"
  then
    RATE=$DEFAULT_RATE_MAX
  fi

  cat <<THROTTLE
pass in proto $1 from $3 to any port $2 keep state (max-src-conn $MAX , max-src-conn-rate $RATE , overload <blacklist> flush global)
THROTTLE
};

#
# block_stealth - return unreachable
#

# $1 interface
# $2 proto
# $3 port
# $4 rate | 10 packets / 30 seconds

function block_stealth {
  RATE=$4

  if test -z "$RATE"
  then
    RATE=$DEFAULT_RATE_MAX
  fi

  cat <<STEALTH

block return-icmp in log (all, to pflog0) on $1 proto $2 from any to any port $3 max-pkt-rate $RATE
block drop in on $1 proto $2 from any to any port $3
STEALTH
}

case $1 in
  "test")
    hostname=`hostname | cut -d . -f 1`
    echo "testing firewall for: $hostname"
    ./${hostname}.sh >${hostname}.pf

    pfctl -n -f ${hostname}.pf
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
  "disable")
    doas pfctl -d
  ;;
  "rules")
    doas pfctl -P -N -s rules
  ;;
  "stat")
    doas pfctl -P -N -s all
  ;;
  "blacklist")
    doas pfctl -t blacklist -T show
  ;;
  "pardon")
    doas pfctl -t blacklist -T flush
  ;;
  "interface")
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
blacklist = show blacklist table
pardon    = flush the blacklist table
interface = show all rules and state on INTERFACE
HELP
  ;;
esac

#! /usr/bin/env bash

# default maximum number of connections for a service
DEFAULT_CON_MAX=100
DEFAULT_RATE_MAX="15/30"

# port assignments
MY_SSH=6666
SSH="{ ssh , sftp , $MY_SSH }"

NTP=123
DOMAIN=53

WEB="{ 80 , 443 , 8080 }"
MAIL="{ 25 , 2525 , 587 , 143 , 993 , 465 }"
FTP="{ ftp , ftp-data }"

RSYNC=873
IRC=6697
RDP=3389

LO=`ifconfig | grep lo | head -n 1 | cut -d ':' -f 1`

#
# lookup the ip address for a host
#

# $1 hostname

function host_lookup {
  nslookup $1 | grep -i address | cut -d ' ' -f 2 | grep -v -i 'address' | tail -n 1;
}

# $1 = address

function broadcast_lookup {
  ifconfig | grep inet | grep $1 | tr -s ' ' | cut -d ' ' -f 6
}

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
# in_icmp
#

# open icmp inbound on interface

# $1 = address

function in_icmp {
  cat <<ICMP
pass in proto icmp to $1 keep state
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
# inbound
#

# $1 = address
# $2 = proto
# $3 = port

function inbound {
  cat <<SERVER
pass in proto $2 from any to $1 port $3 keep state
SERVER
};

#
# in_from
#

# $1 = my ip
# $2 = protocol
# $3 = port
# $4 = address
# $5 = rate limit
# $6 = max connections

function in_from {
  RATE=$5
  if test -z "$RATE"
  then
    RATE=$DEFAULT_RATE_MAX
  fi

  MAX=$6
  if test -z "$MAX"
  then
    MAX=$DEFAULT_CON_MAX
  fi

  cat <<THROTTLE
pass in proto $2 from $4 to $1 port $3 keep state (max-src-conn $MAX , max-src-conn-rate $RATE , overload <blacklist> flush global)
THROTTLE
};


#
# outbound
#

# open outbound traffic

# $1 = my address
# $2 = protocol
# $3 = target port

function outbound {
  cat <<CLIENT
pass out proto $2 from $1 to any port $3 keep state
CLIENT
};

#
# open to a specific host
#

# $1 = my address
# $2 = protocol
# $3 = port
# $4 = dest host

function out_to {
  cat <<CLIENT
pass out proto $2 from $1 to $4 port $3 keep state
CLIENT
};

#
# open_trusted - open trusted services
#

# $1 my address

function open_trusted {
  in_icmp $1
  outbound $1 "{ udp , tcp }" domain

  outbound $1 tcp "$SSH"
};

#
# open_router - assume internet connection
#

function open_router {
  open_dhcp $1
  outbound $1 udp $NTP
};

#
# block_stealth - return unreachable
#

# $1 my address
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

block return-icmp in log (all, to pflog0) proto $2 from any to $1 port $3 max-pkt-rate $RATE
block drop in proto $2 from any to $1 port $3
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

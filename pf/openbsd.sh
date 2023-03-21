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
pass in on $1 proto icmp keep state
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
# open to a specific host
#

#
# open to a specific host
#

function open_to {
  cat <<CLIENT
pass out proto $2 from any to $1 port $3 keep state
CLIENT
};


#
# open_in
#

# open server access from outside

# $1 = interface
# $2 = proto
# $3 = port

function open_in {
  cat <<SERVER
pass in on $1 proto $2 from any to any port $3 keep state
SERVER
};

#
# open_from
#

# $1 = proto
# $2 = port
# $3 = my ip
# $4 = network
# $5 = rate limit
# $6 = max connections

function open_from {
  MAX=$6
  if test -z "$MAX"
  then
    MAX=$DEFAULT_CON_MAX
  fi

  RATE=$5
  if test -z "$RATE"
  then
    RATE=$DEFAULT_RATE_MAX
  fi

  cat <<THROTTLE
pass in proto $1 from $4 to $3 port $2 keep state (max-src-conn $MAX , max-src-conn-rate $RATE , overload <blacklist> flush global)
THROTTLE
};

#
# open standard trusted services
#

# $1 interface

function open_trusted {
  open_icmp $1
  open_out $1 "{ udp , tcp }" domain

  open_out $1 tcp "$SSH"
};

function open_router {
  open_dhcp $1
  open_out $1 udp $NTP
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

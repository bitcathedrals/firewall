#! /usr/bin/env bash

HOSTNAME=`hostname | cut -d . -f 1`

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

HTTPD="80"

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

# $1 macro name
# $2 macro value
function macro {
  echo "$1 = \"$2\"" >>${HOSTNAME}.pf
  echo "MACRO $1 = $2" >/dev/stderr
};


# $1 macro name
# $2 hostname
function macro_host {
  ip=`host_lookup $2`
  echo "$1 = \"$ip\"" >>${HOSTNAME}.pf
  echo "MACRO $1 = $ip" >/dev/stderr
};

# $1 = name
# $2 = self hostname
# $3 = subnet

function macro_network {
  ip=`host_lookup $2`
  broadcast=`broadcast_lookup $ip`

  cat >>${HOSTNAME}.pf <<NETWORK
${1}Net = "$3"
${1}IP = "$ip"
${1}Brd = "$broadcast"
NETWORK

  echo "$1 = $3" >/dev/stderr
  echo "${1}IP = $ip" >/dev/stderr
  echo "${1}Brd = $broadcast" >/dev/stderr;
}

# $1 = host
# $2 = service
# $3 = protocol

function rpc_port {
  rpcinfo -p $1 | grep $2 | grep $3 | head -n 1 | tr -s ' ' | cut -d ' ' -f 5;
}

# $1 = host

function rpc_map {
  PORTMAP_UDP=`rpc_port $1 portmapper udp`
  PORTMAP_TCP=`rpc_port $1 portmapper tcp`

  STATUS_UDP=`rpc_port $1 status udp`
  STATUS_TCP=`rpc_port $1 status tcp`

  LOCK_UDP=`rpc_port $1 nlockmgr udp`
  LOCK_TCP=`rpc_port $1 nlockmgr tcp`

  MOUNT_UDP=`rpc_port $1 mountd udp`
  MOUNT_TCP=`rpc_port $1 mountd tcp`

  NFS_UDP=`rpc_port $1 nfs udp`
  NFS_TCP=`rpc_port $1 nfs tcp`

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
# default_policy
#

# set default policy for default block, loopback, and icmp out

function default_policy {
  cat >>${HOSTNAME}.pf <<DEFAULT_POLICY
set syncookies adaptive
match in all scrub (no-df,random-id)

block drop all

table <blacklist> persist
block quick from <blacklist>

pass in on $LO
pass out on $LO
antispoof for $LO

pass out inet proto icmp keep state
pass in inet proto icmp icmp-type {unreach,althost,routeradv,routersol,timex,paramprob,dataconv,mobredir,mobregreq,mobregrep} keep state
DEFAULT_POLICY
};

# pass in inet proto icmp icmp-type {squench}

#
# risky_icmp
#

# open icmp inbound on a risky interface

# $1 = address
# $2 = broadcast address

function risky_icmp {
  cat >>${HOSTNAME}.pf <<ICMP
block drop in inet proto icmp to $1 icmp-type {redir,althost}
ICMP
}


#
# trusted_icmp
#

# open icmp inbound on a safe interface

# $1 = address
# $2 = broadcast address

function trusted_icmp {
  cat >>${HOSTNAME}.pf <<ICMP
pass in inet proto icmp to $1 icmp-type {echoreq,trace} keep state
ICMP
};

#
# inbound
#

# $1 = address
# $2 = proto
# $3 = port

function inbound {
  cat >>${HOSTNAME}.pf <<SERVER
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

  cat >>${HOSTNAME}.pf <<THROTTLE
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
  if [[ $2 == "tcp" ]]
  then
    STATE="modulate"
  else
    STATE="keep"
  fi

  cat >>${HOSTNAME}.pf <<CLIENT
pass out proto $2 from $1 to any port $3 $STATE state
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
  if [[ $2 == "tcp" ]]
  then
    STATE="modulate"
  else
    STATE="keep"
  fi

  cat >>${HOSTNAME}.pf <<CLIENT
pass out proto $2 from $1 to $4 port $3 $STATE state
CLIENT
};

#
# open_dhcp
#

# open dhcp for interface

# $1 = interface

function open_dhcp {
  cat >>${HOSTNAME}.pf <<DHCP
pass out on $1 proto udp from any to any port { 67, 68 }
pass in on $1 proto udp from any to any port { 67, 68 }
DHCP
};

#
# open basic protocols on a risky interface
#

# $1 my address
# $2 broadcast address

function open_risky {
  risky_icmp $1
  outbound $1 tcp "$SSH"
}

#
# open_trusted - open basic protocols on a trusted interface
#

# $1 my address
# $2 broadcast address

function open_trusted {
  trusted_icmp $1
  outbound $1 tcp "$SSH"
};

#
# open_router - assume internet connection
#

# $1 my address
# $2 dhcp inteface - optional

function open_router {
  outbound $1 udp $NTP

  if [[ -n "$2" ]]
  then
    open_dhcp $2
  fi;

  outbound $1 "{ udp , tcp }" domain
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

  cat >>${HOSTNAME}.pf <<STEALTH
block return-icmp in log (all, to pflog0) proto $2 from any to $1 port $3 max-pkt-rate $RATE
block drop in proto $2 from any to $1 port $3
STEALTH
}

case $1 in
  "test")
    test -f ${HOSTNAME}.pf && rm ${HOSTNAME}.pf
    source ${HOSTNAME}.sh
    pfctl -n -f ${HOSTNAME}.pf
  ;;
  "update")
    test -f ${HOSTNAME}.pf && rm ${HOSTNAME}.pf
    source ${HOSTNAME}.sh
    doas cp ${HOSTNAME}.pf /etc/pf.conf
  ;;
  "flush")
    doas pfctl -F rules
  ;;
  "forget")
    doas pfctl -F states
  ;;
  "dev")
    doas pfctl -f ${HOSTNAME}.pf
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
  "help"|*)
    cat <<HELP
openbsd.sh firewall

help   = command reference

test      = test firewall
update    = generate a new firewall

flush     = flush rules
forget    = flush states

dev       = load development rules
load      = load system rules

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

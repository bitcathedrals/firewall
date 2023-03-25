#! /usr/bin/env bash

#
# load system configuration and then development configuration
#

HOST=`uname -a  | tr -s ' ' | cut -d ' ' -f 2`

SYS_CONFIG=/etc/firewall/$HOST.sh
CUR_CONFIG=$HOST.sh

echo "firewall.sh: executing for host: $HOST"

function rule {
  if [[ ${DEBUG} == "yes" ]]
  then
    echo "debug: $*"
  fi

  eval "doas iptables $*"

  if [[ $? -ne 0 ]]
  then
    echo "error: $*"
  fi;
};

function open_policy {
  rule -P INPUT ACCEPT
  rule -P OUTPUT ACCEPT
  rule -P FORWARD ACCEPT;
};

function close_policy {
  rule -P INPUT DROP
  rule -P OUTPUT DROP
  rule -P FORWARD DROP;
};

function icmp_core {
  #
  # pass connection related
  #

  rule -A icmp_traffic_in  -p icmp -i $1 -m state --state RELATED  -j ACCEPT
  rule -A icmp_traffic_out -p icmp -i $1 -m state --state RELATED  -j ACCEPT;

  #
  # allow outbound ping
  #

  rule -A icmp_traffic_out -p icmp -o $1 --icmp-type echo-request -j ACCEPT
  rule -A icmp_traffic_out -p icmp -o $1 --icmp-type echo-reply -j ACCEPT;
};


function icmp_block_broadcast {
  #
  # drop all broadcast traffic
  #

  rule  -A icmp_filter_in -p icmp -i $1 -m pkttype --pkt-type broadcast -m limit --limit 24\/minute -j NFLOG --nflog-group 2  --nflog-prefix "\"firewall: ICMP broadcast!\""
  rule  -A icmp_filter_in -p icmp -i $1 -m pkttype --pkt-type broadcast -j DROP
};

function icmp_block_strange {
  #
  # log odd ICMP
  #

  rule -A icmp_filter_in -p icmp -i $1 --icmp-type timestamp-request -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix="\"firewall: ICMP strange\""
  rule -A icmp_filter_in -p icmp -i $1 --icmp-type timestamp-reply -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix="\"firewall: ICMP strange\""
  rule -A icmp_filter_in -p icmp -i $1 --icmp-type address-mask-request -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix="\"firewall: ICMP strange\""
  rule -A icmp_filter_in -p icmp -i $1 --icmp-type address-mask-reply -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix="\"firewall: ICMP strange\""

  #
  # drop odd ICMP
  #

  rule -A icmp_filter_in  -p icmp -i $1 --icmp-type timestamp-request -j DROP
  rule -A icmp_filter_in  -p icmp -i $1 --icmp-type timestamp-reply -j DROP
  rule -A icmp_filter_in  -p icmp -i $1 --icmp-type address-mask-request -j DROP
  rule -A icmp_filter_out -p icmp -o $1 --icmp-type address-mask-reply -j DROP;
};

function icmp_ping_throttle {
  rule -A icmp_traffic_in -p icmp -i $1 --icmp-type echo-request -m limit --limit 8\/second --limit-burst 24 -j ACCEPT
  rule -A icmp_traffic_in -p icmp -i $1 --icmp-type echo-reply -m limit --limit 8\/second --limit-burst 24 -j ACCEPT

  rule -A icmp_traffic_in -p icmp -i $1 --icmp-type echo-request -j DROP
  rule -A icmp_traffic_in -p icmp -i $1 --icmp-type echo-request -j DROP;
};

function icmp_ping_block {
  rule -A icmp_filter_in -p icmp -i $1 --icmp-type echo-reply  -j DROP
  rule -A icmp_filter_in -p icmp -i $1 --icmp-type echo-request  -j DROP;
};

function tcp_core {
  #
  # tcp connection state
  #

  rule -A tcp_con_in -p tcp -i $1 -m state --state ESTABLISHED -j ACCEPT
  rule -A tcp_con_out -p tcp -o $1 -m state --state ESTABLISHED -j ACCEPT

  rule -A tcp_con_in -p tcp -i $1  -m state --state RELATED -j ACCEPT
  rule -A tcp_con_out -p tcp -o $1 -m state --state RELATED -j ACCEPT

  rule -A tcp_con_in -p tcp -i $1 -m conntrack --ctstatus SEEN_REPLY --tcp-flags SYN,ACK,FIN,RST ACK,SYN -j ACCEPT

  rule -A tcp_con_in -p tcp -i $1 --tcp-flags RST RST -j ACCEPT
  rule -A tcp_con_out -p tcp -o $1 --tcp-flags RST RST -j ACCEPT

  rule -A tcp_con_in -p tcp -i $1 --tcp-flags ACK ACK -j ACCEPT
  rule -A tcp_con_out -p tcp -o $1 --tcp-flags ACK ACK -j ACCEPT;
};

function tcp_any_out {
  rule -A tcp_con_out -p tcp -o $1 -m state --state NEW -j ACCEPT;
};

function tcp_drop_broadcast {
  #
  # disable tcp broadcast.
  #

  rule -A tcp_filter_in -p tcp -i $1 -m pkttype --pkt-type broadcast -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix "\"firewall: TCP broadcast drop\""
  rule -A tcp_filter_in -p tcp -i $1 -m pkttype --pkt-type broadcast -j DROP;
};

function udp_core {
  rule -A udp_con_in -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT
  rule -A udp_con_out -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT
};

function udp_drop_broadcast {
  rule -A udp_filter_in -p udp -i $1  -m pkttype --pkt-type broadcast -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix "\"firewall: UDP broadcast drop\""
  rule -A udp_filter_in -p udp -i $1 -m pkttype --pkt-type broadcast -j DROP;
};

function udp_any_out {
  rule -A udp_con_out -p udp -o $1 -m state --state NEW -j ACCEPT
};

function open_dhcp {
  rule -A udp_con_out -p udp -o $1 --dport 67 -j ACCEPT
  rule -A udp_con_in -p udp -i $1  --sport 67 -m pkttype --pkt-type broadcast -j ACCEPT;
};

function open_udp_out {
  rule -A udp_con_out -p udp -d $1 --dport $2 -m state --state NEW -j ACCEPT;
};

function open_tcp_out {
  rule -A tcp_con_out -p tcp -d $1 --dport $2 -m state --state NEW -j ACCEPT;
};

# $1 = source address/network
# $2 = port
# $3 = maximum connections

function open_udp_server {
  rule -A udp_filter_in -p udp -s $1 --match multiport --dports $2 -m state --state NEW -m connlimit --connlimit-above $3 -j NFLOG --nflog-group 3 --nflog-prefix "\"firewall: $1:$2 connections  exceeded limit\""
  rule -A udp_filter_in -p udp -s $1 --match multiport --dports $2 -m state --state NEW -m connlimit --connlimit-above $3 -j DROP

  rule -A udp_srv_in -p tcp -s $1 --match multiport --dports $2 -m state --state NEW -j ACCEPT
}

# $1 = source address/network
# $2 = port
# $3 = maximum connection limit

function open_tcp_server {
  rule -A tcp_filter_in -p tcp -s $1 --match multiport --dports $2 -m state --state NEW -m connlimit --connlimit-above $3 -j NFLOG --nflog-group 3 --nflog-prefix "\"firewall: $1:$2 connections  exceeded limit\""
  rule -A tcp_filter_in -p tcp -s $1 --match multiport --dports $2 -m state --state NEW -m connlimit --connlimit-above $3 -j DROP

  rule -A tcp_srv_in -p tcp -s $1 --match multiport --dports $2 -m state --state NEW -j ACCEPT
}

# $1 = source address network
# $2 = destination port

function stealth_udp_block {
  rule -I udp_filter_in -p udp -s $1 --dport $2 -j REJECT --reject-with icmp-host-unreachable;
}

# $1 = source address network
# $2 = destination port

function stealth_tcp_block {
  rule -I tcp_filter_in -p tcp -s $1 --dport $2 -j REJECT --reject-with icmp-host-unreachable;
}

function set_sys {
  doas sysctl ${1}="${2}"
};

function nat {
  set_sys net.ipv4.ip_forward 1

  rule -t nat -A POSTROUTING  -o $1  -j MASQUERADE

  rule -A FORWARD -i $1 -j ACCEPT
  rule -A FORWARD -o $1 -j ACCEPT;
};

function configure_system {
  set_sys net.ipv4.tcp_ecn 1
  set_sys net.ipv4.tcp_ecn 1
  set_sys net.ipv4.tcp_sack 1
  set_sys net.ipv4.tcp_window_scaling 1
  set_sys net.ipv4.tcp_syncookies 1
  set_sys net.ipv4.conf.all.accept_source_route 0
  set_sys net.ipv4.conf.all.accept_redirects 0
  set_sys net.ipv4.conf.all.log_martians 1
  set_sys net.ipv4.ip_local_port_range "10000 65000"
  set_sys net.ipv4.conf.all.arp_ignore 1
  set_sys net.ipv4.ip_default_ttl 97
};

case $1 in
  "open")
    open_policy
  ;;
  "close")
    close_policy
  ;;
  "init")
    #
    # system configuration
    #

    configure_system

    #
    # loopback
    #

    rule -A INPUT -i lo -j ACCEPT
    rule -A OUTPUT -o lo -j ACCEPT

    #
    # icmp protocol
    #

    rule -N icmp_filter_in
    rule -N icmp_filter_out

    rule -N icmp_traffic_in
    rule -N icmp_traffic_out

    rule -A INPUT  -p icmp -j icmp_filter_in
    rule -A OUTPUT -p icmp -j icmp_filter_out

    rule -A INPUT  -p icmp -j icmp_traffic_in
    rule -A OUTPUT -p icmp -j icmp_traffic_out

    rule -A INPUT -p icmp -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix "\"firewall: ICMP no matching rule\""
    rule -A INPUT -p icmp -j DROP

    rule -A OUTPUT -p icmp -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix "\"firewall: ICMP no matching rule\""
    rule -A OUTPUT -p icmp -j DROP

    #
    # tcp protocol
    #

    rule -N tcp_filter_in
    rule -N tcp_filter_out

    rule -A INPUT   -p tcp -j tcp_filter_in
    rule -A OUTPUT  -p tcp -j tcp_filter_out

    rule -N tcp_con_in
    rule -N tcp_con_out

    rule -A INPUT   -p tcp -j tcp_con_in
    rule -A OUTPUT  -p tcp -j tcp_con_out

    rule -N tcp_srv_in
    rule -N tcp_srv_out

    rule -A INPUT   -p tcp -j tcp_srv_in
    rule -A OUTPUT  -p tcp -j tcp_srv_out

    rule -A INPUT -p tcp -i $1 -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix "\"firewall: TCP no matching rule\""
    rule -A INPUT -p tcp -i $1 -j DROP

    rule -A OUTPUT -p tcp -o $1 -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix "\"firewall: TCP no matching rule\""
    rule -A OUTPUT -p tcp -o $1 -j DROP

    #
    # udp protocol
    #

    rule -N udp_filter_in
    rule -N udp_filter_out

    rule -A INPUT   -p udp -j udp_filter_in
    rule -A OUTPUT  -p udp -j udp_filter_out

    rule -N udp_con_in
    rule -N udp_con_out

    rule -A INPUT   -p udp -j udp_con_in
    rule -A OUTPUT  -p udp -j udp_con_out

    rule -N udp_srv_in
    rule -N udp_srv_out

    rule -A INPUT   -p udp -j udp_srv_in
    rule -A OUTPUT  -p udp -j udp_srv_out

    rule -A INPUT -p udp -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix "\"firewall: UDP no matching rule\""
    rule -A INPUT -p udp -j DROP

    rule -A OUTPUT -p udp -m limit --limit 24\/minute -j NFLOG --nflog-group 2 --nflog-prefix "\"firewall: UDP no matching rule\""
    rule -A OUTPUT -p udp -j DROP
  ;;
  "delete")
    rule -X icmp_filter_in
    rule -X icmp_filter_out
    rule -X icmp_traffic_in
    rule -X icmp_traffic_out

    rule -X tcp_filter_in
    rule -X tcp_filter_out
    rule -X tcp_con_in
    rule -X tcp_con_out
    rule -X tcp_srv_in
    rule -X tcp_srv_out

    rule -X udp_filter_in
    rule -X udp_filter_out
    rule -X udp_con_in
    rule -X udp_con_out
    rule -X udp_srv_in
    rule -X udp_srv_out
  ;;
  "flush")
    rule -t nat -F POSTROUTING
    rule -t nat -Z POSTROUTING
    rule -t nat -F PREROUTING
    rule -t nat -Z PREROUTING

    rule -F icmp_filter_in
    rule -Z icmp_filter_in
    rule -F icmp_filter_out
    rule -Z icmp_filter_out
    rule -F icmp_traffic_in
    rule -Z icmp_traffic_in
    rule -F icmp_traffic_out
    rule -Z icmp_traffic_out

    rule -F tcp_filter_in
    rule -Z tcp_filter_in
    rule -F tcp_filter_out
    rule -Z tcp_filter_out
    rule -F tcp_con_in
    rule -Z tcp_con_in
    rule -F tcp_con_out
    rule -Z tcp_con_out
    rule -F tcp_srv_in
    rule -Z tcp_srv_in
    rule -F tcp_srv_out
    rule -Z tcp_srv_out

    rule -F udp_filter_in
    rule -Z udp_filter_in
    rule -F udp_filter_out
    rule -Z udp_filter_out
    rule -F udp_con_in
    rule -Z udp_con_in
    rule -F udp_con_out
    rule -Z udp_con_out
    rule -F udp_srv_in
    rule -Z udp_srv_in
    rule -F udp_srv_out
    rule -Z udp_srv_out
  ;;
  "load")
    #
    # load the config
    #

    if [[ -f $SYS_CONFIG ]]
    then
      echo "firewall.sh: loading system configuration: $CONFIG"
      source $SYS_CONFIG
    fi
  ;;
  "dev")
    #
    # load the config
    #

    if [[ -f $CUR_CONFIG ]]
    then
      echo "firewall.sh: loading development configuration: $CONFIG"
      source $CUR_CONFIG
    fi
  ;;
  "reload")
    $0 flush
    $0 load
  ;;
  "start")
    $0 init
    $0 load
    $0 close
  ;;
  "stop")
    $0 flush
    $0 delete
    $0 open
  ;;
  "rules")
    doas iptables -v --list
  ;;
  "install")
    test -d /etc/firewall || doas mkdir -p /etc/firewall
    doas cp $CUR_CONFIG $SYS_CONFIG
    doas cp iptables.sh /etc/firewall/iptables.sh
    doas cp firewall.service /lib/systemd/system/
    doas systemctl daemon-reload
    doas systemctl enable firewall.service
  ;;
  "help"|*)
    cat <<HELP
firewall.sh
open   = default ACCEPT policy
close  = default DROP policy

init   = initialize the kernel and chains

flush  = flush chains
load   = load the system rules
reload = re-initialize the firewall

dev    = load development rules
rules  = list loaded rules

start  = init, load, and set close policy
stop   = flush, delete, and set open policy
HELP
  ;;
esac


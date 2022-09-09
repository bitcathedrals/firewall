#! /usr/bin/env bash

#
# load system configuration and then development configuration
#

HOST=`uname -a  | tr -s ' ' | cut -d ' ' -f 2`

echo "firewall.sh: executing for host: $HOST"

if [[ -f /etc/firewall/$HOST.sh ]]
then
  echo "firewall.sh: configuring with /etc/firewall/$HOST.sh"
  source /etc/firewall/$HOST.sh ]]
fi

if [[ -f $HOME/coding/firewall/iptables/$HOST.sh ]]
then
  echo "firewall.sh: configuring with /home/coding/firewall/iptables/$HOST.sh"
  source $HOME/coding/firewall/iptables/$HOST.sh
fi

function rule {
  if [[ ${DEBUG} == "yes" ]]
  then
    echo "debug: $*"
  fi

  eval "iptables $*"

  if [[ $? -ne 0 ]]
  then
    echo "error: $*"
  fi;
}

case $1 in
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
    rule  -F INPUT
    rule  -Z INPUT
    rule  -F OUTPUT
    rule  -Z OUTPUT
    rule  -F FORWARD
    rule  -Z FORWARD
    rule  -t nat  -F POSTROUTING
    rule  -t nat  -Z POSTROUTING
    rule  -t nat  -F PREROUTING
    rule  -t nat  -Z PREROUTING
    rule  -F icmp_filter_in
    rule  -Z icmp_filter_in
    rule  -F icmp_filter_out
    rule  -Z icmp_filter_out
    rule  -F icmp_traffic_in
    rule  -Z icmp_traffic_in
    rule  -F icmp_traffic_out
    rule  -Z icmp_traffic_out
    rule  -F tcp_filter_in
    rule  -Z tcp_filter_in
    rule  -F tcp_filter_out
    rule  -Z tcp_filter_out
    rule  -F tcp_con_in
    rule  -Z tcp_con_in
    rule  -F tcp_con_out
    rule  -Z tcp_con_out
    rule  -F tcp_srv_in
    rule  -Z tcp_srv_in
    rule  -F tcp_srv_out
    rule  -Z tcp_srv_out
    rule  -F udp_filter_in
    rule  -Z udp_filter_in
    rule  -F udp_filter_out
    rule  -Z udp_filter_out
    rule  -F udp_con_in
    rule  -Z udp_con_in
    rule  -F udp_con_out
    rule  -Z udp_con_out
    rule  -F udp_srv_in
    rule  -Z udp_srv_in
    rule  -F udp_srv_out
    rule  -Z udp_srv_out
  ;;
  "open")
    rule -P INPUT ACCEPT
    rule -P OUTPUT ACCEPT
    rule -P FORWARD ACCEPT
  ;;
  "load")
    rule -P INPUT DROP
    rule -P OUTPUT DROP
    rule -P FORWARD DROP

    #
    # system configuratino
    #

    sysctl net.ipv4.tcp_ecn="1"
    sysctl net.ipv4.tcp_ecn="1"
    sysctl net.ipv4.tcp_sack="1"
    sysctl net.ipv4.tcp_window_scaling="1"
    sysctl net.ipv4.tcp_syncookies="1"
    sysctl net.ipv4.conf.all.accept_source_route="0"
    sysctl net.ipv4.conf.all.accept_redirects="0"
    sysctl net.ipv4.conf.all.log_martians="1"
    sysctl net.ipv4.ip_local_port_range="10000 65000"
    sysctl net.ipv4.conf.all.arp_ignore="1"
    sysctl net.ipv4.ip_default_ttl="97"

    #
    # loopback
    #

    rule  -A INPUT -i lo -j ACCEPT
    rule  -A OUTPUT -o lo -j ACCEPT

    rule  -A INPUT  -i $EXTERNAL_INTERFACE  -s $LOOPBACK_NETMASK  -j NFLOG --nflog-group 2  --nflog-prefix "\"firewall: spoof attempt\""
    rule  -A INPUT  -i $EXTERNAL_INTERFACE  -s $LOOPBACK_NETMASK  -j DROP

    #
    # icmp
    #

    rule -N icmp_filter_in
    rule -N icmp_filter_out

    rule -N icmp_traffic_in
    rule -N icmp_traffic_out

    rule  -A INPUT  -p icmp -j icmp_filter_in
    rule  -A OUTPUT -p icmp -j icmp_filter_out

    rule  -A INPUT  -p icmp -j icmp_traffic_in
    rule  -A OUTPUT -p icmp -j icmp_traffic_out

    #
    # drop all broadcast traffic
    #

    rule  -A icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "\"firewall: ICMP broadcast!\""
    rule  -A icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "\"firewall: ICMP broadcast!\""
    rule  -A icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -j DROP
    rule  -A icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -j DROP

    #
    # filter odd stuff
    #

    rule  -A icmp_filter_in  -p icmp  --icmp-type timestamp-request  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="\"firewall: ICMP strange\""
    rule  -A icmp_filter_in  -p icmp  --icmp-type timestamp-reply  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="\"firewall: ICMP strange\""
    rule  -A icmp_filter_in  -p icmp  --icmp-type address-mask-request  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="\"firewall: ICMP strange\""
    rule  -A icmp_filter_out -p icmp  --icmp-type address-mask-reply  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="\"firewall: ICMP strange\""

    rule  -A icmp_filter_in  -p icmp  --icmp-type timestamp-request  -j DROP
    rule  -A icmp_filter_in  -p icmp  --icmp-type timestamp-reply  -j DROP
    rule  -A icmp_filter_in  -p icmp  --icmp-type address-mask-request  -j DROP
    rule  -A icmp_filter_out -p icmp  --icmp-type address-mask-reply  -j DROP

    #
    # ping handling with throttling
    #

    if [[ -z "$FIREWALL_PING_STEALTH" ]]
    then
      rule  -A icmp_traffic_in  -p icmp  --icmp-type echo-request  -m limit --limit 8\/second --limit-burst 24  -j ACCEPT
      rule  -A icmp_traffic_in  -p icmp  --icmp-type echo-reply  -m limit --limit 8\/second --limit-burst 24 -j ACCEPT
    fi

    rule  -A icmp_traffic_out -p icmp  --icmp-type echo-request  -j ACCEPT
    rule  -A icmp_traffic_out -p icmp  --icmp-type echo-reply  -j ACCEPT

    rule  -A icmp_traffic_in  -p icmp  --icmp-type echo-request  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "\"firewall: ICMP high rate\""

    rule  -A icmp_traffic_in  -p icmp  --icmp-type echo-reply  -j DROP
    rule  -A icmp_traffic_in  -p icmp  --icmp-type echo-request  -j DROP

    rule  -A icmp_traffic_in  -p icmp  -m state --state RELATED  -j ACCEPT
    rule  -A icmp_traffic_out -p icmp  -m state --state RELATED  -j ACCEPT

    rule  -A INPUT  -p icmp  -j DROP
    rule -A OUTPUT -p icmp -j DROP

    #
    # tcp protocol
    #

    rule -N tcp_filter_in
    rule -N tcp_filter_out
    rule  -A INPUT   -p tcp -j tcp_filter_in
    rule  -A OUTPUT  -p tcp -j tcp_filter_out
    rule -N tcp_con_in
    rule -N tcp_con_out
    rule  -A INPUT   -p tcp -j tcp_con_in
    rule  -A OUTPUT  -p tcp -j tcp_con_out
    rule -N tcp_srv_in
    rule -N tcp_srv_out
    rule  -A INPUT   -p tcp -j tcp_srv_in
    rule  -A OUTPUT  -p tcp -j tcp_srv_out

    #
    # tcp core connection
    #

    rule  -A tcp_con_in -p tcp  -m state --state ESTABLISHED  -j ACCEPT
    rule  -A tcp_con_out -p tcp  -m state --state ESTABLISHED  -j ACCEPT

    rule  -A tcp_con_in -p tcp  -m state --state RELATED  -j ACCEPT
    rule  -A tcp_con_out -p tcp  -m state --state RELATED  -j ACCEPT

    rule  -A tcp_con_in -p tcp  -m conntrack --ctstatus SEEN_REPLY  --tcp-flags SYN,ACK,FIN,RST ACK,SYN  -j ACCEPT

    rule  -A tcp_con_in -p tcp  --tcp-flags RST RST  -j ACCEPT
    rule  -A tcp_con_out -p tcp  --tcp-flags RST RST  -j ACCEPT
    rule  -A tcp_con_in -p tcp  --tcp-flags ACK ACK  -j ACCEPT
    rule  -A tcp_con_out -p tcp  --tcp-flags ACK ACK  -j ACCEPT

    #
    # disable tcp broadcast.
    #

    rule  -A INPUT   -p tcp -m pkttype --pkt-type broadcast -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "\"firewall: TCP broadcast drop\""
    rule  -A INPUT   -p tcp -m pkttype --pkt-type broadcast  -j DROP

    rule  -A OUTPUT  -p tcp -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "\"firewall: TCP no matching rule\""
    rule  -A INPUT   -p tcp -j DROP

    #
    # udp protocol
    #

    rule -N udp_filter_in
    rule -N udp_filter_out

    rule  -A INPUT   -p udp -j udp_filter_in
    rule  -A OUTPUT  -p udp -j udp_filter_out

    rule -N udp_con_in
    rule -N udp_con_out

    rule  -A INPUT   -p udp -j udp_con_in
    rule  -A OUTPUT  -p udp -j udp_con_out

    rule -N udp_srv_in
    rule -N udp_srv_out

    rule  -A INPUT   -p udp -j udp_srv_in
    rule  -A OUTPUT  -p udp -j udp_srv_out

    rule  -A udp_con_in -p udp  -m state --state ESTABLISHED,RELATED  -j ACCEPT
    rule  -A udp_con_out -p udp  -m state --state ESTABLISHED,RELATED  -j ACCEPT

    if [[ "$FIREWALL_OUTBOUND_ALL" == "yes" ]]
    then
      rule  -A udp_con_out -p udp -m state --state  NEW  -j ACCEPT
      rule  -A tcp_con_out -p tcp -m state --state  NEW  -j ACCEPT
    fi

    #
    # DROP all UDP broadcast
    #
    rule  -A INPUT   -p udp  -m pkttype --pkt-type broadcast -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "\"firewall: UDP broadcast drop\"" -j DROP
    rule  -A INPUT   -p udp  -m pkttype --pkt-type broadcast  -j DROP

    rule  -A INPUT   -p udp  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "\"firewall: UDP no rule for packet\""
    rule  -A INPUT   -p udp  -j DROP

    #
    # clients
    #

    if [[ "$FIREWALL_CLIENT_DHCP" == "yes" ]]
    then
      rule  -A udp_filter_in -p udp  -i $EXTERNAL_INTERFACE  -s 0.0.0.0  --sport 67  -m pkttype --pkt-type broadcast  -j DROP
      rule  -A udp_con_out -p udp  -o $EXTERNAL_INTERFACE  --dport 67  -j ACCEPT
      rule  -A udp_con_in -p udp  -i $EXTERNAL_INTERFACE  ! -s 0.0.0.0  --sport 67  -m pkttype --pkt-type broadcast  -j ACCEPT
    fi

    if [[ "$FIREWALL_CLIENT_DOMAIN" == "yes" ]]
    then
      rule  -A udp_con_out -p udp  --dport domain  -m state --state NEW -j ACCEPT
      rule  -A tcp_con_out -p tcp  --dport domain  -m state --state NEW -j ACCEPT
    fi

    if [[ "$FIREWALL_CLIENT_NTP" == "yes" ]]
    then
      rule  -A udp_con_out -p udp  --dport ntp  -m state --state NEW -j ACCEPT
      rule  -A tcp_con_out -p tcp  --dport ntp  -m state --state NEW -j ACCEPT
    fi

    if [[ "$FIREWALL_CLIENT_HTTP" == "yes" ]]
    then
      rule  -A tcp_con_out -p tcp  --dport http  -m state --state NEW -j ACCEPT
    fi

    if [[ "$FIREWALL_CLIENT_SSL" == "yes" ]]
    then
      rule  -A tcp_con_out -p tcp  --dport https  -m state --state NEW -j ACCEPT
    fi

    #
    # servers
    #

    if [[ "$FIREWALL_SERVER_SSH" == "yes" ]]
    then
      rule  -A tcp_filter_in -p tcp  --dport $FIREWALL_SSH_PORT  -m connlimit --connlimit-above $FIREWALL_SSH_CAP  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "\"firewall: SSH exceeded connection limit\""
      rule  -A tcp_filter_in -p tcp  --dport $FIREWALL_SSH_PORT  -m state --state NEW  -m connlimit --connlimit-above $FIREWALL_SSH_CAP  -j DROP
      rule  -A tcp_srv_in -p tcp  --dport $FIREWALL_SSH_PORT  -m state --state NEW -j ACCEPT

      if [[ -n $FIREWALL_SSH_PORT ]]
      then
        rule -A tcp_filter_in -p tcp --dport ssh -m state --state NEW -j NFLOG --nflog-gropu 3 --nflog-prefix "\"firewall: SSH connection on standard SSH port\""
        rule -A tcp_filter_in -p tcp --dport ssh -m state --state NEW -j DROP
      fi
    fi

    if [[ "$FIREWALL_SERVER_DNS" == "yes" ]]
    then
      rule  -A tcp_filter_in -p tcp  --dport domain  -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "\"firewall: SSH exceeded connection limit\""
      rule  -A tcp_filter_in -p tcp  --dport domain -m state --state NEW  -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -j DROP

      rule  -A udp_srv_in -p udp  -s $EXTERNAL_NETMASK  --dport domain  -j ACCEPT
      rule  -A udp_srv_out -p udp  -d $EXTERNAL_NETMASK  --sport domain  -j ACCEPT
    fi

    if [[ "$FIREWALL_SERVER_ZONE" == "yes" ]]
    then
      rule  -A tcp_filter_in -p tcp  --dport domain  -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "\"firewall: domain exceeded connection limit\""
      rule  -A tcp_filter_in -p tcp  --dport domain -m state --state NEW -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -j DROP

      rule  -A tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport domain  -m state --state NEW  -j ACCEPT
    fi

    if [[ "$FIREWALL_SERVER_DHCP" == "yes" ]]
    then
      rule  -A udp_srv_out -p udp  -d $EXTERNAL_NETMASK  --sport 67  -j ACCEPT
      rule  -A udp_srv_in -p udp  -s $EXTERNAL_NETMASK  --sport 68  -j ACCEPT
    fi

    if [[ "$FIREWALL_SERVER_RSYNC" == "yes" ]]
    then
      rule  -A tcp_filter_in -p tcp  --dport rsync  -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "\"firewall: rsync exceeded connection limit\""
      rule  -A tcp_filter_in -p tcp  --dport rsync -m state --state NEW -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -j DROP


      rule  -A tcp_srv_in -p tcp  -d $EXTERNAL_NETMASK  --dport rsync  -m state --state NEW  -j ACCEPT
      rule  -A tcp_srv_in -p tcp  -d $EXTERNAL_NETMASK  --dport rsync  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "\"firewall: RSYNC dropping unmatched\""
    fi

    if [[ "$FIREWALL_SERVER_HTTP_LOW" == "yes" ]]
    then
      rule  -A tcp_filter_in -p tcp  --dport 80  -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "\"firewall: http exceeded connection limit\""
      rule  -A tcp_filter_in -p tcp  --dport 80 -m state --state NEW -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -j DROP

      rule  -A tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport 80  -m state --state NEW  -j ACCEPT
    fi

    if [[ "$FIREWALL_SERVER_HTTP_HIGH" == "yes" ]]
    then
      rule  -A tcp_filter_in -p tcp  --dport 8080  -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "\"firewall: http high exceeded connection limit\""
      rule  -A tcp_filter_in -p tcp  --dport 8080 -m state --state NEW -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -j DROP

      rule  -A tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport 8080  -m state --state NEW  -j ACCEPT
    fi

    if [[ "$FIREWALL_SERVER_HTTP_SSL" == "yes" ]]
    then
      rule  -A tcp_filter_in -p tcp  --dport https  -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "\"firewall: https high exceeded connection limit\""
      rule  -A tcp_filter_in -p tcp  --dport https -m state --state NEW -m connlimit --connlimit-above $FIREWALL_SERVICE_CAP  -j DROP

      rule  -A tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport https  -m state --state NEW  -j ACCEPT
    fi

    #
    # blocks
    #

    if [[ "$FIREWALL_BLOCK_SMB" == "yes" ]]
    then
      rule  -I udp_filter_in -p udp  --dport 137:139  -j DROP
      rule  -I udp_filter_in -p udp  --dport 137:139  -j REJECT
      rule  -I udp_filter_in -p udp  --dport 137:139  -j REJECT  --reject-with icmp-host-unreachable
    fi

    if [[ "$FIREWALL_BLOCK_DOMAIN" == "yes" ]]
    then
      rule  -I udp_filter_in -p udp  -i $EXTERNAL_INTERFACE  --dport domain  -j DROP
      rule  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport domain  -j DROP
    fi

    if [[ "$FIREWALL_BLOCK_HTTP" == "yes" ]]
    then
      rule  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport http  -j DROP
      rule  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport https  -j DROP
    fi

    if [[ "$FIREWALL_BLOCK_GENERIC" == "yes" ]]
    then
      rule  -I udp_filter_in -p udp  -i $EXTERNAL_INTERFACE  --dport sunrpc  -j DROP
      rule  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport sunrpc  -j DROP
      rule  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport telnet  -j DROP
    fi

    if [[ "$FIREWALL_BLOCK_FTP" == "yes" ]]
    then
      rule  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport ftp  -j DROP
      rule  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport ftp-data  -j DROP
    fi

    #
    # NAT
    #

    if [[ "$FIREWALL_NAT" == "yes" ]]
    then
      sysctl net.ipv4.ip_forward="1"

      rule  -t nat  -A POSTROUTING  -o $EXTERNAL_INTERFACE  -j MASQUERADE

      rule  -A FORWARD  -i $EXTERNAL_INTERFACE  -m state --state RELATED,ESTABLISHED  -j ACCEPT
      rule  -A FORWARD  -p udp  -j ACCEPT
      rule  -A FORWARD  -p icmp  -j ACCEPT
      rule  -A FORWARD  -j NFLOG --nflog-group 2  --nflog-prefix "\"firewall: unknown FORWARD traffic will be dropped\""

      rule  -I FORWARD  -s $EXTERNAL_NETMASK  -j ACCEPT
    fi

    #
    # forwarding
    #

    if [[ -n "$FIREWALL_DNAT_HTTP" ]]
    then
      rule  -t nat  -A PREROUTING  -p tcp  -i $EXTERNAL_INTERFACE  --dport 80  -j DNAT --to $FIREWALL_DNAT_HTTP
      rule  -A tcp_con_in -p tcp  -i $EXTERNAL_INTERFACE  --dport 80  -j ACCEPT
      rule  -t nat  -A PREROUTING  -p udp  -i $EXTERNAL_INTERFACE  --dport 80  -j DNAT --to $FIREWALL_DNAT_HTTP
      rule  -A udp_con_in -p udp  -i $EXTERNAL_INTERFACE  --dport 80  -j ACCEPT
      rule  -t nat  -A PREROUTING  -p tcp  -i $EXTERNAL_INTERFACE  --dport 443  -j DNAT --to $FIREWALL_DNAT_HTTP
      rule  -A tcp_con_in -p tcp  -i $EXTERNAL_INTERFACE  --dport 443  -j ACCEPT
      rule  -t nat  -A PREROUTING  -p udp  -i $EXTERNAL_INTERFACE  --dport 443  -j DNAT --to $FIREWALL_DNAT_HTTP
    fi
  ;;
  "reload")
    $0 flush
    $0 delete
    $0 load
  ;;
  "stop")
    $0 flush
    $0 delete
    $0 open
  ;;
  "help"|*)
    cat <<HELP
firewall.sh

delete   =  delete chains
flush    = flush chains
open     = open firewall completely, default accept policy
load     = load the firewall rules
reload   = re-initialize the firewall
stop     = stop the firewall, will completely remove firewall
HELP
  ;;
esac

exit 0

#! /bin/bash

#
# load system configuration and then development configuration
#

HOST=`uname -a  | tr -s ' ' | cut -d ' ' -f 2`

echo "firwall.sh: executing for host: $HOST"

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

case $1 in
  "delete")
    iptables -X icmp_filter_in
    iptables -X icmp_filter_out
    iptables -X icmp_traffic_in
    iptables -X icmp_traffic_out
    iptables -X tcp_filter_in
    iptables -X tcp_filter_out
    iptables -X tcp_con_in
    iptables -X tcp_con_out
    iptables -X tcp_srv_in
    iptables -X tcp_srv_out
    iptables -X udp_filter_in
    iptables -X udp_filter_out
    iptables -X udp_con_in
    iptables -X udp_con_out
    iptables -X udp_srv_in
    iptables -X udp_srv_out
  ;;
  "flush")
    iptables  -F INPUT
    iptables  -Z INPUT
    iptables  -F OUTPUT
    iptables  -Z OUTPUT
    iptables  -F FORWARD
    iptables  -Z FORWARD
    iptables  -t nat  -F POSTROUTING
    iptables  -t nat  -Z POSTROUTING
    iptables  -t nat  -F PREROUTING
    iptables  -t nat  -Z PREROUTING
    iptables  -F icmp_filter_in
    iptables  -Z icmp_filter_in
    iptables  -F icmp_filter_out
    iptables  -Z icmp_filter_out
    iptables  -F icmp_traffic_in
    iptables  -Z icmp_traffic_in
    iptables  -F icmp_traffic_out
    iptables  -Z icmp_traffic_out
    iptables  -F tcp_filter_in
    iptables  -Z tcp_filter_in
    iptables  -F tcp_filter_out
    iptables  -Z tcp_filter_out
    iptables  -F tcp_con_in
    iptables  -Z tcp_con_in
    iptables  -F tcp_con_out
    iptables  -Z tcp_con_out
    iptables  -F tcp_srv_in
    iptables  -Z tcp_srv_in
    iptables  -F tcp_srv_out
    iptables  -Z tcp_srv_out
    iptables  -F udp_filter_in
    iptables  -Z udp_filter_in
    iptables  -F udp_filter_out
    iptables  -Z udp_filter_out
    iptables  -F udp_con_in
    iptables  -Z udp_con_in
    iptables  -F udp_con_out
    iptables  -Z udp_con_out
    iptables  -F udp_srv_in
    iptables  -Z udp_srv_in
    iptables  -F udp_srv_out
    iptables  -Z udp_srv_out
  ;;
  "open")
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT
  ;;
  "load")
    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
    iptables -P FORWARD DROP

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

    iptables  -A INPUT -i lo -j ACCEPT
    iptables  -A OUTPUT -o lo -j ACCEPT

    iptables  -A INPUT  -i $EXTERNAL_INTERFACE  -s $LOOPBACK_NETMASK  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: spoof attempt"
    iptables  -A INPUT  -i $EXTERNAL_INTERFACE  -s $LOOPBACK_NETMASK  -j DROP


    iptables  -A INPUT  -i $EXTERNAL_INTERFACE  -s $EXTERNAL_NETMASK  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: spoof attempt"
    iptables  -A INPUT  -i $EXTERNAL_INTERFACE  -s $EXTERNAL_NETMASK  -j DROP

    #
    # icmp
    #

    iptables -N icmp_filter_in
    iptables -N icmp_filter_out
    iptables -N icmp_traffic_in
    iptables -N icmp_traffic_out
    iptables  -A INPUT  -p icmp -j icmp_filter_in
    iptables  -A OUTPUT -p icmp -j icmp_filter_out
    iptables  -A INPUT  -p icmp -j icmp_traffic_in
    iptables  -A OUTPUT -p icmp -j icmp_traffic_out
    iptables  -A icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: ICMP broadcast! "
    iptables  -A icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: ICMP broadcast! "
    iptables  -A icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -j DROP
    iptables  -A icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -j DROP
    iptables  -A icmp_filter_in  -p icmp  --icmp-type timestamp-request  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP strange "
    iptables  -A icmp_filter_in  -p icmp  --icmp-type timestamp-reply  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP strange "
    iptables  -A icmp_filter_in  -p icmp  --icmp-type address-mask-request  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP strange "
    iptables  -A icmp_filter_out -p icmp  --icmp-type address-mask-reply  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP strange "
    iptables  -A icmp_filter_in  -p icmp  --icmp-type timestamp-request  -j DROP
    iptables  -A icmp_filter_in  -p icmp  --icmp-type timestamp-reply  -j DROP
    iptables  -A icmp_filter_in  -p icmp  --icmp-type address-mask-request  -j DROP
    iptables  -A icmp_filter_out -p icmp  --icmp-type address-mask-reply  -j DROP
    iptables  -A icmp_traffic_in  -p icmp  --icmp-type echo-request  -m limit --limit 8\/second --limit-burst 24  -j ACCEPT
    iptables  -A icmp_traffic_in  -p icmp  --icmp-type echo-reply  -m limit --limit 8\/second --limit-burst 24  -j ACCEPT
    iptables  -A icmp_traffic_out -p icmp  --icmp-type echo-request  -j ACCEPT
    iptables  -A icmp_traffic_out -p icmp  --icmp-type echo-reply  -j ACCEPT
    iptables  -A icmp_traffic_in  -p icmp  --icmp-type echo-reply  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: ICMP high rate "
    iptables  -A icmp_traffic_in  -p icmp  --icmp-type echo-request  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: ICMP high rate "
    iptables  -A icmp_traffic_in  -p icmp  --icmp-type echo-reply  -j DROP
    iptables  -A icmp_traffic_in  -p icmp  --icmp-type echo-request  -j DROP
    iptables  -A icmp_traffic_in  -p icmp  -m state --state RELATED  -j ACCEPT
    iptables  -A icmp_traffic_out -p icmp  -m state --state RELATED  -j ACCEPT
    iptables  -A icmp_traffic_out -p icmp  -m state --state NEW  -j ACCEPT
    iptables  -A INPUT  -p icmp  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP no rule for packet"
    iptables  -A OUTPUT -p icmp  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP no rule for packet"
    iptables  -A INPUT  -p icmp  -j DROP

    #
    # tcp protocol
    #

    iptables -N tcp_filter_in
    iptables -N tcp_filter_out
    iptables  -A INPUT   -p tcp -j tcp_filter_in
    iptables  -A OUTPUT  -p tcp -j tcp_filter_out
    iptables -N tcp_con_in
    iptables -N tcp_con_out
    iptables  -A INPUT   -p tcp -j tcp_con_in
    iptables  -A OUTPUT  -p tcp -j tcp_con_out
    iptables -N tcp_srv_in
    iptables -N tcp_srv_out
    iptables  -A INPUT   -p tcp -j tcp_srv_in
    iptables  -A OUTPUT  -p tcp -j tcp_srv_out
    iptables  -A tcp_con_in -p tcp  -m state --state ESTABLISHED  -j ACCEPT
    iptables  -A tcp_con_out -p tcp  -m state --state ESTABLISHED  -j ACCEPT
    iptables  -A tcp_con_out -p tcp  -m state --state NEW  -j ACCEPT
    iptables  -A tcp_con_in -p tcp  -m state --state RELATED  -j ACCEPT
    iptables  -A tcp_con_out -p tcp  -m state --state RELATED  -j ACCEPT
    iptables  -A tcp_con_in -p tcp  -m conntrack --ctstatus SEEN_REPLY  --tcp-flags SYN,ACK,FIN,RST ACK,SYN  -j ACCEPT
    iptables  -A tcp_con_in -p tcp  --tcp-flags RST RST  -j ACCEPT
    iptables  -A tcp_con_out -p tcp  --tcp-flags RST RST  -j ACCEPT
    iptables  -A tcp_con_in -p tcp  --tcp-flags ACK ACK  -j ACCEPT
    iptables  -A tcp_con_out -p tcp  --tcp-flags ACK ACK  -j ACCEPT
    iptables  -A INPUT   -p tcp  -m pkttype --pkt-type broadcast  -j DROP
    iptables  -A INPUT   -p tcp  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: TCP no matching rule"
    iptables  -A OUTPUT  -p tcp  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: TCP no matching rule"
    iptables  -A INPUT   -p tcp  -j DROP

    #
    # udp protocol
    #

    iptables -N udp_filter_in
    iptables -N udp_filter_out
    iptables  -A INPUT   -p udp -j udp_filter_in
    iptables  -A OUTPUT  -p udp -j udp_filter_out
    iptables -N udp_con_in
    iptables -N udp_con_out
    iptables  -A INPUT   -p udp -j udp_con_in
    iptables  -A OUTPUT  -p udp -j udp_con_out
    iptables -N udp_srv_in
    iptables -N udp_srv_out
    iptables  -A INPUT   -p udp -j udp_srv_in
    iptables  -A OUTPUT  -p udp -j udp_srv_out
    iptables  -A udp_con_in -p udp  -m state --state ESTABLISHED,RELATED  -j ACCEPT
    iptables  -A udp_con_out -p udp  -m state --state ESTABLISHED,RELATED,NEW  -j ACCEPT
    iptables  -A udp_con_in -p udp  --sport domain  -j ACCEPT
    iptables  -A INPUT   -p udp  -m pkttype --pkt-type broadcast  -j DROP
    iptables  -A INPUT   -p udp  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: UDP no rule for packet"
    iptables  -A OUTPUT  -p udp  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: UDP no rule for packet"
    iptables  -A INPUT   -p udp  -j DROP

    #
    # clients
    #

    if [[ "$FIREWALL_CLIENT_DHCP" == "yes" ]]
    then
      iptables  -A udp_filter_in -p udp  -i $EXTERNAL_INTERFACE  -s 0.0.0.0  --sport 67  -m pkttype --pkt-type broadcast  -j DROP
      iptables  -A udp_con_out -p udp  -o $EXTERNAL_INTERFACE  --dport 67  -j ACCEPT
      iptables  -A udp_con_in -p udp  -i $EXTERNAL_INTERFACE  ! -s 0.0.0.0  --sport 67  -m pkttype --pkt-type broadcast  -j ACCEPT
    fi

    #
    # servers
    #

    if [[ "$FIREWALL_SERVER_SSH" == "yes" ]]
    then
      iptables  -A tcp_filter_in -p tcp  --dport ssh  -m connlimit --connlimit-above 20  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "firewall: SSH exceeded connection limit"
      iptables  -A tcp_filter_in -p tcp  --dport ssh  -m state --state NEW  -m connlimit --connlimit-above 20  -j DROP
      iptables  -A tcp_srv_in -p tcp  --dport ssh  -m state --state NEW  -j ACCEPT
      iptables  -A tcp_srv_in -p tcp  --dport ssh  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "firewall: SSH dropping unmatched"
    fi

    if [[ "$FIREWALL_SERVER_DNS" == "yes" ]]
    then
      iptables  -A udp_srv_in -p udp  -s $EXTERNAL_NETMASK  --dport domain  -j ACCEPT
      iptables  -A udp_srv_out -p udp  -d $EXTERNAL_NETMASK  --sport domain  -j ACCEPT
      iptables  -A tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport domain  -m state --state NEW  -j ACCEPT
      iptables  -A tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport domain  -m state --state NEW  -j NFLOG  --nflog-group 3
    fi

    if [[ "$FIREWALL_SERVER_DHCP" == "yes" ]]
    then
      iptables  -A udp_srv_out -p udp  -d $EXTERNAL_NETMASK  --sport 67  -j ACCEPT
      iptables  -A udp_srv_in -p udp  -s $EXTERNAL_NETMASK  --sport 68  -j ACCEPT
    fi

    if [[ "$FIREWALL_SERVER_RSYNC" == "yes" ]]
    then
      iptables  -A tcp_srv_in -p tcp  -d $EXTERNAL_NETMASK  --dport rsync  -m state --state NEW  -j ACCEPT
      iptables  -A tcp_srv_in -p tcp  -d $EXTERNAL_NETMASK  --dport rsync  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "firewall: RSYNC dropping unmatched"
    fi

    if [[ "$FIREWALL_SERVER_HTTP_HIGH" ]]
    then
      iptables  -A tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport 8080  -m state --state NEW  -j ACCEPT
      iptables  -A tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport 8080  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "firewall: http-proxy dropping unmatched"
    fi

    #
    # blocks
    #

    if [[ "$FIREWALL_BLOCK_SMB" == "yes" ]]
    then
      iptables  -I udp_filter_in -p udp  --dport 137:139  -j DROP
      iptables  -I udp_filter_in -p udp  --dport 137:139  -j REJECT
      iptables  -I udp_filter_in -p udp  --dport 137:139  -j REJECT  --reject-with icmp-host-unreachable
    fi

    if [[ "$FIREWALL_BLOCK_DOMAIN" == "yes" ]]
    then
      iptables  -I udp_filter_in -p udp  -i $EXTERNAL_INTERFACE  --dport domain  -j DROP
      iptables  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport domain  -j DROP
    fi

    if [[ "$FIREWALL_BLOCK_HTTP" == "yes" ]]
    then
      iptables  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport http  -j DROP
      iptables  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport https  -j DROP
    fi

    if [[ "$FIREWALL_BLOCK_GENERIC" == "yes" ]]
    then
      iptables  -I udp_filter_in -p udp  -i $EXTERNAL_INTERFACE  --dport sunrpc  -j DROP
      iptables  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport sunrpc  -j DROP
      iptables  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport telnet  -j DROP
    fi

    if [[ "$FIREWALL_BLOCK_FTP" == "yes" ]]
    then
      iptables  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport ftp  -j DROP
      iptables  -I tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport ftp-data  -j DROP
    fi

    #
    # NAT
    #

    if [[ "$FIREWALL_NAT" == "yes" ]]
    then
      sysctl net.ipv4.ip_forward="1"
      iptables  -t nat  -A POSTROUTING  -o $EXTERNAL_INTERFACE  -j MASQUERADE

      iptables  -A FORWARD  -i $EXTERNAL_INTERFACE  -m state --state RELATED,ESTABLISHED  -j ACCEPT
      iptables  -A FORWARD  -p udp  -j ACCEPT
      iptables  -A FORWARD  -p icmp  -j ACCEPT
      iptables  -A FORWARD  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: unknown FORWARD traffic will be dropped"

      iptables  -I FORWARD  -s $EXTERNAL_NETMASK  -j ACCEPT
    fi

    #
    # forwarding
    #

    if [[ -n "$FIREWALL_DNAT_HTTP" ]]
    then
      iptables  -t nat  -A PREROUTING  -p tcp  -i $EXTERNAL_INTERFACE  --dport 80  -j DNAT --to $FIREWALL_DNAT_HTTP
      iptables  -A tcp_con_in -p tcp  -i $EXTERNAL_INTERFACE  --dport 80  -j ACCEPT
      iptables  -t nat  -A PREROUTING  -p udp  -i $EXTERNAL_INTERFACE  --dport 80  -j DNAT --to $FIREWALL_DNAT_HTTP
      iptables  -A udp_con_in -p udp  -i $EXTERNAL_INTERFACE  --dport 80  -j ACCEPT
      iptables  -t nat  -A PREROUTING  -p tcp  -i $EXTERNAL_INTERFACE  --dport 443  -j DNAT --to $FIREWALL_DNAT_HTTP
      iptables  -A tcp_con_in -p tcp  -i $EXTERNAL_INTERFACE  --dport 443  -j ACCEPT
      iptables  -t nat  -A PREROUTING  -p udp  -i $EXTERNAL_INTERFACE  --dport 443  -j DNAT --to $FIREWALL_DNAT_HTTP
    fi
  ;;
  "unload")
    #
    # reset kernel parameters
    #

    sysctl net.ipv4.conf.all.log_martians="0"
    sysctl net.ipv4.ip_forward="0"

    #
    # flush the core chains
    #

    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables  -F INPUT
    iptables  -Z INPUT
    iptables  -F OUTPUT
    iptables  -Z OUTPUT
    iptables  -F FORWARD
    iptables  -Z FORWARD
    iptables  -t nat  -F POSTROUTING
    iptables  -t nat  -Z POSTROUTING
    iptables  -t nat  -F PREROUTING
    iptables  -t nat  -Z PREROUTING

    #
    # flush loopback
    #

    iptables  -D INPUT -i lo -j ACCEPT
    iptables  -D OUTPUT -o lo -j ACCEPT

    #
    # institute block loopback spoofing
    #

    iptables  -D INPUT  -i $EXTERNAL_INTERFACE  -s $LOOPBACK_NETMASK  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: spoof attempt"
    iptables  -D INPUT  -i $EXTERNAL_INTERFACE  -s $LOOPBACK_NETMASK  -j DROP
    iptables  -D INPUT  -i $EXTERNAL_INTERFACE  -s $EXTERNAL_NETMASK  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: spoof attempt"
    iptables  -D INPUT  -i $EXTERNAL_INTERFACE  -s $EXTERNAL_NETMASK  -j DROP

    iptables  -D INPUT  -i $EXTERNAL_INTERFACE  -s $EXTERNAL_NETMASK  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: spoof attempt"
    iptables  -D INPUT  -i $EXTERNAL_INTERFACE  -s $EXTERNAL_NETMASK -j DROP


    # delete ICMP

    iptables  -F icmp_filter_in
    iptables  -Z icmp_filter_in
    iptables  -F icmp_filter_out
    iptables  -Z icmp_filter_out
    iptables  -F icmp_traffic_in
    iptables  -Z icmp_traffic_in
    iptables  -F icmp_traffic_out
    iptables  -Z icmp_traffic_out

    iptables  -D INPUT  -p icmp -j icmp_filter_in
    iptables  -D OUTPUT -p icmp -j icmp_filter_out
    iptables  -D INPUT  -p icmp -j icmp_traffic_in
    iptables  -D OUTPUT -p icmp -j icmp_traffic_out

    # delete ICMP filtering

    iptables  -D icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: ICMP broadcast! "
    iptables  -D icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: ICMP broadcast! "
    iptables  -D icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -j DROP
    iptables  -D icmp_filter_in  -p icmp  -m pkttype --pkt-type broadcast  -j DROP
    iptables  -D icmp_filter_in  -p icmp  --icmp-type timestamp-request  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP strange "
    iptables  -D icmp_filter_in  -p icmp  --icmp-type timestamp-reply  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP strange "
    iptables  -D icmp_filter_in  -p icmp  --icmp-type address-mask-request  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP strange "
    iptables  -D icmp_filter_out -p icmp  --icmp-type address-mask-reply  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP strange "
    iptables  -D icmp_filter_in  -p icmp  --icmp-type timestamp-request  -j DROP
    iptables  -D icmp_filter_in  -p icmp  --icmp-type timestamp-reply  -j DROP
    iptables  -D icmp_filter_in  -p icmp  --icmp-type address-mask-request  -j DROP
    iptables  -D icmp_filter_out -p icmp  --icmp-type address-mask-reply  -j DROP
    iptables  -D icmp_traffic_in  -p icmp  --icmp-type echo-request  -m limit --limit 8\/second --limit-burst 24  -j ACCEPT
    iptables  -D icmp_traffic_in  -p icmp  --icmp-type echo-reply  -m limit --limit 8\/second --limit-burst 24  -j ACCEPT
    iptables  -D icmp_traffic_out -p icmp  --icmp-type echo-request  -j ACCEPT
    iptables  -D icmp_traffic_out -p icmp  --icmp-type echo-reply  -j ACCEPT
    iptables  -D icmp_traffic_in  -p icmp  --icmp-type echo-reply  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: ICMP high rate "
    iptables  -D icmp_traffic_in  -p icmp  --icmp-type echo-request  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: ICMP high rate "
    iptables  -D icmp_traffic_in  -p icmp  --icmp-type echo-reply  -j DROP
    iptables  -D icmp_traffic_in  -p icmp  --icmp-type echo-request  -j DROP
    iptables  -D icmp_traffic_in  -p icmp  -m state --state RELATED  -j ACCEPT
    iptables  -D icmp_traffic_out -p icmp  -m state --state RELATED  -j ACCEPT
    iptables  -D icmp_traffic_out -p icmp  -m state --state NEW  -j ACCEPT
    iptables  -D INPUT  -p icmp  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP no rule for packet"
    iptables  -D OUTPUT -p icmp  -j NFLOG --nflog-group 2  --nflog-prefix="firewall: ICMP no rule for packet"
    iptables  -D INPUT  -p icmp  -j DROP

    #
    # delete core TCP chains
    #

    iptables  -F tcp_filter_in
    iptables  -Z tcp_filter_in
    iptables  -F tcp_filter_out
    iptables  -Z tcp_filter_out
    iptables  -D INPUT   -p tcp -j tcp_filter_in
    iptables  -D OUTPUT  -p tcp -j tcp_filter_out
    iptables  -F tcp_con_in
    iptables  -Z tcp_con_in
    iptables  -F tcp_con_out
    iptables  -Z tcp_con_out
    iptables  -D INPUT   -p tcp -j tcp_con_in
    iptables  -D OUTPUT  -p tcp -j tcp_con_out
    iptables  -F tcp_srv_in
    iptables  -Z tcp_srv_in
    iptables  -F tcp_srv_out
    iptables  -Z tcp_srv_out
    iptables  -D INPUT   -p tcp -j tcp_srv_in
    iptables  -D OUTPUT  -p tcp -j tcp_srv_out
    iptables  -D tcp_con_in -p tcp  -m state --state ESTABLISHED  -j ACCEPT
    iptables  -D tcp_con_out -p tcp  -m state --state ESTABLISHED  -j ACCEPT
    iptables  -D tcp_con_out -p tcp  -m state --state NEW  -j ACCEPT
    iptables  -D tcp_con_in -p tcp  -m state --state RELATED  -j ACCEPT
    iptables  -D tcp_con_out -p tcp  -m state --state RELATED  -j ACCEPT
    iptables  -D tcp_con_in -p tcp  -m conntrack --ctstatus SEEN_REPLY  --tcp-flags SYN,ACK,FIN,RST ACK,SYN  -j ACCEPT
    iptables  -D tcp_con_in -p tcp  --tcp-flags RST RST  -j ACCEPT
    iptables  -D tcp_con_out -p tcp  --tcp-flags RST RST  -j ACCEPT
    iptables  -D tcp_con_in -p tcp  --tcp-flags ACK ACK  -j ACCEPT
    iptables  -D tcp_con_out -p tcp  --tcp-flags ACK ACK  -j ACCEPT
    iptables  -D INPUT   -p tcp  -m pkttype --pkt-type broadcast  -j DROP
    iptables  -D INPUT   -p tcp  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: TCP no matching rule"
    iptables  -D OUTPUT  -p tcp  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: TCP no matching rule"
    iptables  -D INPUT   -p tcp  -j DROP
    iptables  -F udp_filter_in
    iptables  -Z udp_filter_in
    iptables  -F udp_filter_out
    iptables  -Z udp_filter_out
    iptables  -D INPUT   -p udp -j udp_filter_in
    iptables  -D OUTPUT  -p udp -j udp_filter_out
    iptables  -F udp_con_in
    iptables  -Z udp_con_in
    iptables  -F udp_con_out
    iptables  -Z udp_con_out
    iptables  -D INPUT   -p udp -j udp_con_in
    iptables  -D OUTPUT  -p udp -j udp_con_out
    iptables  -F udp_srv_in
    iptables  -Z udp_srv_in
    iptables  -F udp_srv_out
    iptables  -Z udp_srv_out
    iptables  -D INPUT   -p udp -j udp_srv_in
    iptables  -D OUTPUT  -p udp -j udp_srv_out
    iptables  -D udp_con_in -p udp  -m state --state ESTABLISHED,RELATED  -j ACCEPT
    iptables  -D udp_con_out -p udp  -m state --state ESTABLISHED,RELATED,NEW  -j ACCEPT
    iptables  -D udp_con_in -p udp  --sport domain  -j ACCEPT
    iptables  -D INPUT   -p udp  -m pkttype --pkt-type broadcast  -j DROP
    iptables  -D INPUT   -p udp  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: UDP no rule for packet"
    iptables  -D OUTPUT  -p udp  -m limit --limit 24\/minute  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: UDP no rule for packet"
    iptables  -D INPUT   -p udp  -j DROP
    iptables  -D udp_filter_in -p udp  -i $EXTERNAL_INTERFACE  -s 0.0.0.0  --sport 67  -m pkttype --pkt-type broadcast  -j DROP
    iptables  -D udp_con_out -p udp  -o $EXTERNAL_INTERFACE  --dport 67  -j ACCEPT
    iptables  -D udp_con_in -p udp  -i $EXTERNAL_INTERFACE  ! -s 0.0.0.0  --sport 67  -m pkttype --pkt-type broadcast  -j ACCEPT
    iptables  -D tcp_filter_in -p tcp  --dport ssh  -m connlimit --connlimit-above 20  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "firewall: SSH exceeded connection limit"
    iptables  -D tcp_filter_in -p tcp  --dport ssh  -m state --state NEW  -m connlimit --connlimit-above 20  -j DROP
    iptables  -D tcp_srv_in -p tcp  --dport ssh  -m state --state NEW  -j ACCEPT
    iptables  -D tcp_srv_in -p tcp  --dport ssh  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "firewall: SSH dropping unmatched"
    iptables  -D udp_srv_in -p udp  -s $EXTERNAL_NETMASK  --dport domain  -j ACCEPT
    iptables  -D udp_srv_out -p udp  -d $EXTERNAL_NETMASK  --sport domain  -j ACCEPT
    iptables  -D tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport domain  -m state --state NEW  -j ACCEPT
    iptables  -D tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport domain  -m state --state NEW  -j NFLOG  --nflog-group 3
    iptables  -D udp_srv_out -p udp  -d $EXTERNAL_NETMASK  --sport 67  -j ACCEPT
    iptables  -D udp_srv_in -p udp  -s $EXTERNAL_NETMASK  --sport 68  -j ACCEPT
    iptables  -D tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport rsync  -m state --state NEW  -j ACCEPT
    iptables  -D tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport rsync  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "firewall: RSYNC dropping unmatched"
    iptables  -D tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport 8080  -m state --state NEW  -j ACCEPT
    iptables  -D tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport 8080  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "firewall: http-proxy dropping unmatched"
    iptables  -D udp_srv_in -p udp  -s $EXTERNAL_NETMASK  --dport domain  -j ACCEPT
    iptables  -D udp_srv_out -p udp  -d $EXTERNAL_NETMASK  --sport domain  -j ACCEPT
    iptables  -D tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport domain  -m state --state NEW  -j ACCEPT
    iptables  -D tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport domain  -m state --state NEW  -j NFLOG  --nflog-group 3
    iptables  -D udp_srv_out -p udp  -d $EXTERNAL_NETMASK  --sport 67  -j ACCEPT
    iptables  -D udp_srv_in -p udp  -s $EXTERNAL_NETMASK  --sport 68  -j ACCEPT
    iptables  -D tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport 8080  -m state --state NEW  -j ACCEPT
    iptables  -D tcp_srv_in -p tcp  -s $EXTERNAL_NETMASK  --dport 8080  -m state --state NEW  -j NFLOG  --nflog-group 3  --nflog-prefix "firewall: http-proxy dropping unmatched"
    iptables  -D udp_filter_in -p udp  --dport 137:139  -j DROP
    iptables  -D udp_filter_in -p udp  --dport 137:139  -j REJECT
    iptables  -D udp_filter_in -p udp  --dport 137:139  -j REJECT  --reject-with icmp-host-unreachable
    iptables  -D tcp_filter_in -p tcp  --dport 1433  -j DROP
    iptables  -D udp_filter_in -p udp  -i $EXTERNAL_INTERFACE  --dport domain  -j DROP
    iptables  -D tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport domain  -j DROP
    iptables  -D tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport http  -j DROP
    iptables  -D tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport https  -j DROP
    iptables  -D udp_filter_in -p udp  -i $EXTERNAL_INTERFACE  --dport sunrpc  -j DROP
    iptables  -D tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport sunrpc  -j DROP
    iptables  -D tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport telnet  -j DROP
    iptables  -D tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport ftp  -j DROP
    iptables  -D tcp_filter_in -p tcp  -i $EXTERNAL_INTERFACE  --dport ftp-data  -j DROP
    iptables  -t nat  -D POSTROUTING  -o $EXTERNAL_INTERFACE  -j MASQUERADE
    iptables  -D FORWARD  -i $EXTERNAL_INTERFACE  -m state --state RELATED,ESTABLISHED  -j ACCEPT
    iptables  -D FORWARD  -p udp  -j ACCEPT
    iptables  -D FORWARD  -p icmp  -j ACCEPT
    iptables  -D FORWARD  -j NFLOG --nflog-group 2  --nflog-prefix "firewall: unknown FORWARD traffic will be dropped"

    iptables  -D FORWARD  -s $EXTERNAL_NETMASK  -j ACCEPT
    iptables  -D FORWARD  -s $EXTERNAL_NETMASK  -j ACCEPT

    iptables  -t nat  -D PREROUTING  -p tcp  -i $EXTERNAL_INTERFACE  --dport 80  -j DNAT --to 192.168.2.8
    iptables  -D tcp_con_in -p tcp  -i $EXTERNAL_INTERFACE  --dport 80  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p udp  -i $EXTERNAL_INTERFACE  --dport 80  -j DNAT --to 192.168.2.8
    iptables  -D udp_con_in -p udp  -i $EXTERNAL_INTERFACE  --dport 80  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p tcp  -i $EXTERNAL_INTERFACE  --dport 443  -j DNAT --to 192.168.2.8
    iptables  -D tcp_con_in -p tcp  -i $EXTERNAL_INTERFACE  --dport 443  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p udp  -i $EXTERNAL_INTERFACE  --dport 443  -j DNAT --to 192.168.2.8
    iptables  -D udp_con_in -p udp  -i $EXTERNAL_INTERFACE  --dport 443  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p tcp  -i $EXTERNAL_INTERFACE  --dport 1935  -j DNAT --to 192.168.2.8
    iptables  -D tcp_con_in -p tcp  -i $EXTERNAL_INTERFACE  --dport 1935  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p udp  -i $EXTERNAL_INTERFACE  --dport 1935  -j DNAT --to 192.168.2.8
    iptables  -D udp_con_in -p udp  -i $EXTERNAL_INTERFACE  --dport 1935  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p tcp  -i $EXTERNAL_INTERFACE  --dport 3478:3480  -j DNAT --to 192.168.2.8
    iptables  -D tcp_con_in -p tcp  -i $EXTERNAL_INTERFACE  --dport 3478:3480  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p udp  -i $EXTERNAL_INTERFACE  --dport 3478:3480  -j DNAT --to 192.168.2.8
    iptables  -D udp_con_in -p udp  -i $EXTERNAL_INTERFACE  --dport 3478:3480  -j ACCEPT
  ;;
  "reload")
    $0 disable
    $0 flush
    $0 load
  ;;
  "help"|*)
    cat <<HELP
firewall.sh

delete   =  delete chains
flush    = flush chains
open     = open firewall completely, default accept policy
load     = load the firewall rules
unload   = remove firewall rules
reload   = re-initialize the firewall
HELP
  ;;
esac

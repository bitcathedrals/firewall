#! /bin/bash

case $1 in
  "load")
    iptables  -I FORWARD  -d 192.168.2.8  -j ACCEPT
    iptables  -I FORWARD  -s 192.168.2.8  -j ACCEPT
    iptables  -t nat  -A PREROUTING  -p tcp  -i enp1s0  --dport 80  -j DNAT --to 192.168.2.8
    iptables  -A tcp_con_in -p tcp  -i enp1s0  --dport 80  -j ACCEPT
    iptables  -t nat  -A PREROUTING  -p udp  -i enp1s0  --dport 80  -j DNAT --to 192.168.2.8
    iptables  -A udp_con_in -p udp  -i enp1s0  --dport 80  -j ACCEPT
    iptables  -t nat  -A PREROUTING  -p tcp  -i enp1s0  --dport 443  -j DNAT --to 192.168.2.8
    iptables  -A tcp_con_in -p tcp  -i enp1s0  --dport 443  -j ACCEPT
    iptables  -t nat  -A PREROUTING  -p udp  -i enp1s0  --dport 443  -j DNAT --to 192.168.2.8
    iptables  -A udp_con_in -p udp  -i enp1s0  --dport 443  -j ACCEPT
    iptables  -t nat  -A PREROUTING  -p tcp  -i enp1s0  --dport 1935  -j DNAT --to 192.168.2.8
    iptables  -A tcp_con_in -p tcp  -i enp1s0  --dport 1935  -j ACCEPT
    iptables  -t nat  -A PREROUTING  -p udp  -i enp1s0  --dport 1935  -j DNAT --to 192.168.2.8
    iptables  -A udp_con_in -p udp  -i enp1s0  --dport 1935  -j ACCEPT
    iptables  -t nat  -A PREROUTING  -p tcp  -i enp1s0  --dport 3478:3480  -j DNAT --to 192.168.2.8
    iptables  -A tcp_con_in -p tcp  -i enp1s0  --dport 3478:3480  -j ACCEPT
    iptables  -t nat  -A PREROUTING  -p udp  -i enp1s0  --dport 3478:3480  -j DNAT --to 192.168.2.8
    iptables  -A udp_con_in -p udp  -i enp1s0  --dport 3478:3480  -j ACCEPT
  ;;
  "unload")
    iptables  -D FORWARD  -d 192.168.2.8  -j ACCEPT
    iptables  -D FORWARD  -s 192.168.2.8  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p tcp  -i enp1s0  --dport 80  -j DNAT --to 192.168.2.8
    iptables  -D tcp_con_in -p tcp  -i enp1s0  --dport 80  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p udp  -i enp1s0  --dport 80  -j DNAT --to 192.168.2.8
    iptables  -D udp_con_in -p udp  -i enp1s0  --dport 80  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p tcp  -i enp1s0  --dport 443  -j DNAT --to 192.168.2.8
    iptables  -D tcp_con_in -p tcp  -i enp1s0  --dport 443  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p udp  -i enp1s0  --dport 443  -j DNAT --to 192.168.2.8
    iptables  -D udp_con_in -p udp  -i enp1s0  --dport 443  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p tcp  -i enp1s0  --dport 1935  -j DNAT --to 192.168.2.8
    iptables  -D tcp_con_in -p tcp  -i enp1s0  --dport 1935  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p udp  -i enp1s0  --dport 1935  -j DNAT --to 192.168.2.8
    iptables  -D udp_con_in -p udp  -i enp1s0  --dport 1935  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p tcp  -i enp1s0  --dport 3478:3480  -j DNAT --to 192.168.2.8
    iptables  -D tcp_con_in -p tcp  -i enp1s0  --dport 3478:3480  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p udp  -i enp1s0  --dport 3478:3480  -j DNAT --to 192.168.2.8
    iptables  -D udp_con_in -p udp  -i enp1s0  --dport 3478:3480  -j ACCEPT
  ;;
  *)
    echo "unknown command $1"
  ;;
esac

exit 0

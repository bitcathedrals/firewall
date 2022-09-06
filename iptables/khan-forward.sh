#! /bin/bash

case $1 in
  "load")
    iptables  -t nat  -A PREROUTING  -p tcp  -i enp1s0  --dport 7777  -j DNAT --to 192.168.2.187
    iptables  -A tcp_con_in -p tcp  -i enp1s0  --dport 7777  -j ACCEPT
    iptables  -t nat  -A PREROUTING  -p udp  -i enp1s0  --dport 8888  -j DNAT --to 192.168.2.187
    iptables  -A udp_con_in -p udp  -i enp1s0  --dport 8888  -j ACCEPT
  ;;
  "unload")
    iptables  -t nat  -D PREROUTING  -p tcp  -i enp1s0  --dport 7777  -j DNAT --to 192.168.2.187
    iptables  -D tcp_con_in -p tcp  -i enp1s0  --dport 7777  -j ACCEPT
    iptables  -t nat  -D PREROUTING  -p udp  -i enp1s0  --dport 8888  -j DNAT --to 192.168.2.187
    iptables  -D udp_con_in -p udp  -i enp1s0  --dport 8888  -j ACCEPT
  ;;
  *)
    echo "unknown command $1"
  ;;
esac

exit 0

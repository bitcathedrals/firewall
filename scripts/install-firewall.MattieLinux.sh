#! /usr/bin/env bash

IPTABLES=/home/mattie/coding/firewall/iptables
FIREWALL=$IPTALBES/firewall.sh
SYSTEMD=/lib/systemd/system

sudo test -d  /etc/firewall || sudo mdkdir /etc/firewall

sudo cp $IPTABLES/firewall.sh /etc/firewall/
sudo cp $IPTABLES/MattieLinux.sh  /etc/firewall/

sudo cp $IPTABLES/firewall.service $SYSTEMD/firewall.service


#! /usr/bin/env bash

FIREWALL=../iptables/
doas test -d /etc/firewall || mkdir /etc/firewall

doas cp $FIREWALL/linux/firewall.sh /etc/firewall
doas cp $FIREWALL/$1.sh /etc/firewall

doas cp $FIREWALL/firewall.service /lib/systemd/system/firewall.service

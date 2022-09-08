#! /usr/bin/env bash

FIREWALL=/home/mattie/coding/firewall/iptables/
test -d /etc/firewall || mkdir /etc/firewall

cp $FIREWALL/firewall.sh /etc/firewall
cp $FIREWALL/kali.sh     /etc/firewall

cp $FIREWALL/firewall.service /lib/systemd/system/firewall.service

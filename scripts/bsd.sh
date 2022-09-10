#! /usr/bin/env bash

DEV=/home/mattie/coding/firewall/pf/

case $1 in
  "disable")
    pfctl -d
  ;;
  "enable")
    pfctl -e
  ;;
  "stable")
    pfctl -ef /etc/pf.conf
  ;;
  ;;
  "dev")
    $FIREWALL/firewall.sh >$FIREWALL/pf.conf
    pfctl -ef $FIREWALL/pf.conf
  ;;
  "check")
    $FIREWALL/firewall.sh >$FIREWALL/pf.conf
    pfctl -nef $FIREWALL/pf.conf
  ;;
  "install")
    $FIREWALL/firewall.sh >/etc/pf.conf
  ;;
  "info")
    pfctl -s info
  ;;
  "blacklist-conf")
cat >>/etc/blacklistd.conf <<CONF
[local]
ssh stream * * * 3 24h
CONF

cat >>/etc/rc.conf <<CONF
blacklist_enable="YES"
CONF
  ;;
  "pf-conf")
cat >>/etc/rc.conf <<CONF
pf_enable="YES"
pflog_enable="YES"
CONF
  ;;
  "help"|*)
    cat <<HELP
bsd.sh

disable         =  disable packet filter
enable          =  enable the packet filter
stable          =  load stable version of packet filter
dev             =  load development version of packet filter
check           = check syntax of the packet filter
install         = install the development firewall into /etc/
info            = show pf info
blacklist-conf  = update the blacklist.conf file
pf-conf         = update rc.conf to load firewall
HELP
esac

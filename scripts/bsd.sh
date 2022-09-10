#! /usr/bin/env bash

HOST=`uname -a  | tr -s ' ' | cut -d ' ' -f 2`

REPO=$HOME/coding/firewall/pf
CONFIG=$REPO/${HOST}.sh

FIREWALL="$REPO/firewall.sh"

STABLE=/etc/pf.conf
DEV=$REPO/pf.conf

BLACKLIST=/etc/blacklistd.conf
RC=/etc/rc.conf

if [[ -f $CONFIG ]]
then
  echo >/dev/stderr "bsd.sh: loading firewall config: $CONFIG"
  source $CONFIG
else
  echo >/dev/stderr "bsd.sh: could not locate host config $CONFIG, aborting!"
  exit 1
fi

if [[ -f $FIREWALL ]]
then
  echo >/dev/stderr "bsd.sh: loading firewall: $FIREWALL"
else
  echo >/dev/stderr "bsd.sh: could not locate firewall: $FIREWALL, aborting!"
  exit 1
fi

case $1 in
  "onestart")
    sudo service pflog onestart
    sudo service pf onestart
  ;;
  "disable")
    sudo pfctl -d
  ;;
  "enable")
    sudo pfctl -e
  ;;
  "stable")
    sudo pfctl -ef $STABLE
  ;;
  "dev")
    $FIREWALL >$DEV
    sudo pfctl -ef $DEV
  ;;
  "check")
    $FIREWALL >$DEV
    pfctl -vnf $DEV
  ;;
  "install")
    sudo $FIREWALL >$STABLE
  ;;
  "info")
    sudo pfctl -s info
  ;;
  "restart")
    if [[ $FIREWALL_BLACKLIST == "yes" ]]
    then
      sudo service blacklistd restart
    fi

    sudo service sshd restart

    if [[ $2 == "dev" ]]
    then
      sudo pf -ef $DEV
    else
      sudo pf -ef $STABLE
    fi

    sudo service pflog restart
    sudo service pf restart
  ;;
  "dev")
    $0 restart dev
  ;;
  "stable")
    $0 restart stable
  ;;
  "blacklist")
    sudo cat >>$BLACKLIST <<CONF
[local]
ssh stream * * * 3 24h
CONF

    sudo cat >>$RC <<CONF
blacklist_enable="YES"
CONF
  ;;
  "pf")
    sudo cat >>$RC <<CONF
pf_enable="YES"
pflog_enable="YES"
CONF

    $0 restart stable
  ;;
  "help"|*)
    cat >/dev/stderr <<HELP
bsd.sh

onestart              = start pf services without global configuration
disable               = disable packet filter
enable                = enable the packet filter
stable                = load stable version of packet filter
dev                   = load development version of packet filter
check                 = check syntax of the packet filter
restart <dev|stable>  = restart stable firewall and related services
install               = install the development firewall into /etc/
info                  = show pf info
blacklist             = update the blacklist.conf file
pf                    = update rc.conf to load firewall
HELP
  ;;
esac

#! /usr/bin/env bash

HOST=`uname -a  | tr -s ' ' | cut -d ' ' -f 2`

REPO=$HOME/coding/firewall/pf
CONFIG=$REPO/${HOST}.sh

FIREWALL="$REPO/firewall.sh"

STABLE=/etc/pf.conf
DEV=$REPO/pf.conf

BLACKLIST=/etc/blacklistd.conf
RC=/etc/rc.conf
SYSCTL=/etc/sysctl.conf

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
  "permissions")
    echo >/dev/stderr "bsd.sh: unlocking system file permissions."

    su root chflags nouarch $BLACKLIST $RC $SYSCTL
    su root chgrp wheel $BLACKLIST $RC $SYSCTL
    su root chmod g+rw $BLACKLIST $RC $SYSCTL
  ;;
  "onestart")
    echo >/dev/stderr "bsd.sh: onestart loading kernel modules and launching system daemons."

    sudo kldload pf
    sudo service pflog onestart
    sudo service pf onestart
    sudo service blacklistd onestart
  ;;
  "flush")
    echo >/dev/stderr "bsd.sh: flushing firewall."

    sudo pfctl -F all
  ;;
  "list")
    echo /dev/stderr "bsd.sh listing firewall rules."

    sudo pfctl -sr
  ;;
  "disable")
    echo /dev/stderr "bsd.sh: disabling firewall."

    sudo pfctl -d
  ;;
  "enable")
    echo /dev/stderr "bsd.sh enabling firewall."

    sudo pfctl -ef $STABLE
  ;;
  "stable")
    echo /dev/stderr "bsd.sh installing dev firewall into system stable."

    sudo cp $DEV $STABLE
  ;;
  "dev")
    echo /dev/stderr "bsd,sh: generating and loading dev firewall."
    $FIREWALL >$DEV
  ;;
  "load")
    echo /dev/stderr "bsd.sh: loading dev firewall."

    sudo pfctl -ef $DEV
  ;;
  "check")
    echo /dev/stderr "bsd.sh: firewall dry run."

    $FIREWALL >$DEV
    pfctl -vnf $DEV
  ;;
  "install")
    echo /dev/stderr "bsd.sh install the firewall into the system."

    $0 dev
    $0 stable

    $0 blackhole
    $0 blacklist

    $0 pf
  ;;
  "info")
    echo /dev/stderr "bsd.sh: list information on sockets and firewall rules."

    sudo sockstat -4
    sudo pfctl -sr
  ;;
  "restart")
    echo /dev/stderr "bsd.sh: restarting all firewall services,"

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
    echo /dev/stderr "bsd.sh: restarting dev firewall."

    $0 restart dev
  ;;
  "stable")
    echo /dev/stderr "bsd.sh: restarting stable firewall."

    $0 restart stable
  ;;
  "blacklist")
    if [[ $FIREWALL_BLACKLIST == "yes" ]]
    then
      if grep -v blacklistd_enable $RC
      then
        sudo cat >>$RC <<CONF
sysrc blacklistd_enable="YES"
CONF
      fi
    else
      echo /dev/stderr "bsd.sh: skipping disabled blacklist configuration."
    fi
  ;;
  "blackhole")
    echo /dev/stderr "bsd.sh: installing blackhole firewall configuration."

    if grep -v net.inet.tcp.blackhole $SYSCTL && grep -v net.inet.tcp.blackhole $SYSCTL
    then
      sudo cat >>$SYSCTL <<CONF
net.inet.tcp.blackhole=2
net.inet.udp.blackhole=1
CONF
    fi
  ;;
  "pf")
    echo /dev/stderr "bsd.sh: installing pf configuration."

    if grep -v pf_enable $RC && grep -v pflog_enable $RC
    then
      sudo cat >>$RC <<CONF
pf_enable="YES"
pflog_enable="YES"
CONF
    fi
  ;;
  "help"|*)
    cat >/dev/stderr <<HELP
bsd.sh

onestart              = start pf services without global configuration
flush                 = flush all firewall rules
disable               = disable packet filter
list                  = show rules
enable                = enable the packet filter
stable                = load stable version of packet filter
dev                   = load development version of packet filter
check                 = check syntax of the packet filter
blackhole             = install blackhole configuration
blacklist             = update the blacklist.conf file
pf                    = update rc.conf to load firewall
restart <dev|stable>  = restart stable firewall and related services
install               = install the development firewall into /etc/
info                  = show pf info
HELP
  ;;
esac

# FireWall

Firewall is an implementation of advanced firewall practices in Linux
IPtables and FreeBSD pf.

It implements the basic Internet protocols, provides intrusion
detection, clients, servers, throttling, and blocking.

It is implemented as a shell script core with generation through a
library driven configuration. The library also acts as a command
wrapper around the system interface.

Currently the linux iptables firewall is a highly advanced
implementation featuring intrusion logging, limits and logging.

The pf for FreeBSD is in it's initial stages however it offers basic
firewall functionality, blacklistd, and blackhole.

The openBSD is advanced except for it's basic ICMP and broadcast
handling.




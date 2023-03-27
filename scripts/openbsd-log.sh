#! /usr/bin/env bash

exec doas tcpdump ${@} -n -l -r /var/log/pflog | tail -n 75 | less







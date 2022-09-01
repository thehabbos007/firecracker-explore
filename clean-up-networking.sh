#!/usr/bin/env bash

sudo iptables -F
sudo ip link del tap0
sudo sh -c "echo 0 > /proc/sys/net/ipv4/ip_forward" # usually the default

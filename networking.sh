#!/bin/bash

sudo ip tuntap add dev tap0 mode tap

sudo ip addr add 10.0.0.1/20 dev tap0
sudo ip link set tap0 up
ip addr show dev tap0

IFNAME=enp6s0

# Enable IP forwarding
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# Enable masquerading / NAT - https://tldp.org/HOWTO/IP-Masquerade-HOWTO/ipmasq-background2.5.html
sudo iptables -t nat -A POSTROUTING -o $IFNAME -j MASQUERADE
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tap0 -o $IFNAME -j ACCEPT

#!/bin/bash
set -e

# Allow us to route traffic that uses 127.0.0.1
echo "net.ipv4.conf.all.route_localnet=1" | tee --append /etc/sysctl.conf

# install iptables-persistent to persist iptables rules across reboots
export DEBIAN_FRONTEND=noninteractive
apt-get install -y iptables-persistent
# iptables-persistent is really named netfilter-persistent in 16.04
invoke-rc.d netfilter-persistent save
systemctl stop netfilter-persistent.service

# setup iptables rules to allow for Task IAM Roles
iptables -t nat -A PREROUTING -p tcp -d 169.254.170.2 --dport 80 -j DNAT --to-destination 127.0.0.1:51679
iptables -t nat -A OUTPUT -d 169.254.170.2 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 51679

# Save iptables rules
netfilter-persistent save

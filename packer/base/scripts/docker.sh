#!/bin/bash
set -e

apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get purge -y lxc-docker
apt-cache policy docker-engine

apt-get install -o Dpkg::Options::="--force-confold" -y \
        linux-image-extra-$(uname -r) \
        docker-engine

gpasswd -a ubuntu docker

systemctl daemon-reload
systemctl enable format-var-lib-docker.service
systemctl enable var-lib-docker.mount
systemctl enable docker.service

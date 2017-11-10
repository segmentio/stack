#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
systemctl disable apt-daily.service
systemctl disable apt-daily.timer

apt-get update -y

apt-get install -y \
        build-essential  \
        git \
        wget \
        dkms \
        apt-transport-https \
        ca-certificates \
        python-apt \
        python-pip \
        curl \
        netcat \
        ngrep \
        dstat \
        nmon \
        iptraf \
        iftop \
        iotop \
        atop \
        mtr \
        tree \
        unzip \
        sysdig \
        git \
        htop \
        jq \
        ntp \
        logrotate \
        dhcping \
        dhcpdump \
        nfs-common \
        curl \
        unzip \
        jq \

pip install awscli

apt-get upgrade -y

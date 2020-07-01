#!/bin/bash
set -e

wget -q -N -P /tmp/ "sourceforge.net/projects/e1000/files/ixgbevf stable/3.4.3/ixgbevf-3.4.3.tar.gz"
tar -xzf /tmp/ixgbevf-3.4.3.tar.gz
mv ixgbevf-3.4.3 /usr/src/

cat <<EOT | tee /usr/src/ixgbevf-3.4.3/dkms.conf
PACKAGE_NAME="ixgbevf"
PACKAGE_VERSION="3.4.3"
CLEAN="cd src/; make clean"
MAKE="cd src/; make BUILD_KERNEL=\${kernelver}"
BUILT_MODULE_LOCATION[0]="src/"
BUILT_MODULE_NAME[0]="ixgbevf"
DEST_MODULE_LOCATION[0]="/updates"
DEST_MODULE_NAME[0]="ixgbevf"
AUTOINSTALL="yes"
EOT

sed -i 's/#if UTS_UBUNTU_RELEASE_ABI > 255/#if UTS_UBUNTU_RELEASE_ABI > 99255/' /usr/src/ixgbevf-3.4.3/src/kcompat.h
dkms remove ixgbevf -v 3.4.3 --all 2>/dev/null || true
dkms add -m ixgbevf -v 3.4.3
dkms build -m ixgbevf -v 3.4.3
dkms install -m ixgbevf -v 3.4.3
update-initramfs -c -k all

echo "options ixgbevf InterruptThrottleRate=1,1,1,1,1,1,1,1" | tee /etc/modprobe.d/ixgbevf.conf
modinfo ixgbevf

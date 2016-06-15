#!/bin/bash
set -e

wget -q -N -P /tmp/ "sourceforge.net/projects/e1000/files/ixgbevf stable/3.1.2/ixgbevf-3.1.2.tar.gz"
tar -xzf /tmp/ixgbevf-3.1.2.tar.gz
mv ixgbevf-3.1.2 /usr/src/

cat <<EOT | tee /usr/src/ixgbevf-3.1.2/dkms.conf
PACKAGE_NAME="ixgbevf"
PACKAGE_VERSION="3.1.2"
CLEAN="cd src/; make clean"
MAKE="cd src/; make BUILD_KERNEL=\${kernelver}"
BUILT_MODULE_LOCATION[0]="src/"
BUILT_MODULE_NAME[0]="ixgbevf"
DEST_MODULE_LOCATION[0]="/updates"
DEST_MODULE_NAME[0]="ixgbevf"
AUTOINSTALL="yes"
EOT

dkms add -m ixgbevf -v 3.1.2
dkms build -m ixgbevf -v 3.1.2
dkms install -m ixgbevf -v 3.1.2
update-initramfs -c -k all

echo "options ixgbevf InterruptThrottleRate=1,1,1,1,1,1,1,1" | tee /etc/modprobe.d/ixgbevf.conf
modinfo ixgbevf

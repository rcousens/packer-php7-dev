#!/bin/bash -eux
#yum -y remove gcc cpp kernel-devel kernel-headers perl
yum -y clean all
rm -rf VBoxGuestAdditions_*.iso VBoxGuestAdditions_*.iso.?

# clean up redhat interface persistence
rm -f /etc/udev/rules.d/70-persistent-net.rules
#if [ -r /etc/sysconfig/network-scripts/ifcfg-eth0 ]; then
#  sed -i 's/^HWADDR.*$//' /etc/sysconfig/network-scripts/ifcfg-eth0
#  sed -i 's/^UUID.*$//' /etc/sysconfig/network-scripts/ifcfg-eth0
#fi
#! /bin/bash -eux

# remove vbox guest additions iso
yum -y clean all
rm -rf VBoxGuestAdditions_*.iso VBoxGuestAdditions_*.iso.?

# clean up redhat interface persistence
rm -f /etc/udev/rules.d/70-persistent-net.rules

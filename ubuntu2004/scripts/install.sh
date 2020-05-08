#!/bin/sh -eux

# Update the package list
apt-get -y update;

# Upgrade all installed packages incl. kernel and kernel headers
apt-get -y dist-upgrade -o Dpkg::Options::="--force-confnew";

##################################
### Install VBoxGuestAdditions ###
##################################

# set a default HOME_DIR environment variable if not set
HOME_DIR="/home/packer";

VER="`cat $HOME_DIR/.vbox_version`";
ISO="VBoxGuestAdditions_$VER.iso";
mkdir -p /tmp/vbox;
mount -o loop $HOME_DIR/$ISO /tmp/vbox;
sh /tmp/vbox/VBoxLinuxAdditions.run \
    || echo "VBoxLinuxAdditions.run exited $? and is suppressed." \
        "For more read https://www.virtualbox.org/ticket/12479";
umount /tmp/vbox;

# Delete tmp files and iso
rm -rf /tmp/vbox;
rm -f $HOME_DIR/*.iso;

## To be cleaned and completed... (maybe ansible ?)
#!/bin/sh
################################################################################
# Authors:
# - Pavel Demin <pavel.demin@uclouvain.be>
# - Iztok Jeras <iztok.jeras@redpitaya.com>
# License:
# https://raw.githubusercontent.com/RedPitaya/RedPitaya/master/COPYING
################################################################################

################################################################################
# prepating and mounting image
################################################################################

# current time and date are used to create the image name
DATE=`date +"%H-%M-%S_%d-%b-%Y"`

# the ABI (armel/armhf) provided by the compiler is used to create the image name
ARCH=armhf

# default image size if 3GB, which is appropriate for all 4BG SD cards
SIZE=3500

#IMAGE=$1
IMAGE=debian_${ARCH}_${DATE}.img

dd if=/dev/zero of=$IMAGE bs=1M count=$SIZE

DEVICE=`losetup -f`

losetup $DEVICE $IMAGE

BOOT_DIR=boot
ROOT_DIR=root

# Create partitions
parted -s $DEVICE mklabel msdos
parted -s $DEVICE mkpart primary fat16   4MB 128MB
parted -s $DEVICE mkpart primary ext4  128MB 100%

BOOT_DEV=/dev/`lsblk -lno NAME $DEVICE | sed '2!d'`
ROOT_DEV=/dev/`lsblk -lno NAME $DEVICE | sed '3!d'`

# Create file systems
mkfs.vfat -v    $BOOT_DEV
mkfs.ext4 -F -j $ROOT_DEV

# Mount file systems
mkdir -p $BOOT_DIR $ROOT_DIR
mount $BOOT_DEV $BOOT_DIR
mount $ROOT_DEV $ROOT_DIR

################################################################################
# install OS
################################################################################

OVERLAY=OS/debian/overlay

. OS/debian/debian.sh 

# enable chroot access with native execution
cp /etc/resolv.conf         $ROOT_DIR/etc/
cp /usr/bin/qemu-arm-static $ROOT_DIR/usr/bin/

. OS/debian/redpitaya.sh
#. OS/debian/wyliodrin.sh

# disable chroot access with native execution
rm $ROOT_DIR/etc/resolv.conf
rm $ROOT_DIR/usr/bin/qemu-arm-static

################################################################################
# umount image
################################################################################

# Unmount file systems
umount $BOOT_DIR $ROOT_DIR
rmdir $BOOT_DIR $ROOT_DIR

losetup -d $DEVICE

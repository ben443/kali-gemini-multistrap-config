#!/bin/sh

#pass path to the root. Don't let it run without one as it will break your system
if [ "" = "$1" ] ; then
    echo "You need to specify a path to the target rootfs"
    exit 1
else
    if [ -e "$1" ] ; then
        ROOTFS="$1"
        sudo mount proc -t proc $ROOTFS/proc
        sudo mount dev -t devtmpfs $ROOTFS/dev
        sudo mount devpts -t devpts $ROOTFS/dev/pts
        sudo mount sys -t sysfs $ROOTFS/sys
        sudo mount none -t tmpfs $ROOTFS/var/cache
        sudo mount none -t tmpfs $ROOTFS/tmp
        sudo mount none -t tmpfs $ROOTFS/root
        sudo mount none -t tmpfs $ROOTFS/var/log
    else
        echo "Root dir $ROOTFS not found"
        exit 1
    fi
fi

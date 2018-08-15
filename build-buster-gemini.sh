#!/bin/bash
## Customise this:
KERNEL_VER=7
SUITE=buster
SYS_IMG_FILE=system.img
ROOT_IMG_FILE=linux_root.img
DEBUG=1

#WHICH PARTS TO EXECUTE ( 0=Don't execute
#                         1=Execute
#                         2=Ask )
PURGE=2
CLEANUP=2
PREPARE=2
COMPILEKERNEL=2
PKGKERNEL=2
WRITEMULTISTRAPCFG=2
MULTISTRAP=2
ADDKERNELMODS=2
ADDQEMU=2
WRITEPOSTSETUP=2
WRITEROOTFSCFG=2
POSTSETUP=2
REMOVEQEMU=2
PREPAREIMG=2
CREATEIMG=2

# Packages to install
BUSTER_PACKAGES="task-lxqt-desktop ark bash-completion bluez breeze bzip2 chromium dosfstools exfat-utils file fonts-hack-ttf fonts-liberation fonts-noto fonts-noto-cjk fonts-noto-mono gdisk gstreamer1.0-plugins-base gtk3-engines-breeze gvfs-backends hunspell-en-us hyphen-en-us isc-dhcp-common iw kate kcharselect kde-style-breeze-qt4 kdelibs5-data kpackagelauncherqml kwin-x11 libfm-qt-l10n libglib2.0-data libkf5config-bin libkf5dbusaddons-bin libkf5globalaccel-bin libkf5iconthemes-bin libkf5xmlgui-bin liblxqt-l10n libreoffice libreoffice-gtk2 libreoffice-librelogo libvlc-bin locales lxc lximage-qt lximage-qt-l10n lxqt-about-l10n lxqt-admin-l10n lxqt-config-l10n lxqt-globalkeys-l10n lxqt-notificationd-l10n lxqt-openssh-askpass-l10n lxqt-panel-l10n lxqt-policykit-l10n lxqt-powermanagement-l10n lxqt-runner-l10n lxqt-session-l10n lxqt-sudo lxqt-sudo-l10n mythes-en-us ncurses-term net-tools ntfs-3g p7zip-full pavucontrol-qt pavucontrol-qt-l10n pcmanfm-qt-l10n policykit-1 psmisc qlipper qpdfview qpdfview-djvu-plugin qpdfview-ps-plugin qpdfview-translations qt5-gtk-platformtheme qt5-image-formats-plugins qterminal qterminal-l10n qttranslations5-l10n rename rsync rtkit saytime smplayer smplayer-l10n smplayer-themes ssh sudo unzip upower wget wpasupplicant xdg-user-dirs xdg-utils xz-utils youtube-dl"
GEMIAN_PACKAGES="hybris-usb lxc-android libhybris drihybris glamor-hybris xserver-xorg-video-hwcomposer pulseaudio-module-droid ofono repowerd xss-lock gemian-lock gemian-leds cmst"
## End customising


PROG_NAME="$0"
CURRENT_DATE=`date +%Y%m%d`
REAL_PATH=$(realpath $PROG_NAME)
DIR_NAME=$(dirname $REAL_PATH)
BASE_NAME=$(basename $PROG_NAME)
BUILD_DIR=$(dirname $DIR_NAME)
OUT_DIR=${BUILD_DIR}/ROOTFS_OUT
ROOTFS=${OUT_DIR}/$SUITE
CONFIG=$SUITE-gemini.conf
POSTSETUP_SCRIPT=${DIR_NAME}/kali-gemini-prep-chroot.sh
ROOTFS_CONFIG_SCRIPT=${DIR_NAME}/kali-gemini-rootfs-config.sh
SYS_IMG=${BUILD_DIR}/SYSIMG/$SYS_IMG_FILE
CROSS_COMPILER=${BUILD_DIR}/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_SRC=${BUILD_DIR}/kernel-3.18
KERNEL_CONFIG=$KERNEL_SRC/arch/arm64/configs/kali_gemini_defconfig
RAMDISK=${BUILD_DIR}/RAMDISK/ramdisk.cpio.gz
KERNEL_OUT=${BUILD_DIR}/KERNEL_OUT
MODULES_OUT=${BUILD_DIR}/MODULES_OUT
KERNELIMG_OUT=${BUILD_DIR}/KERNELIMG_OUT
MKBOOTIMG=${BUILD_DIR}/mkbootimg/mkbootimg
ROOT_IMG=${BUILD_DIR}/ROOTIMG_OUT/$CURRENT_DATE-$ROOT_IMG_FILE
TMP_MNT=/tmp/temp_mount/

function do_print_vars {

    printf "\nPROG_NAME = ${PROG_NAME}\n"
    printf "REAL_PATH = ${REAL_PATH}\n"
    printf "DIR_NAME = ${DIR_NAME}\n"
    printf "BUILD_DIR = ${BUILD_DIR}\n"
    printf "OUT_DIR = ${OUT_DIR}\n"
    printf "ROOTFS = ${ROOTFS}\n"
    printf "CONFIG = $CONFIG\n"
    printf "POSTSETUP_SCRIPT = ${POSTSETUP_SCRIPT}\n"
    printf "ROOTFS_CONFIG_SCRIPT = ${ROOTFS_CONFIG_SCRIPT}\n"
    printf "CROSS_COMPILER = ${CROSS_COMPILER}\n"
    printf "KERNEL_SRC = ${KERNEL_SRC}\n"
    printf "KERNEL_CONFIG = ${KERNEL_CONFIG}\n"
    printf "RAMDISK = ${RAMDISK}\n"
    printf "KERNEL_OUT = ${KERNEL_OUT}\n"
    printf "MODULES_OUT = ${MODULES_OUT}\n"
    printf "KERNELIMG_OUT = ${KERNELIMG_OUT}\n"
    printf "MKBOOTIMG = ${MKBOOTIMG}\n"
    printf "SYS_IMG = ${SYS_IMG}\n"
    printf "TMP_MNT = ${TMP_MNT}\n"
    printf "SUDO_USER = $SUDO_USER\n"
    printf "\n"
}

function set_sudo_user() {
  if [ -z "$SUDO_USER" ]; then
    SUDO_USER=root
  fi
}

function ask() {
    # http://djm.me/ask
    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question
        printf "\t+++++ "
        read -p "$1 [$prompt] " REPLY

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

function exitonerr {
    # via: http://stackoverflow.com/a/5196108
    "$@"
    local status=$?

    if [ $status -ne 0 ]; then
        echo "Error completing: $1" >&2
        exit 1
    fi

    return $status
}

function do_prepare {
    printf "\t*****     Preparing build environment\n"
    if [ ! -d ${OUT_DIR} ]; then
        mkdir -p ${OUT_DIR}
	chown $SUDO_USER:$SUDO_USER ${OUT_DIR}
    fi
    if [ ! -d ${KERNEL_OUT} ]; then
        mkdir -p ${KERNEL_OUT}
	chown $SUDO_USER:$SUDO_USER ${KERNEL_OUT}
    fi
    if [ ! -d ${KERNELIMG_OUT} ]; then
        mkdir -p ${KERNELIMG_OUT}
	chown $SUDO_USER:$SUDO_USER ${KERNELIMG_OUT}
    fi
    if [ ! -d ${MODULES_OUT} ]; then
        mkdir -p ${MODULES_OUT}
	chown $SUDO_USER:$SUDO_USER ${MODULES_OUT}
    fi
    if [ ! -d ${ROOTFS} ]; then
        mkdir -p ${ROOTFS}
	chown $SUDO_USER:$SUDO_USER ${ROOTFS}
    fi
    if [ ! -d $(dirname ${ROOT_IMG}) ]; then
        mkdir -p $(dirname $ROOT_IMG)
	chown $SUDO_USER:$SUDO_USER $(dirname $ROOT_IMG)
    fi
}

function do_compile_kernel {
    if ask "  - Reset kernel config?" "Y"; then
        printf "\t****     Using kernel config ${KERNEL_CONFIG} ****\n"
        cp ${KERNEL_CONFIG} $KERNEL_OUT/.config
    fi
    if ask "  - Reset kernel version to ${KERNEL_VER}?" "Y"; then
        ((version = $KERNEL_VER -1)) 
        printf "\t****     Setting  kernel version to ${KERNEL_VER} ****\n"
        echo $version > ${KERNEL_OUT}/.version
    fi
    NUM_CPUS=`nproc`
    make O=$KERNEL_OUT -C $KERNEL_SRC ARCH=arm64  CROSS_COMPILE=$CROSS_COMPILER menuconfig 
    make O=$KERNEL_OUT -C $KERNEL_SRC ARCH=arm64  CROSS_COMPILE=$CROSS_COMPILER -j${NUM_CPUS}
    make O=$KERNEL_OUT -C $KERNEL_SRC ARCH=arm64  CROSS_COMPILE=$CROSS_COMPILER -j${NUM_CPUS} modules
}

function do_package_kernel {
    OUT_DIR=$KERNELIMG_OUT/$CURRENT_DATE-$KERNEL_VER
    if [ ! -d ${OUT_DIR} ]; then
        mkdir -p ${OUT_DIR}
	chown $SUDO_USER:$SUDO_USER ${OUT_DIR}
    fi
    $MKBOOTIMG \
    --kernel $KERNEL_OUT/arch/arm64/boot/Image.gz-dtb \
    --ramdisk $RAMDISK \
    --base 0x40080000 \
    --second_offset 0x00e80000 \
    --cmdline "bootopt=64S3,32N2,64N2 log_buf_len=4M" \
    --kernel_offset 0x00000000 \
    --ramdisk_offset 0x04f80000 \
    --tags_offset 0x03f80000 \
    --pagesize 2048 \
    -o $OUT_DIR/linux_boot.img

    chown $SUDO_USER:$SUDO_USER OUT_DIR/linux_boot.img

    cp $KERNEL_OUT/.config $OUT_DIR
    chown $SUDO_USER:$SUDO_USER OUT_DIR/.config

    make O=$KERNEL_OUT -C $KERNEL_SRC ARCH=arm64  CROSS_COMPILE=$CROSS_COMPILER -j${NUM_CPUS} INSTALL_MOD_PATH=$MODULES_OUT modules_install
    rm $MODULES_OUT/lib/modules/3.18.41-kali+/build
    rm $MODULES_OUT/lib/modules/3.18.41-kali+/source
    tar -C $MODULES_OUT -cJf $OUT_DIR/modules-3.18.41-kali#$KERNEL_VER.tar.xz lib
    chown $SUDO_USER:$SUDO_USER $OUT_DIR/modules-3.18.41-kali#$KERNEL_VER.tar.xz
}
    

function write_multistrap_config {
    printf "\t*****     Generating multistrap configuration\n"
    cat > ${DIR_NAME}/$CONFIG <<EOF
[General]
arch=arm64
directory=${ROOTFS}
# same as --tidy-up option if set to true
cleanup=true
# same as --no-auth option if set to true
# keyring packages listed in each bootstrap will
# still be installed.
noauth=true
# extract all downloaded archives (default is true)
unpack=true
# whether to add the /suite to be explicit about where apt
# needs to look for packages. Default is false.
explicitsuite=false
# this setupscript is to properly mount filesystems for configuration step
# and copy files
configscript=$POSTSETUP_SCRIPT
# copied into the chroot to be executed later
configscript=$ROOTFS_CONFIG_SCRIPT
# add packages of Priority: important
addimportant=true
# allow Recommended packages to be seen as strict dependencies
# allowrecommends=false
# enable MultiArch for the specified architectures
# default is empty
multiarch=
# aptsources is a list of sections to be used
# the /etc/apt/sources.list.d/multistrap.sources.list
# of the target. Order is not important
aptsources=Buster Gemian
# the bootstrap option determines which repository
# is used to calculate the list of Priority: required packages
# and which packages go into the rootfs.
# The order of sections is not important.
bootstrap=Buster Gemian

[Buster]
packages=${BUSTER_PACKAGES}
source=http://mirror.aarnet.edu.au/debian
keyring=debian-archive-keyring
suite=buster

[Gemian]
packages=$GEMIAN_PACKAGES
source=http://gemian.thinkglobally.org/buster/
suite=buster
components=main
EOF
    chown $SUDO_USER:$SUDO_USER ${DIR_NAME}/$CONFIG
}

function do_multistrap {
    printf "\t*****     Multistrapping\n"
    multistrap -d ${ROOTFS} -f $CONFIG
}

function do_add_kernel_modules {
    printf "\t*****     Installing kernel modules\n"
    rsync --progress -a ${MODULES_OUT}/lib/* ${ROOTFS}/lib/
}

function do_add_qemu {
    printf "\t*****     Adding qemu\n"
    cp /usr/bin/qemu-aarch64-static $ROOTFS/usr/bin/
}

function do_remove_qemu {
    printf "\t*****     Removing qemu\n"
    rm -f $ROOTFS/usr/bin/qemu-aarch64-static
}

function write_postsetup_script {
    printf "\t*****     Generating postsetup script\n"
    cat > ${POSTSETUP_SCRIPT} <<EOF
#!/bin/sh

#pass path to the root. Don't let it run without one as it will break your system
if [ "" = "\$1" ] ; then
    echo "You need to specify a path to the target rootfs"
    exit 1
else
    if [ -e "\$1" ] ; then
        ROOTFS="\$1"
        sudo mount proc -t proc \$ROOTFS/proc
        sudo mount dev -t devtmpfs \$ROOTFS/dev
        sudo mount devpts -t devpts \$ROOTFS/dev/pts
        sudo mount sys -t sysfs \$ROOTFS/sys
        sudo mount none -t tmpfs \$ROOTFS/var/cache
        sudo mount none -t tmpfs \$ROOTFS/tmp
        sudo mount none -t tmpfs \$ROOTFS/root
        sudo mount none -t tmpfs \$ROOTFS/var/log
    else
        echo "Root dir \$ROOTFS not found"
        exit 1
    fi
fi
EOF

    chmod 755 ${POSTSETUP_SCRIPT}
    chown $SUDO_USER:$SUDO_USER ${POSTSETUP_SCRIPT}
}

function write_rootfs_config_script {
    printf "\t*****     Generating post configuration script\n"
    cat > ${ROOTFS_CONFIG_SCRIPT} <<EOF
#!/bin/sh
mkdir /nvcfg
mkdir /nvdata
mkdir /system
mkdir /data
ln -s system/vendor /vendor

systemctl enable usb-tethering
systemctl enable ssh

systemctl enable system.mount
systemctl enable tmp.mount
systemctl enable android-mount.service
systemctl enable droid-hal-init
systemctl enable lxc@android.service

systemctl disable isc-dhcp-server.service  isc-dhcp-server6.service lxc-net.service ureadahead.service systemd-modules-load.service
systemctl disable connman-wait-online.service

echo "nameserver 8.8.8.8" > /etc/resolv.conf
wget -O - http://gemian.thinkglobally.org/archive-key.asc | sudo apt-key add -

update-alternatives --set aarch64-linux-gnu_egl_conf /usr/lib/aarch64-linux-gnu/libhybris-egl/ld.so.conf
mkdir /usr/lib/aarch64-linux-gnu/mesa-egl
mv /usr/lib/aarch64-linux-gnu/libGLESv* /usr/lib/aarch64-linux-gnu/libEGL.so* /usr/lib/aarch64-linux-gnu/mesa-egl

ldconfig

# PulseAudio
# /etc/pulseaudio/default.pa

groupadd -g 1001 radio
useradd -u 1001 -g 1001 -s /usr/sbin/nologin radio

groupadd -g 1000 aid_system
groupadd -g 1003 aid_graphics
groupadd -g 1004 aid_input
groupadd -g 1005 aid_audio
groupadd -g 3001 aid_net_bt_admin
groupadd -g 3002 aid_net_bt
groupadd -g 3003 aid_inet
groupadd -g 3004 aid_inet_raw
groupadd -g 3005 aid_inet_admin
groupadd -g 100000 gemini

useradd -m -u 100000 -g 100000 -G audio,video,sudo,aid_system,aid_graphics,aid_input,aid_audio,aid_net_bt_admin,aid_net_bt,aid_inet,aid_inet_raw,aid_inet_admin -s /bin/bash gemini

echo "gemini:gemini" | chpasswd
echo "root:toor" | chpasswd

ln -sf ../lib/systemd/systemd /sbin/init

# Hack for chromium
mkdir -p /usr/lib/chromium
ln -sf /usr/lib/aarch64-linux-gnu/libhybris-egl/libEGL.so.1.0.0 /usr/lib/chromium/libEGL.so
ln -sf /usr/lib/aarch64-linux-gnu/libhybris-egl/libGLESv2.so.2.0.0 /usr/lib/chromium/libGLESv2.so
EOF

    chmod 755 ${ROOTFS_CONFIG_SCRIPT}
    chown $SUDO_USER:$SUDO_USER ${ROOTFS_CONFIG_SCRIPT}
}

function do_postsetup {
    printf "\t*****     Running post configuration scripts in rootfs\n"
    ${POSTSETUP_SCRIPT} $ROOTFS
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
      LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS dpkg --configure -a
    cp -rv configs/* $ROOTFS

    cp ${ROOTFS_CONFIG_SCRIPT} $ROOTFS/config.sh
    chroot $ROOTFS /config.sh
    rm $ROOTFS/config.sh

    cp ${SYS_IMG} $ROOTFS/data/


    umount -l $ROOTFS/proc
    umount -l $ROOTFS/dev/pts
    umount -l $ROOTFS/dev
    umount -l $ROOTFS/sys
    umount -l $ROOTFS/var/cache
    umount -l $ROOTFS/tmp
    umount -l $ROOTFS/root
    umount -l $ROOTFS/var/log
}

function do_prepare_img {
    printf "\t*****     Preparing image file\n"
    size=$(du -sm $ROOTFS | cut -f1)
    size=$(($size + 400))
    if [ debug = 1 ]; then
        printf "\nPROG_NAME = $size\n"
        return 0
    fi
    dd if=/dev/zero of=${ROOT_IMG} bs=1M count=$size
    mkfs ext4 -F ${ROOT_IMG}
    chown $SUDO_USER:$SUDO_USER ${ROOT_IMG}
}

function do_create_img {
    printf "\t*****     Filling image file\n"
    if [ ! -d ${TMP_MNT} ]; then
        mkdir -p ${TMP_MNT}
    fi
    mount -o loop,rw,sync ${ROOT_IMG} ${TMP_MNT}
    rsync --progress -a ${ROOTFS}/* ${TMP_MNT}
    umount ${TMP_MNT}
}

function do_purge {
    printf "\t*****     Purging files from previous runs\n"
    rm -fr $ROOTFS
    rm -fr $KERNEL_OUT
    rm -fr $MODULES_OUT
    do_cleanup
}

function do_cleanup {
    printf "\t*****     Deleting configuration files from previous runs\n"
    rm -f $POSTSETUP_SCRIPT
    rm -f $ROOTFS_CONFIG_SCRIPT
    rm -f ${DIR_NAME}/$CONFIG
}

if [ $(id -u) -ne 0 ]; then
  printf "\nProgram must be run as root. Try 'sudo ${PROG_NAME}'\n\n"
  exit 1
fi



## Main
set_sudo_user

if [ $DEBUG == 1 ]; then
    do_print_vars
fi

if ask "Purge files from previous builds?" "Y"; then
    if [ $PURGE == 1 ] || ([ $PURGE == 2 ] && ask "  - Delete rootfs from previous builds?" "Y"); then
        do_purge
    fi
    if [ $CLEANUP == 1 ] || ([ $CLEANUP == 2 ] && ask "  - Delete configuration files from previous builds?" "Y"); then
        do_cleanup
    fi
fi
if ask "Create build environment?" "Y"; then
    if [ $PREPARE == 1 ] || ([ $PREPARE == 2 ] && ask "  - Prepare build environment?" "Y"); then
        do_prepare
    fi
    if [ $WRITEMULTISTRAPCFG == 1 ] || ([ $WRITEMULTISTRAPCFG == 2 ] && ask "  - Create multistrap configuration?" "Y"); then
        write_multistrap_config
    fi
    if [ $WRITEPOSTSETUP == 1 ] || ([ $WRITEPOSTSETUP == 2 ] && ask "  - Create postsetup script?" "Y"); then
        write_postsetup_script
    fi
    if [ $WRITEROOTFSCFG == 1 ] || ([ $WRITEROOTFSCFG == 2 ] && ask "  - Create rootfs configuration script?" "Y"); then
        write_rootfs_config_script
    fi
fi
if ask "Compile custom kernel?" "Y"; then
    if [ $COMPILEKERNEL == 1 ] || ([ $COMPILEKERNEL == 2 ] && ask "  - Compile kernel?" "Y"); then
        do_compile_kernel
    fi
    if [ $PKGKERNEL == 1 ] || ([ $PKGKERNEL == 2 ] && ask "  - Package kernel?" "Y"); then
        do_package_kernel
    fi
fi
if ask "Create rootfs?" "Y"; then
    if [ $MULTISTRAP == 1 ] || ([ $MULTISTRAP == 2 ] && ask "  - Run multistrap to create rootfs?" "Y"); then
        do_multistrap
    fi
    if [ $ADDQEMU == 1 ] || ([ $ADDQEMU == 2 ] && ask "  - Add qemu?" "Y"); then
        do_add_qemu
    fi
    if [ $ADDKERNELMODS == 1 ] || ([ $ADDKERNELMODS == 2 ] && ask "  - Install kernel modules from ${MODULES_OUT}?" "Y"); then
        do_add_kernel_modules
    fi
    if [ $POSTSETUP == 1 ] || ([ $POSTSETUP == 2 ] && ask "  - Configure rootfs?" "Y"); then
        do_postsetup
    fi
    if [ $REMOVEQEMU == 1 ] || ([ $REMOVEQEMU == 2 ] && ask "  - Remove qemu?" "Y"); then
        do_remove_qemu
    fi
fi
if ask "Create image?" "Y"; then
    if [ $PREPAREIMG == 1 ] || ([ $PREPAREIMG == 2 ] && ask "  - Prepare image?" "Y"); then
        do_prepare_img
    fi
    if [ $CREATEIMG == 1 ] || ([ $CREATEIMG == 2 ] && ask "  - Copy rootfs to new image file?" "Y"); then
        do_create_img
    fi
fi
if ask "Purge temporary files from this build?" "Y"; then
    if [ $PURGE == 1 ] || ([ $PURGE == 2 ] && ask "  - Delete rootfs from previous build?" "Y"); then
        do_purge
    fi
    if [ $CLEANUP == 1 ] || ([ $CLEANUP == 2 ] && ask "  - Delete configuration files from previous build?" "Y"); then
        do_cleanup
    fi
fi




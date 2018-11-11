#!/bin/bash
## Customise this:
KERNEL_VER=9
SUITE=kali
HOSTNAME=kali
SYS_IMG_FILE=system.img
ROOT_IMG_FILE=linux_root.img
DEBUG=1

#WHICH PARTS TO EXECUTE ( 0=Don't execute
#                         1=Execute
#                         2=Ask )
PURGE=2
PURGEKERNEL=0
CLEANUP=2
PREPARE=2
COMPILEKERNEL=0
PKGKERNEL=0
WRITEMULTISTRAPCFG=2
MULTISTRAP=2
ADDKERNELMODS=0
ADDQEMU=2
WRITEPOSTSETUP=2
WRITEROOTFSCFG=2
WRITEAPTPREF=2
POSTSETUP=2
REMOVEQEMU=2
PREPAREIMG=2
CREATEIMG=2
ARCHIVEKERNEL=0
ARCHIVEROOTFS=2

# Packages to install
KALI_KALI="kali-defaults kali-menu desktop-base kali-linux-top10 kali-root-login firmware-realtek firmware-atheros firmware-libertas"
KALI_GENERIC="task-lxqt-desktop ark bash-completion bluez breeze bzip2 dosfstools exfat-utils file firefox-esr fonts-hack-ttf fonts-liberation fonts-noto fonts-noto-cjk fonts-noto-mono gdisk gstreamer1.0-plugins-base gtk3-engines-breeze gvfs-backends hunspell-en-us hyphen-en-us isc-dhcp-common iw kate kcharselect kde-style-breeze-qt4 kdelibs5-data kpackagelauncherqml kwin-x11 libfm-qt-l10n libglib2.0-data libkf5config-bin libkf5dbusaddons-bin libkf5globalaccel-bin libkf5iconthemes-bin libkf5xmlgui-bin liblxqt-l10n libvlc-bin locales lxc lximage-qt lximage-qt-l10n lxqt-about-l10n lxqt-admin-l10n lxqt-config-l10n lxqt-globalkeys-l10n lxqt-notificationd-l10n lxqt-openssh-askpass-l10n lxqt-panel-l10n lxqt-policykit-l10n lxqt-powermanagement-l10n lxqt-runner-l10n lxqt-session-l10n lxqt-sudo lxqt-sudo-l10n mythes-en-us ncurses-term net-tools ntfs-3g p7zip-full pavucontrol-qt pavucontrol-qt-l10n pcmanfm-qt-l10n policykit-1 psmisc qlipper qpdfview qpdfview-djvu-plugin qpdfview-ps-plugin qpdfview-translations qt5-gtk-platformtheme qt5-image-formats-plugins qterminal qterminal-l10n qttranslations5-l10n rename rsync rtkit saytime ssh sudo unzip upower wget wpasupplicant xdg-user-dirs xdg-utils xz-utils youtube-dl"
KALI_PACKAGES="${KALI_KALI} ${KALI_GENERIC}"
GEMINI_PACKAGES="kali-gemini-linux kali-hw-gemini hybris-usb lxc-android libhybris drihybris glamor-hybris xserver-xorg-video-hwcomposer pulseaudio-module-droid libpulse0 pulseaudio ofono repowerd xss-lock gemian-lock gemian-leds cmst connman-plugin-suspend-wmtwifi"
## End customising


PROG_NAME="$0"
CURRENT_DATE=`date +%Y%m%d`
REAL_PATH=$(realpath $PROG_NAME)
DIR_NAME=$(dirname $REAL_PATH)
BASE_NAME=$(basename $PROG_NAME)
BUILD_DIR=$(dirname $DIR_NAME)
OUT_DIR=${BUILD_DIR}/ROOTFS_OUT
ARCH_DIR=${BUILD_DIR}/ARCHIVE
ROOTFS=${OUT_DIR}/$SUITE
CONFIG=$SUITE-gemini.conf
APTPREFERENCES=${DIR_NAME}/preferences
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
KERNELARCH=$ARCH_DIR/$(basename $KERNEL_SRC)-$KERNEL_VER-$CURRENT_DATE-$SUITE.tar.xz
ROOTFSARCH=$ARCH_DIR/$SUITE-unconfigured-no-modules-$CURRENT_DATE.tar.xz

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
    printf "APT PREFERENCES = ${APTPREFERENCES}\n"
    printf "CROSS_COMPILER = ${CROSS_COMPILER}\n"
    printf "KERNEL_SRC = ${KERNEL_SRC}\n"
    printf "KERNEL_CONFIG = ${KERNEL_CONFIG}\n"
    printf "RAMDISK = ${RAMDISK}\n"
    printf "KERNEL_OUT = ${KERNEL_OUT}\n"
    printf "MODULES_OUT = ${MODULES_OUT}\n"
    printf "KERNELIMG_OUT = ${KERNELIMG_OUT}\n"
    printf "KERNELARCH = ${KERNELARCH}\n"
    printf "ROOTFSARCH = ${ROOTFSARCH}\n"
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
    if [ ! -d ${ARCH_DIR} ]; then
        mkdir -p ${ARCH_DIR}
        chown $SUDO_USER:$SUDO_USER ${ARCH_DIR}
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

    chown $SUDO_USER:$SUDO_USER $OUT_DIR/linux_boot.img

    cp $KERNEL_OUT/.config $OUT_DIR
    chown $SUDO_USER:$SUDO_USER $OUT_DIR/.config

    make O=$KERNEL_OUT -C $KERNEL_SRC ARCH=arm64  CROSS_COMPILE=$CROSS_COMPILER -j${NUM_CPUS} INSTALL_MOD_PATH=$MODULES_OUT modules_install
    rm $MODULES_OUT/lib/modules/3.18.41-kali+/build
    rm $MODULES_OUT/lib/modules/3.18.41-kali+/source
    tar -C $MODULES_OUT -czf $OUT_DIR/kali-gemini-linux-3.18.41.$KERNEL_VER.tar.gz lib
    chown $SUDO_USER:$SUDO_USER $OUT_DIR/kali-gemini-linux-3.18.41.$KERNEL_VER.tar.gz
}
    
function do_archive_kernel {
    tar -C ${BUILD_DIR} -I pxz -cf ${KERNELARCH} $(basename $KERNEL_OUT) $(basename $MODULES_OUT)
    chown $SUDO_USER:$SUDO_USER ${KERNELARCH}
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
aptsources=Kali Gemini
aptpreferences=$APTPREFERENCES
# the bootstrap option determines which repository
# is used to calculate the list of Priority: required packages
# and which packages go into the rootfs.
# The order of sections is not important.
bootstrap=Kali Gemini

[Kali]
packages=$KALI_PACKAGES
source=http://http.kali.org/kali
keyring=kali-archive-keyring
suite=kali-rolling
components=main contrib non-free

[Gemini]
packages=$GEMINI_PACKAGES
source=http://http.re4son-kernel.com/re4son/
suite=kali-gem
components=main
EOF
    chown $SUDO_USER:$SUDO_USER ${DIR_NAME}/$CONFIG
}

function do_multistrap {
    printf "\t*****     Multistrapping\n"
    multistrap -d ${ROOTFS} -f $CONFIG
}

function do_archive_rootfs {
    tar -C ${OUT_DIR} -I pxz -cf ${ROOTFSARCH} $(basename $ROOTFS)
    chown $SUDO_USER:$SUDO_USER ${ROOTFSARCH}
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
groupadd -g 1010 mysql
useradd -r -g mysql -s /bin/false mysql

mkdir -p /var/log/apache2
mkdir -p /var/log/samba
mkdir -p /var/cache/samba

## Multistrap only extracted the packages and didn't run any
## preinst scripts so lets run them now
/var/lib/dpkg/info/dash.preinst install
/var/lib/dpkg/info/kali-hw-gemini.preinst install
dpkg --configure -a

# sddm-breeze-theme may not be installed properly
# This will stuff up the proper kali theming
# Let's create a link to the existing debian theme if necessary
if [ ! -e /usr/share/sddm/themes/breeze ]; then
	ln -s /etc/alternatives/sddm-debian-theme /usr/share/sddm/themes/breeze
fi

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
systemctl enable connman.service
systemctl enable gemian-leds
systemctl enable bluetooth
systemctl enable repowerd

systemctl disable isc-dhcp-server.service  isc-dhcp-server6.service lxc-net.service ureadahead.service systemd-modules-load.service
systemctl disable connman-wait-online.service

cat << EFO > /lib/systemd/system/resizefs.service
[Unit]
Description=Resize filesystem
After=local-fs.target
[Service]
Type=oneshot
ExecStart=/bin/sh -c "sudo resize2fs -p \$(findmnt -n -o SOURCE /)"
ExecStartPost=/bin/systemctl disable resizefs
[Install]
WantedBy=multi-user.target
EFO
chmod 644 /lib/systemd/system/resizefs.service

cat << EFO > /lib/systemd/system/gemini-lights.service
[Unit]
Description=Initialize lights on Gemini
After=local-fs.target
[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo \"7 0 0 0 \" > /proc/aw9120_operation"
[Install]
WantedBy=multi-user.target
EFO
chmod 644 /lib/systemd/system/gemini-lights.service

systemctl enable resizefs
systemctl enable gemini-lights


echo "nameserver 8.8.8.8" > /etc/resolv.conf
wget -O - http://http.re4son-kernel.com/archive-key.asc | sudo apt-key add -

# Fix dhcp client bug
touch /etc/fstab

update-alternatives --set aarch64-linux-gnu_egl_conf /usr/lib/aarch64-linux-gnu/libhybris-egl/ld.so.conf

## mkdir /usr/lib/aarch64-linux-gnu/mesa-egl
## mv /usr/lib/aarch64-linux-gnu/libGLESv* /usr/lib/aarch64-linux-gnu/libEGL.so* /usr/lib/aarch64-linux-gnu/mesa-egl
ln -s /usr/lib/aarch64-linux-gnu/libhybris-egl/ld.so.conf /etc/ld.so.conf.d/01_libhybris-egl.conf
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
groupadd -g 100000 kali

useradd -m -u 100000 -g 100000 -G audio,video,sudo,aid_system,aid_graphics,aid_input,aid_audio,aid_net_bt_admin,aid_net_bt,aid_inet,aid_inet_raw,aid_inet_admin -s /bin/bash kali

echo "kali:kali" | chpasswd
echo "root:toor" | chpasswd

ln -sf ../lib/systemd/systemd /sbin/init

# Hack for chromium
mkdir -p /usr/lib/chromium
ln -sf /usr/lib/aarch64-linux-gnu/libhybris-egl/libEGL.so.1.0.0 /usr/lib/chromium/libEGL.so
ln -sf /usr/lib/aarch64-linux-gnu/libhybris-egl/libGLESv2.so.2.0.0 /usr/lib/chromium/libGLESv2.so


echo 'LANG="en_US.UTF-8"\n' > /etc/default/locale

echo "${HOSTNAME}" > /etc/hostname


cat << EFO > /etc/hosts
127.0.0.1       ${HOSTNAME}    localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EFO

EOF

    chmod 755 ${ROOTFS_CONFIG_SCRIPT}
    chown $SUDO_USER:$SUDO_USER ${ROOTFS_CONFIG_SCRIPT}
}

function write_aptpreferences {
    printf "\t*****     Generating apt preferences\n"
    FILES=configs/etc/apt/preferences.d/*
    > ${APTPREFERENCES}
    for f in $FILES
    do
        cat $f >> ${APTPREFERENCES}
    done
}

function do_postsetup {
    printf "\t*****     Running post configuration scripts in rootfs\n"
    ##cp -rv configs/* $ROOTFS
    cp -rv $ROOTFS/etc/skel/.config $ROOTFS/root/
    ${POSTSETUP_SCRIPT} $ROOTFS
    cp ${ROOTFS_CONFIG_SCRIPT} $ROOTFS/config.sh
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS /config.sh
    rm $ROOTFS/etc/apt/preferences.d/preferences
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
    size=$(($size + 500))
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
    rsync -av ${ROOTFS}/* ${TMP_MNT}
    umount ${TMP_MNT}
}

function do_purge {
    printf "\t*****     Purging files from previous runs\n"
    rm -fr $ROOTFS
}

function do_purgekernel {
    printf "\t*****     Purging kernel files from previous runs\n"
    rm -fr $KERNEL_OUT
    rm -fr $MODULES_OUT
}

function do_cleanup {
    printf "\t*****     Deleting configuration files from previous runs\n"
    rm -f $POSTSETUP_SCRIPT
    rm -f $ROOTFS_CONFIG_SCRIPT
    rm -f ${DIR_NAME}/$CONFIG
    rm -f ${APTPREFERENCES}
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

if ([ $PURGE == 1 ] || [ $PURGEKERNEL == 1 ] || [ $CLEANUP == 1 ]) || \
  (([ $PURGE == 2 ] || [ $PURGEKERNEL == 2 ] || [ $CLEANUP == 2 ]) && \
  ask "Purge files from previous builds?" "Y"); then
    if [ $PURGE == 1 ] || ([ $PURGE == 2 ] && ask "  - Delete rootfs from previous builds?" "Y"); then
        do_purge
    fi
    if [ $PURGEKERNEL == 1 ] || ([ $PURGEKERNEL == 2 ] && ask "  - Delete kernels from previous builds?" "Y"); then
        do_purgekernel
    fi
    if [ $CLEANUP == 1 ] || ([ $CLEANUP == 2 ] && ask "  - Delete configuration files from previous builds?" "Y"); then
        do_cleanup
    fi
fi
if ([ $PREPARE == 1 ] || [ $WRITEAPTPREF == 1 ] || [ $WRITEPOSTSETUP  == 1 ] || [ $WRITEROOTFSCFG  == 1 ]) || \
  (([ $PREPARE == 2 ] || [ $WRITEAPTPREF == 2 ] || [ $WRITEPOSTSETUP  == 2 ] || [ $WRITEROOTFSCFG  == 2 ]) && \
  ask "Create build environment?" "Y"); then
    if [ $PREPARE == 1 ] || ([ $PREPARE == 2 ] && ask "  - Prepare build environment?" "Y"); then
        do_prepare
    fi
    if [ $WRITEAPTPREF == 1 ] || ([ $WRITEAPTPREF == 2 ] && ask "  - Create apt preferences list?" "Y"); then
        write_aptpreferences
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
if ([ $COMPILEKERNEL == 1 ] || [ $PKGKERNEL == 1 ] || [ $ARCHIVEKERNEL == 1 ]) || \
  (([ $COMPILEKERNEL == 2 ] || [ $PKGKERNEL == 2 ] || [ $ARCHIVEKERNEL == 2 ]) && \
  ask "Compile custom kernel?" "Y"); then
    if [ $COMPILEKERNEL == 1 ] || ([ $COMPILEKERNEL == 2 ] && ask "  - Compile kernel?" "Y"); then
        do_compile_kernel
    fi
    if [ $PKGKERNEL == 1 ] || ([ $PKGKERNEL == 2 ] && ask "  - Package kernel?" "Y"); then
        do_package_kernel
    fi
    if [ $ARCHIVEKERNEL == 1 ] || ([ $ARCHIVEKERNEL == 2 ] && ask "  - Archive KERNEL_OUT & MODULES_OUT directories?" "Y"); then
        do_archive_kernel
    fi
fi
if ([ $MULTISTRAP == 1 ] || [ $ARCHIVEROOTFS == 1 ] || [ $ADDQEMU  == 1 ] || [ $ADDKERNELMODS  == 1 ] || [ $POSTSETUP  == 1 ] || [ $REMOVEQEMU  == 1 ]) || \
  (([ $MULTISTRAP == 2 ] || [ $ARCHIVEROOTFS == 2 ] || [ $ADDQEMU  == 2 ] || [ $ADDKERNELMODS  == 2 ] || [ $POSTSETUP  == 2 ] || [ $REMOVEQEMU  == 2 ]) && \
  ask "Create rootfs?" "Y"); then
    if [ $MULTISTRAP == 1 ] || ([ $MULTISTRAP == 2 ] && ask "  - Run multistrap to create rootfs?" "Y"); then
        do_multistrap
    fi
    if [ $ARCHIVEROOTFS == 1 ] || ([ $ARCHIVEROOTFS == 2 ] && ask "  - Archive ROOTFS directory?" "Y"); then
        do_archive_rootfs
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
if ([ $PREPAREIMG == 1 ] || [ $CREATEIMG == 1 ]) || \
  (([ $PREPAREIMG == 2 ] || [ $CREATEIMG == 2 ]) && \
  ask "Create image?" "Y"); then
    if [ $PREPAREIMG == 1 ] || ([ $PREPAREIMG == 2 ] && ask "  - Prepare image?" "Y"); then
        do_prepare_img
    fi
    if [ $CREATEIMG == 1 ] || ([ $CREATEIMG == 2 ] && ask "  - Copy rootfs to new image file?" "Y"); then
        do_create_img
    fi
fi
if ([ $PURGE == 1 ] || [ $PURGEKERNEL == 1 ] || [ $CLEANUP == 1 ]) || \
  (([ $PURGE == 2 ] || [ $PURGEKERNEL == 2 ] || [ $CLEANUP == 2 ]) && \
  ask "Purge files from previous builds?" "Y"); then
    if [ $PURGE == 1 ] || ([ $PURGE == 2 ] && ask "  - Delete rootfs from previous builds?" "Y"); then
        do_purge
    fi
    if [ $PURGEKERNEL == 1 ] || ([ $PURGEKERNEL == 2 ] && ask "  - Delete kernels from previous builds?" "Y"); then
        do_purgekernel
    fi
    if [ $CLEANUP == 1 ] || ([ $CLEANUP == 2 ] && ask "  - Delete configuration files from previous builds?" "Y"); then
        do_cleanup
    fi
fi




#!/bin/bash
## Customise this:
SUITE=kali
SYS_IMG_FILE=system.img
ROOT_IMG_FILE=linux_root.img
DEBUG=1


#WHICH PARTS TO EXECUTE:
PURGE=1
PREPARE=1
WRITEMULTISTRAPCFG=1
MULTISTRAP=1
ADDQEMU=1
WRITEPOSTSETUP=1
WRITEROOTFSCFG=1
POSTSETUP=1
REMOVEQEMU=1
PREPAREIMG=1
CREATEIMG=1
CLEANUP=1
KALI_KALI="kali-defaults kali-menu desktop-base kali-linux-top10 kali-root-login firmware-realtek firmware-atheros firmware-libertas"
KALI_GENERIC="task-lxqt-desktop ark bash-completion bluez breeze bzip2 chromium dosfstools exfat-utils file fonts-hack-ttf fonts-liberation fonts-noto fonts-noto-cjk fonts-noto-mono gdisk gstreamer1.0-plugins-base gtk3-engines-breeze gvfs-backends hunspell-en-us hyphen-en-us isc-dhcp-common iw kate kcharselect kde-style-breeze-qt4 kdelibs5-data kpackagelauncherqml kwin-x11 libfm-qt-l10n libglib2.0-data libkf5config-bin libkf5dbusaddons-bin libkf5globalaccel-bin libkf5iconthemes-bin libkf5xmlgui-bin libqt5core5a libqt5dbus5 libqt5gui5 libqt5widgets5 libqt5x11extras5 libqtermwidget5-0 libqt5xml5 liblxqt-l10n libvlc-bin locales lxc lximage-qt lximage-qt-l10n lxqt-about-l10n lxqt-admin-l10n lxqt-config-l10n lxqt-globalkeys-l10n lxqt-notificationd-l10n lxqt-openssh-askpass-l10n lxqt-panel-l10n lxqt-policykit-l10n lxqt-powermanagement-l10n lxqt-runner-l10n lxqt-session-l10n lxqt-sudo lxqt-sudo-l10n mythes-en-us ncurses-term net-tools ntfs-3g p7zip-full pavucontrol-qt pavucontrol-qt-l10n pcmanfm-qt-l10n policykit-1 psmisc qlipper qpdfview qpdfview-djvu-plugin qpdfview-ps-plugin qpdfview-translations qt5-gtk-platformtheme qt5-image-formats-plugins qterminal qterminal-l10n qttranslations5-l10n rename rsync rtkit saytime smplayer smplayer-l10n smplayer-themes ssh sudo unzip upower wget wpasupplicant xdg-user-dirs xdg-utils xz-utils youtube-dl"
KALI_PACKAGES="${KALI_KALI} ${KALI_GENERIC}"
GEMIAN_PACKAGES="hybris-usb lxc-android libhybris drihybris glamor-hybris xserver-xorg-video-hwcomposer pulseaudio-module-droid ofono repowerd xss-lock gemian-lock gemian-leds cmst"
STRETCH_PACKAGES="libicu57"
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
POSTSETUP_SCRIPT=${DIR_NAME}/kali-gemini-postbuild.sh
ROOTFS_CONFIG_SCRIPT=${DIR_NAME}/kali-gemini-rootfs-config.sh
SYS_IMG=${BUILD_DIR}/SYSIMG/$SYS_IMG_FILE
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

function do_prepare {
    printf "\t***** Preparing build environment\n"
    if [ ! -d ${OUT_DIR} ]; then
        mkdir -p ${OUT_DIR}
	chown $SUDO_USER:$SUDO_USER ${OUT_DIR}
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

function write_multistrap_config {
    printf "\t***** Generating multistrap configuration\n"
    cat > ${DIR_NAME}/$CONFIG <<EOF
[General]
arch=arm64
directory=gemian-rootfs
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
configscript=debian-gemini-setup.sh
# copied into the chroot to be executed later
configscript=debian-gemini-config.sh
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
aptsources=Kali Gemian
# the bootstrap option determines which repository
# is used to calculate the list of Priority: required packages
# and which packages go into the rootfs.
# The order of sections is not important.
bootstrap=Stretch Kali Gemian

[Stretch]
packages=${STRETCH_PACKAGES}
source=http://http.debian.net/debian
keyring=debian-archive-keyring
suite=stretch

[Kali]
packages=$KALI_PACKAGES
source=http://http.kali.org/kali
keyring=kali-archive-keyring
suite=kali-rolling
components=main contrib non-free

[Gemian]
packages=$GEMIAN_PACKAGES
source=http://gemian.thinkglobally.org/buster/
suite=buster
components=main
EOF
    chown $SUDO_USER:$SUDO_USER ${DIR_NAME}/$CONFIG
}

function do_multistrap {
    printf "\t***** Multistrapping\n"
    multistrap -d ${ROOTFS} -f $CONFIG
}

function do_add_qemu {
    printf "\t***** Adding qemu\n"
    cp /usr/bin/qemu-aarch64-static $ROOTFS/usr/bin/
}

function do_remove_qemu {
    printf "\t***** Removing qemu\n"
    rm -f $ROOTFS/usr/bin/qemu-aarch64-static
}

function write_postsetup_script {
    printf "\t***** Generating postsetup script\n"
    cat > ${POSTSETUP_SCRIPT} <<EOF
#!/bin/sh

#pass path to the root. Don't let it run without one as it will break your system
if [ "" = "\$1" ] ; then
  echo "You need to specify a path to the target rootfs"
else
  if [ -e "\$1" ] ; then
    ROOTFS="\$1"
  else
    echo "Root dir \$ROOTFS not found"
  fi
fi

sudo mount proc -t proc \$ROOTFS/proc
sudo mount dev -t devtmpfs \$ROOTFS/dev
sudo mount devpts -t devpts \$ROOTFS/dev/pts
sudo mount sys -t sysfs \$ROOTFS/sys
sudo mount none -t tmpfs \$ROOTFS/var/cache
sudo mount none -t tmpfs \$ROOTFS/var/run
sudo mount none -t tmpfs \$ROOTFS/tmp
sudo mount none -t tmpfs \$ROOTFS/root
sudo mount none -t tmpfs \$ROOTFS/var/log
EOF

    chmod 755 ${POSTSETUP_SCRIPT}
    chown $SUDO_USER:$SUDO_USER ${POSTSETUP_SCRIPT}
}

function write_rootfs_config_script {
    printf "\t***** Generating post configuration script\n"
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
    printf "\t***** Running post configuration scripts in rootfs\n"
    ${POSTSETUP_SCRIPT} $ROOTFS
    chroot $ROOTFS dpkg --configure -a
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
    umount -l $ROOTFS/var/run
    umount -l $ROOTFS/tmp
    umount -l $ROOTFS/root
    umount -l $ROOTFS/var/log
}

function do_prepare_img {
    printf "\t***** Preparing image file\n"
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
    printf "\t***** Filling image file\n"
    if [ ! -d ${TMP_MNT} ]; then
        mkdir -p ${TMP_MNT}
    fi
    mount -o loop,rw,sync ${ROOT_IMG} ${TMP_MNT}
    rsync --progress -a ${ROOTFS}/* ${TMP_MNT}
    umount ${TMP_MNT}
}

function do_purge {
    printf "\t***** Purging files from previous runs\n"
    rm -fr $ROOTFS
    do_cleanup
}

function do_cleanup {
    printf "\t***** Deleting configuration files from previous runs\n"
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
if [ $PURGE == 1 ]; then
    do_purge
fi
if [ $PREPARE == 1 ]; then
    do_prepare
fi
if [ $WRITEMULTISTRAPCFG == 1 ]; then
    write_multistrap_config
fi
if [ $MULTISTRAP == 1 ]; then
    do_multistrap
fi
if [ $ADDQEMU == 1 ]; then
    do_add_qemu
fi
if [ $WRITEPOSTSETUP == 1 ]; then
    write_postsetup_script
fi
if [ $WRITEROOTFSCFG == 1 ]; then
    write_rootfs_config_script
fi
if [ $POSTSETUP == 1 ]; then
    do_postsetup
fi
if [ $REMOVEQEMU == 1 ]; then
    do_remove_qemu
fi
if [ $PREPAREIMG == 1 ]; then
    do_prepare_img
fi
if [ $CREATEIMG == 1 ]; then
    do_create_img
fi
if [ $CLEANUP == 1 ]; then
    do_cleanup
fi





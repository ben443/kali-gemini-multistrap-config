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
ExecStart=/bin/sh -c "resize2fs -p \$(findmnt -n -o SOURCE /)"
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

echo "kali" > /etc/hostname


cat << EFO > /etc/hosts
127.0.0.1       kali    localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EFO


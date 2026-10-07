#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/out}"
OUTPUT_FILE="${1:-${OUTPUT_DIR}/kali-r8q-rootfs.tar.xz}"
KALI_KEYRING="${KALI_KEYRING:-/usr/share/keyrings/kali-archive-keyring.gpg}"
KALI_MIRROR="${KALI_MIRROR:-https://http.kali.org/kali}"
KALI_SUITE="${KALI_SUITE:-kali-rolling}"
ROOTFS_PACKAGES=(systemd-sysv lxc udev dbus ca-certificates locales sudo openssh-server network-manager)
WORK_ROOT=
ROOTFS=
MOUNTS_ACTIVE=0

usage() {
    printf 'Usage: sudo %s [output-tarball]\n' "${0##*/}"
    printf 'Optional environment: KALI_KEYRING, KALI_MIRROR, KALI_SUITE, KALI_EXTRA_PACKAGES\n'
}

cleanup() {
    if [[ "$MOUNTS_ACTIVE" -eq 1 ]]; then
        umount -R "${ROOTFS}/dev" || true
        umount "${ROOTFS}/proc" || true
        umount "${ROOTFS}/sys" || true
        if mountpoint -q "${ROOTFS}/dev" ||
           mountpoint -q "${ROOTFS}/proc" ||
           mountpoint -q "${ROOTFS}/sys"; then
            echo "Rootfs mounts remain active; leaving build directory at $WORK_ROOT." >&2
            return
        fi
    fi
    if [[ -n "$WORK_ROOT" && -d "$WORK_ROOT" ]]; then
        rm -rf -- "$WORK_ROOT"
    fi
}
trap cleanup EXIT

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ "$EUID" -ne 0 ]]; then
    echo "Run this script as root (for example, with sudo)." >&2
    exit 1
fi

for command in debootstrap chroot mount umount mountpoint tar; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required command not found: $command" >&2
        exit 1
    fi
done

if [[ ! -r "$KALI_KEYRING" ]]; then
    echo "Kali archive keyring not readable: $KALI_KEYRING" >&2
    echo "Install kali-archive-keyring or set KALI_KEYRING to its path." >&2
    exit 1
fi

if [[ "$(uname -m)" != "aarch64" ]] && ! command -v qemu-aarch64-static >/dev/null 2>&1; then
    echo "Cross-building arm64 requires qemu-aarch64-static and binfmt support." >&2
    exit 1
fi

OUTPUT_FILE="$(realpath -m -- "$OUTPUT_FILE")"
mkdir -p -- "$(dirname -- "$OUTPUT_FILE")"
WORK_ROOT="$(mktemp -d "$(dirname -- "$OUTPUT_FILE")/.rootfs-build.XXXXXX")"
ROOTFS="${WORK_ROOT}/rootfs"
mkdir -p "$ROOTFS"

debootstrap \
    --arch=arm64 \
    --foreign \
    --keyring="$KALI_KEYRING" \
    --variant=minbase \
    "$KALI_SUITE" "$ROOTFS" "$KALI_MIRROR"

if [[ "$(uname -m)" != "aarch64" ]]; then
    install -m 0755 "$(command -v qemu-aarch64-static)" "${ROOTFS}/usr/bin/qemu-aarch64-static"
fi

mount --rbind /dev "${ROOTFS}/dev"
MOUNTS_ACTIVE=1
mount --make-rslave "${ROOTFS}/dev"
mount -t proc proc "${ROOTFS}/proc"
mount -t sysfs sysfs "${ROOTFS}/sys"

chroot "$ROOTFS" /debootstrap/debootstrap --second-stage
chroot "$ROOTFS" apt-get update

if [[ -n "${KALI_EXTRA_PACKAGES:-}" ]]; then
    read -r -a extra_packages <<< "$KALI_EXTRA_PACKAGES"
    ROOTFS_PACKAGES+=("${extra_packages[@]}")
fi

chroot "$ROOTFS" apt-get install -y --no-install-recommends "${ROOTFS_PACKAGES[@]}"
chroot "$ROOTFS" update-locale LANG=C.UTF-8

printf 'kali-r8q\n' > "${ROOTFS}/etc/hostname"
systemctl --root="$ROOTFS" enable multi-user.target ssh.service

rm -f -- "${ROOTFS}/usr/bin/qemu-aarch64-static"
chroot "$ROOTFS" apt-get clean
rm -rf -- "${ROOTFS}/var/lib/apt/lists/"*

umount -R "${ROOTFS}/dev"
umount "${ROOTFS}/proc"
umount "${ROOTFS}/sys"
MOUNTS_ACTIVE=0

tar --numeric-owner --xattrs --acls -C "$ROOTFS" -cJf "$OUTPUT_FILE" .
printf 'Created Kali arm64 rootfs archive: %s\n' "$OUTPUT_FILE"

# Kali Linux on Halium: Samsung Galaxy S20 FE 5G

This repository is a bring-up workspace for the Samsung Galaxy S20 FE 5G
(`SM-G781B`, `r8q`, Qualcomm `SM8250`) using an Android 11 / Halium 11 base.
Android 11 is API level 30. Halium 11.0 is the recommended starting branch for
Android 11 devices; this repository does not yet contain a verified r8q Halium
source manifest or vendor files.

The build is split into three independent artifacts:

1. A Kali arm64 rootfs tarball with systemd and LXC.
2. An r8q kernel built with the Halium/LXC config fragment.
3. Halium `hybris-boot` and `systemimage` artifacts built from a complete
   device source tree.

The first two can be built here once their host tools and kernel sources are
available. The third needs a Halium source checkout containing device, common,
kernel and vendor sources verified for **SM-G781B**. A successful build of
these pieces is not proof of a bootable or hardware-working port. Device
partition mounting, Android container configuration, vendor blobs, and
installation still need to match this exact model and be tested on hardware.

## Host requirements

On an arm64 or Debian/Kali amd64 build host, install `debootstrap`,
`qemu-user-static` (for amd64 hosts), and the Kali archive keyring. Kernel
building also needs the Android kernel's matching compiler/toolchain and
`make`. Building Halium requires the Android build prerequisites, `repo`,
`git`, and several hundred GB of free disk space.

## Build the Kali rootfs

Run as root. On an amd64 host, `qemu-aarch64-static` must be installed and
registered with binfmt. The Kali archive keyring must be at
`/usr/share/keyrings/kali-archive-keyring.gpg` or be selected with
`KALI_KEYRING`.

```sh
sudo ./build-kali-halium-rootfs.sh
```

The output is `out/kali-r8q-rootfs.tar.xz`. Add extra Kali package names with
`KALI_EXTRA_PACKAGES="package-a package-b"`. This is a generic Halium host
rootfs; it does not include an r8q-specific LXC configuration or Android
system/vendor images.

## Build a Halium-enabled r8q kernel

Use the Android kernel source and defconfig for the **SM-G781B regional
variant**, not another `r8q` SKU. The source tree and toolchain are not
downloaded or guessed by this repository.

```sh
HALIUM_CHECKER=/path/to/halium-11/check-kernel-config \
KERNEL_CROSS_COMPILE=/path/to/aarch64-linux-android- \
  ./build-r8q-kernel.sh /path/to/android_kernel_samsung_sm8250 \
  vendor/r8q_eur_open_defconfig
```

Set `KERNEL_CC`, `KERNEL_LLVM`, `KERNEL_JOBS`, or `KERNEL_OUT` when the kernel
source requires different build settings. `HALIUM_CHECKER` must point to an
executable Halium-11-compatible `check-kernel-config`. The script merges
`kernel/halium.config`, runs `olddefconfig`, checks the full Halium config
contract and the checker result, then builds `Image.gz`, DTBs, and modules.

## Build Halium images

First initialize and sync the Halium 11.0 sources and add a device manifest
which resolves to the correct r8q device tree, SM8250 common tree, kernel and
vendor blobs. Halium's
[source guide](https://docs.halium.org/en/latest/porting/get-sources.html)
describes local manifests and device dependencies.

With those sources present, build the Android-side Halium images:

```sh
./build-halium-images.sh /path/to/halium-11.0
```

This invokes `breakfast r8q`, applies Halium's Hybris patches, and builds
`hybris-boot` and `systemimage`. It does not install the Kali rootfs or flash
the device. The kernel config fragment must be integrated into the device's
actual kernel build; compiling a separate kernel with the helper above does
not automatically replace the kernel used by the Android build.

## Reference projects

- [Droidian recipes](https://github.com/mukahraman/droidian-recipes) shows a
  device-image recipe separated from the kernel and adaptation packages. Its
  current recipe is for the Galaxy Tab S7+, not `r8q`.
- [Kali NetHunter Pro SM8250](https://github.com/ben443/nethunter-pro-sm8250)
  provides Kali/debos and r8q build references. Its r8q boot flow is native
  Linux, not Halium; its boot parameters and artifacts are not drop-in Halium
  configuration.

## Current port status

The user's prior successful Droidian boot is useful device history, but the
source tree and adaptation files from that installation are not present here.
The current profile deliberately leaves source references unset until they
are verified for `SM-G781B`. No bootable image is claimed until the matching
device sources, adaptation files, and on-device boot have been validated.

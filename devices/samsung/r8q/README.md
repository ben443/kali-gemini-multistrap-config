# Samsung Galaxy S20 FE 5G (r8q)

This is the device profile for the Samsung Galaxy S20 FE 5G, model SM-G781B,
based on the Qualcomm SM8250. Android 11 corresponds to API level 30; the
device originally shipped with Android 10/API 29.

The target is Halium 11.0. The user reports that Droidian previously booted on
this device, but the working source tree and adaptation files are unavailable.
Device tree, common tree, kernel and vendor source fields remain unset until
they are verified for SM-G781B. Another r8q SKU's configuration is not
automatically compatible.

The kernel fragment is at `../../../kernel/halium.config`; rootfs and kernel build
commands are documented in the repository README. This profile alone is not a
bootable image.

## References

- [Droidian porting guide: adaptation packages and API levels](https://docs.droidian.org/porting-guide/rootfs-creation/)
- [Halium source selection guide](https://docs.halium.org/en/latest/porting/get-sources.html)
- [Halium kernel build guide](https://docs.halium.org/en/latest/porting/build-sources.html)
- [LineageOS r8q device information](https://wiki.lineageos.org/devices/r8q/)

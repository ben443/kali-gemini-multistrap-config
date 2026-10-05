# Samsung Galaxy S20 FE 5G (r8q)

This directory records the target profile for the Samsung Galaxy S20 FE 5G,
model SM-G781B, based on the Qualcomm SM8250. Android 11 corresponds to API
level 30; `device.yaml` keeps that distinct from the device's original shipping
API level.

The profile is a starting point, not a bootable adaptation or image build.
Halium 11.0 is a candidate base only. The source fields remain unset until a
matching Android 11 device tree, common tree, kernel, and vendor blobs have
been verified for the SM-G781B variant. Do not substitute another r8q SKU's
kernel configuration or vendor files without confirming compatibility.

This repository's existing build scripts and rootfs configuration are still
Gemini PDA-specific; they do not consume this profile yet.

## References

- [Droidian porting guide: adaptation packages and API levels](https://docs.droidian.org/porting-guide/rootfs-creation/)
- [Halium source selection guide](https://docs.halium.org/en/latest/porting/get-sources.html)
- [LineageOS r8q device information](https://wiki.lineageos.org/devices/r8q/)

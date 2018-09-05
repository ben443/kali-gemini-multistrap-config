![](https://re4son-kernel.com/wp-content/uploads/Kali-Gem-sddm.jpg)  

# kali-gemini-multistrap-config
Configs and scripts used to create a Kali Linux rootfs for Gemini PDA

## Status
This project is current an unsupported "Technology Preview", i.e. it is a fully working prototype but not ready for series production as the efforts required for maintenance and support is not sustainable. 

## Prerequisites
```
mkdir gemini && cd gemini
git clone https://github.com/Re4son/kali-gemini-multistrap-config
mkdir SYS_IMG
## Copy Android system image  to SYS_IMG
git clone https://github.com/Re4son/gemini-kali-linux-kernel-3.18 kernel-3.18
git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b nougat-release --depth 1
sudo apt install libncurses5-dev libncursesw5-dev curl multistrap
## Install qemu-aarch64-static from buster
git clone https://github.com/osm0sis/mkbootimg.git
make -C mkbootimg
mkdir RAMDISK && cd RAMDISK
curl -O https://gemian.thinkglobally.org/ramdisk.cpio.gz 
cd ..
```


## Example usage
Customise the first section of "build-*-gemini.sh"
```
sudo ./build-*-gemini.sh
```
  
## Wiki
More information can be found in the [wiki](https://github.com/Re4son/kali-gemini-multistrap-config/wiki)

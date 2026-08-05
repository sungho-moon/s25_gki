#!/bin/bash
# AnyKernel3 installer: generic device check disabled, LKM-ready kernel.

properties() { '
kernel.string=Samsung GKI 6.6.142 LKM Ready KMI 3030/3030
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; }

block=boot
is_slot_device=1
ramdisk_compression=auto
patch_vbmeta_flag=0
no_magisk_check=1
no_vbmeta_partition_patch=1

. tools/ak3-core.sh

ui_print " "
ui_print "[+] Samsung GKI 6.6.142 LKM Ready"
ui_print "[+] No built-in KSU or SUSFS"
ui_print "[+] Device check disabled; active-slot boot only"
ui_print "[+] MODULE_SIG_PROTECT and MODULE_SIG_FORCE disabled"

if [ -L "/dev/block/bootdevice/by-name/init_boot_a" ] || \
   [ -L "/dev/block/by-name/init_boot_a" ]; then
	 split_boot
	 flash_boot
else
	 dump_boot
	 write_boot
fi

ui_print " "
ui_print "[+] Kernel installation completed"

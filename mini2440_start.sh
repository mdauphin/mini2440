#!/bin/bash
#
# Run with script with 
# -sd <SD card image file> to have a SD card loaded
# -kernel <kernel uImage file> to have a kernel preloaded in RAM
#


name_nand="qemu/mini2440/mini2440_nand128.bin"

if [ ! -f "$name_nand" ]; then
	echo $0 : creating NAND empty image : "$name_nand"
	dd if=/dev/zero of="$name_nand" bs=2112 count=65536
	echo "** NAND file created - make sure to 'nand scrub' in u-boot"
fi

#	-mtdblock "$name_nand" \
#	-kernel /tftpboot/uImage
#	-drive file=$name_snapshots,snapshot=on \
#	-kernel $1 \
#	-sd mini2440_sd.img \
#	-serial stdio \
#	-nographic \
#	-monitor telnet::5555,server,nowait
cmd="qemu/arm-softmmu/qemu-system-arm \
	-M mini2440 \
	-m 128
	-kernel uImageT35 \
	-show-cursor \
	-sd $1 \
	-usb -usbdevice keyboard -usbdevice mouse \
	-mtdblock "$name_nand" \
	-serial stdio \
	"
echo $cmd
$cmd

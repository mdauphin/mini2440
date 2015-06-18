# Create qemu sdcard image


echo "Create image $1"
qemu/qemu-img create $1 1G
qemu/qemu-nbd $1.img &
sudo nbd-client localhost 1024 /dev/nbd0

echo "Disk parionning"
printf "n\np\n\n\n\nw\n" | sudo fdisk /dev/nbd0

echo "Format in ext3"
sudo mkfs.ext3 /dev/nbd0p1

mkdir sdcard
sudo mount /dev/nbd0p1 sdcard

cd sdcard
sudo mkdir dev proc bin etc etc/init.d mnt sys sbin lib usr usr/bin usr/sbin var
sudo mkdir -m 777 tmp

sudo cp ../busybox-1.22.1/busybox bin/
cd bin/
sudo ln -s busybox bash
cd ..
sudo cp -r ../opt/FriendlyARM/toolschain/4.4.3/arm-none-linux-gnueabi/lib/* lib/
sudo cp -a ../opt/FriendlyARM/toolschain/4.4.3/arm-none-linux-gnueabi/lib/libgcc* lib/

cd dev
sudo mknod -m 622 console c 5 1
cd ..

echo "::sysinit:/etc/init.d/rcS
::askfirst:-/bin/sh
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
::shutdown:/sbin/swapoff -a
::restart:/sbin/init" | sudo tee -a etc/inittab

echo "#! /bin/sh

# Setup the bin file location and export to system PATH
PATH=/sbin:/bin:/usr/sbin:/usr/bin
umask 022
export PATH

# mount the filesystem directories
mount -a
mkdir /dev/pts
mount -t devpts devpts /dev/pts -o mode=0622

# create device nodes and directories
echo /sbin/mdev>/proc/sys/kernel/hotplug
mdev -s
mkdir /var/lock

# start logging utility services
klogd
syslogd

# set system clock from RTC
hwclock -s

# set host and config loopback interface
ifconfig lo 127.0.0.1" | sudo tee -a etc/init.d/rcS
sudo chmod +x etc/init.d/rcS

echo "# system all-writable devices
full  0:0 0666
null  0:0 0666
ptmx  0:0 0666
random  0:0 0666
tty  0:0 0666
zero  0:0 0666

# console devices
tty[0-9]* 0:5 0660
vc/[0-9]* 0:5 0660

# serial port devices
s3c2410_serial0 0:5 0666 =ttySAC0
s3c2410_serial1 0:5 0666 =ttySAC1
s3c2410_serial2 0:5 0666 =ttySAC2
s3c2410_serial3 0:5 0666 =ttySAC3

# loop devices
loop[0-9]* 0:0 0660 =loop/

# i2c devices
i2c-0  0:0 0666 =i2c/0
i2c-1  0:0 0666 =i2c/1

# frame buffer devices
fb[0-9]  0:0 0666

# input devices
mice  0:0 0660 =input/
mouse.*  0:0 0660 =input/
event.*  0:0 0660 =input/
ts.*  0:0 0660 =input/

# rtc devices
rtc0  0:0 0644 >rtc
rtc[1-9] 0:0 0644

# misc devices
mmcblk0p1 0:0 0600 =sdcard */bin/hotplug
sda1  0:0 0600 =udisk * /bin/hotplug" | sudo tee -a etc/mdev.conf

echo "proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
tmpfs /dev tmpfs defaults 0 0
tmpfs /tmp tmpfs defaults 0 0
var /var tmpfs defaults 0 0" | sudo tee -a etc/fstab

cd ..
sudo umount sdcard
echo "Done"

echo "now boot on sd card with:
setenv bootargs console=ttySAC0,115200 noinitrd root=/dev/mmcblk0p1 rootwait rw ip=dhcp init=/bin/busybox sh
mini2240# /bin/busybox --install -s"


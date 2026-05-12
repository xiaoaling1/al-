sh << 'EOF'
#!/bin/sh
P="yiwan123@"
D="/dev/vda"
R="http://mirrors.aliyun.com/alpine/v3.23"

setup-interfaces -a -r
sleep 2

cat > /tmp/answerfile <<E
KEYMAPOPTS="us us"
HOSTNAMEOPTS="-n alpine"
INTERFACESOPTS="auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp"
DNSOPTS="-d 223.5.5.5 8.8.8.8"
TIMEZONEOPTS="-z PRC"
PROXYOPTS="none"
APKREPOSOPTS="$R/main"
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
USEROPTS="-a -k none"
DISKOPTS="-m sys -s 0 $D"
E

export ERASE_DISKS="$D"
echo | setup-alpine -f /tmp/answerfile -e

mount ${D}2 /mnt
mount ${D}1 /mnt/boot

echo "root:$P" | chroot /mnt chpasswd

sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /mnt/etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /mnt/etc/ssh/sshd_config

printf "$R/main\n$R/community\n" > /mnt/etc/apk/repositories

mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys

chroot /mnt apk update
chroot /mnt apk add --no-cache mkinitfs grub grub-bios linux-lts

chroot /mnt mkinitfs -k $(ls /lib/modules/ | head -1)

cat >> /mnt/etc/default/grub << GRUB
GRUB_CMDLINE_LINUX_DEFAULT="quiet rootfstype=ext4 modules=sd-mod,usb-storage,ext4,virtio,virtio_blk,virtio_pci,virtio_net"
GRUB

chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
chroot /mnt grub-install --recheck $D

sync
umount /mnt/boot /mnt/dev /mnt/proc /mnt/sys /mnt 2>/dev/null
reboot
EOF

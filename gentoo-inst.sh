#! /bin/sh

# TODO: wrap parts into functions and remove useless comments

diskdev='/dev/sda'
swapsize='8G'
stagefile='https://gentoo.mirror.garr.it/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20240923T191858Z.tar.xz'

# check root access
rootok() {
	uid=`id -u`
	if [ $uid -ne 0 ]
	then
		echo 'run as root' >&2
		exit 1
	fi
}

# check connection
connok() {
	ping -c 3 1.1.1.1 >/dev/null
	if [ $? -eq 0 ]
	then
		echo 'no internet connection' >&2
		exit 1
	fi
}

# ask confirmation for disk
diskok() {
	printf "is $diskdev the correct disk? (y/N) "
	read ans
	echo $ans | egrep -i '^y(es)?$' >/dev/null
	if [ $? -eq 0 ]
	then
		echo 'installation aborted' >&2
		exit 1
	fi
}

# partition disk (TODO: does creating a new disk label erase all partitions, even if it is the same disk label type?)
mkparts() {
	partinfo="g
n
1

+1G
n
2

+$swapsize
n
3


t
1
1
t
2
19
t
3
t
3
23
w
"
	echo $partinfo | fdisk $diskdev
}

# create filesystems
mkfsys() {
	mkfs.vfat -F 32 $esp
	mkswap $swap
	swapon $swap
	mkfs.ext4 $rootfs
}

# mount root
mountroot() {
	mkdir -p $root
	mount $rootfs $root
	mkdir -p $root/efi
	mount $esp $root/efi
}

# download and install stage file
stagefile() {
	curl -O $stagefile
	lastwd=$PWD
	cd $root
	tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
	cd $lastwd
}

# don't configure compile options
compileopts() {
}

# chroot
chroot() {
	cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
	mount --types proc /proc $root/proc
	mount --rbind /sys $root/sys
	mount --rbind /dev $root/dev
	mount --bind /run $root/run
	chroot $root /bin/bash
	# TODO: add
}

rootok
connok
diskok
mkparts

esp="${diskdev}1"
swap="${diskdev}2"
rootfs="${diskdev}3"

mkfsys

root='/mnt/gentoo'

mountroot
stagefile
compileopts
chroot

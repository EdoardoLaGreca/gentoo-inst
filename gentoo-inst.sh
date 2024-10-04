# disk device in which to put the gentoo installation
diskdev='/dev/sda'

# size of the swap partition in a format suitable for fdisk
swapsize='8G'

# url of the stage 3 file to install
stagefile='https://gentoo.mirror.garr.it/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20240923T191858Z.tar.xz'

# mirrors for portage
mirrors="https://mirror.kumi.systems/gentoo/ \
http://mirror.kumi.systems/gentoo/ \
rsync://mirror.kumi.systems/gentoo/ \
https://ftp.uni-stuttgart.de/gentoo-distfiles/ \
http://ftp.uni-stuttgart.de/gentoo-distfiles/ \
ftp://ftp.uni-stuttgart.de/gentoo-distfiles/ \
https://gentoo.mirror.garr.it/ \
http://gentoo.mirror.garr.it/ \
https://mirror.init7.net/gentoo/ \
http://mirror.init7.net/gentoo/ \
rsync://mirror.init7.net/gentoo/"

# timezone
timezone='Europe/Rome'

# locales (the first is used as system language)
locales='en_GB.UTF-8 UTF-8
en_US.UTF-8 UTF-8
it_IT.UTF-8 UTF-8'

# -- START FUNCTIONS -- #

# merge the current USE flags with another USE flag
# e.g.: mergeuse -kde (disables the kde USE flag)
# e.g.: mergeuse networkmanager (enables the networkmanager USE flag)
# if the given flag was not present, add it
# if the given flag is already present and has opposite mode (enabled or disabled), invert the mode
# if the given flag is already present and has the same mode (enabled or disabled), do nothing
# if the USE variable is not defined, define it with the given flag
mergeuse() {
	makeconf='/etc/portage/make.conf'
	flag="$1"
	mode=`echo $flag | egrep -o '^-?'`
	flag=`echo $flag | sed "s/^$mode//"`

	if ! egrep '^USE=' $makeconf
	then
		echo "USE=\"\"" >>$makeconf
	fi

	oldusefull=`emerge --info | egrep -o "^USE=(\"|')[^[:cntrl:]]*(\"|')"`
	olduse=`echo $oldusefull | sed "s/^USE=//;s/'//g;s/\"//g"`
	match=`echo "$olduse" | egrep -o "(^|[[:space:]])(-|+)?$flag([[:space:]]|$)"`

	if [ -z "$match" ]
	then
		newuse="$olduse $mode$flag"
	else
		newuse=`echo $olduse | sed "s/$match/$mode$flag/`
	fi

	newusefull="USE=\"$newuse\""
	sed -i "s/$oldusefull/$newusefull/" $makeconf
}

# -- ABOVE: INTERNAL FUNCTIONS -- #

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
	if [ $? -ne 0 ]
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

# partition disk
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
23
w
"
	# delete the partition table header to make sure that fdisk does not
	# prompt for any confirmation
	dd if=/dev/zero of=$diskdev bs=1K count=8 status=progress
	echo $partinfo | fdisk $diskdev -w always -W always
}

# create filesystems and activate swap
mkfsys() {
	mkfs.vfat -F 32 $esp
	mkswap $swap
	swapon $swap
	mkfs.ext4 $rootfs
}

# mount root
mountroot() {
	mkdir -p $rootdir
	mount $rootfs $rootdir
	mkdir -p $rootdir/efi
}

# download and install stage file
inststagefile() {
	curl -O $stagefile
	lastwd=$PWD
	cd $rootdir
	tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
	cd $lastwd
}

# configure compile options
compileopts() {
	# don't
	:
}

# pre-chroot
prechroot() {
	cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
	mount --types proc /proc $rootdir/proc
	mount --rbind /sys $rootdir/sys
	mount --rbind /dev $rootdir/dev
	mount --bind /run $rootdir/run
}

# post-chroot
postchroot() {
	. /etc/profile
	PS1="(chroot) $PS1"
	export PS1
	mount $esp /efi
}

# configure portage
confptg() {
	until emerge --sync --quiet
	do
		printf 'failed to sync emerge, retry? (Y/n) '
		read ans
		echo $ans | egrep -i '^no?$' >/dev/null
		if [ $? -eq 0 ]
		then
			break
		fi
	done

	echo "GENTOO_MIRRORS=\"$mirrors\"" >>/etc/portage/make.conf
	# skip news reading
	# skip profile selection
	# skip binary package host
	# skip USE variable configuration, including CPU_FLAGS_* and VIDEO_CARDS
	# skip ACCEPT_LICENSE variable configuration
	# skip @world set updating
	echo 'sys-kernel/linux-firmware linux-fw-redistributable' >>/etc/portage/package.license/kernel
}

# set timezone
settz() {
	echo "$timezone" >/etc/timezone
	emerge --config sys-libs/timezone-data
}

# configure locales
setlocales() {
	echo "$locales" >/etc/locale.gen
	locale-gen
	echo "LANG=\"`echo "$locales" | head -n 1 | awk '{print $1}'`\"" >>/etc/env.d/02locale
	echo "LC_COLLATE=\"C.UTF-8\"" >>/etc/env.d/02locale
}

# download and install firmware
dlfw() {
	emerge sys-kernel/linux-firmware
}

# kernel configuration and compilation
kernconf() {
	echo 'sys-kernel/installkernel grub' >>/etc/portage/package.use/installkernel
	echo 'sys-kernel/installkernel dracut' >>/etc/portage/package.use/installkernel
	emerge sys-kernel/installkernel

	# use distribution kernel
	emerge sys-kernel/gentoo-kernel-bin
	# skip signing (both kernel modules and kernel image)

	# add dist-kernel USE flag
	mergeuse 'dist-kernel'
}

# fill /etc/fstab
fstabconf() {
	# add /efi
	uuid=`blkid | grep "^$esp:" | awk '{ print $2 }' | sed "s/^PARTUUID=\"//;s/\"$//'`
	printf "UUID=$uuid\t/efi\tvfat\tumask=0077\t0 2" >> /etc/fstab

	# add swap
	uuid=`blkid | grep "^$swap:" | awk '{ print $2 }' | sed "s/^PARTUUID=\"//;s/\"$//'`
	printf "UUID=$uuid\tnone\tswap\tsw\t0 0" >> /etc/fstab

	# add /
	uuid=`blkid | grep "^$rootfs:" | awk '{ print $2 }' | sed "s/^PARTUUID=\"//;s/\"$//`
	printf "UUID=$uuid\t/\text4\tdefaults\t0 1\n" >>/etc/fstab
}

# configure networking
netconf() {
	echo edo-pc >/etc/hostname

	# use dhcpcd instead of netifrc
	emerge net-misc/dhcpcd
	rc-update add dhcpcd default
	rc-service dhcpcd start
}

# prompt for a new root password
rootpw() {
	# passwd
	:
}

# set up OpenRC
openrcconf() {
	# /etc/rc.conf
	if [ -f ./rc.conf ]
	then
		if ! diff ./rc.conf /etc/rc.conf
		then
			mv /etc/rc.conf /etc/rc.conf.bk
			cp ./rc.conf /etc
		else
			echo 'the new ./rc.conf and the old /etc/rc.conf files are identical' >&2
		fi
	else
		echo 'rc.conf does not exist or it's not a regular file, failed to set up OpenRC' >&2
	fi

	# /etc/conf.d/hwclock
	#sed -i 's/#*clock=.*/clock="local"/' /etc/conf.d/hwclock
}

# set up a system logger
syslogger() {
	emerge app-admin/sysklogd
	rc-update add sysklogd default
}

# install a cron daemon
crondmon() {
	emerge sys-process/cronie
	rc-update add cronie default
}

# add file indexing
fileindexing() {
	emerge sys-apps/mlocate
}

# enable the SSH daemon
sshdmon() {
	#rc-update add sshd default
	:
}

# add Bash completions
bashcompl() {
	#emerge app-shells/bash-completion
	:
}

# add time synchronization
timesync() {
	emerge net-misc/chrony
	rc-update add chronyd default
}

# install the filesystem tools
fstools() {
	# already installed for ext4 as part of @world
	#emerge sys-fs/e2fsprogs
}

# install networking tools
nettools() {
	# dhcpcd was already installed in netconf
	#emerge net-misc/dhcpcd
	emerge net-wireless/iw net-wireless/wpa_supplicant
}

# add a bootloader
bootld() {
	# set GRUB_PLATFORMS anyway to ensure compatibility with UEFI
	echo 'GRUB_PLATFORMS="efi-64"' >>/etc/portage/make.conf
	emerge --verbose sys-boot/grub

	# make sure that the EFI system partition is mounted before installing
	mkdir -p /efi
	mount $esp /efi

	grub-install --efi-directory=/efi
	grub-mkconfig -o /boot/grub/grub.cfg
}

# -- END FUNCTIONS -- #

# part 1: before chroot
part1() {
	rootok
	connok
	diskok
	mkparts
	mkfsys
	mountroot
	inststagefile
	compileopts
	prechroot
}

#chroot $rootdir /bin/bash

# part 2: after chroot
part2() {
	postchroot
	confptg
	settz
	setlocales
	dlfw
	kernconf
	fstabconf
	netconf
	rootpw
	openrcconf
	syslogger
	crondmon
	fileindexing
	sshdmon
	bashcompl
	timesync
	fstools
	nettools
	bootld
}

# disk partitions
esp="${diskdev}1"
swap="${diskdev}2"
rootfs="${diskdev}3"

# for part1
rootdir='/mnt/gentoo'

$1

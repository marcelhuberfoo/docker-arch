#!/usr/bin/env bash
# Generate a minimal filesystem for archlinux (requires root)

set -e

hash pacstrap &>/dev/null || {
    echo "Could not find pacstrap. Run pacman -S arch-install-scripts"
    exit 1
}

hash expect &>/dev/null || {
    echo "Could not find expect. Run pacman -S expect"
    exit 1
}

DATE=$1

echo Building Arch Linux container for ${DATE}...

INSTARCH_KEY=051680AC
ROOTFS=$(mktemp -d ${TMPDIR:-/var/tmp}/rootfs-archlinux-XXXXXXXXXX)
chmod 755 $ROOTFS

# packages to ignore for space savings
PKGIGNORE=linux,jfsutils,lvm2,groff,man-db,man-pages,mdadm,pciutils,pcmciautils,reiserfsprogs,s-nail,xfsprogs

expect <<EOF
  set send_slow {1 .1}
  proc send {ignore arg} {
      sleep .1
      exp_send -s -- \$arg
  }
  set timeout 60

  spawn pacstrap -C ./mkimage-arch-pacman.conf -c -d -G -i $ROOTFS base sudo haveged --ignore $PKGIGNORE
  expect {
      -exact "anyway? \[Y/n\] " { send -- "n\r"; exp_continue }
      -exact "(default=all): " { send -- "\r"; exp_continue }
      -exact "installation? \[Y/n\]" { send -- "y\r"; exp_continue }
  }
EOF

arch-chroot $ROOTFS /bin/sh -c "haveged -w 1024; pacman-key --init; pkill haveged; pacman -Rs --noconfirm haveged; pacman-key --populate archlinux"

# add my repository
arch-chroot $ROOTFS /bin/sh -c "pacman-key -r ${INSTARCH_KEY} && pacman-key --lsign-key ${INSTARCH_KEY}"
echo -e "[instarch]\nServer = http://instarch.codekoala.com/\$arch/" >> $ROOTFS/etc/pacman.conf

arch-chroot $ROOTFS /bin/sh -c "ln -sf /usr/share/zoneinfo/UTC /etc/localtime"
echo 'en_US.UTF-8 UTF-8' > $ROOTFS/etc/locale.gen
arch-chroot $ROOTFS locale-gen
arch-chroot $ROOTFS /bin/sh -c 'echo "Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist'

# clean up downloaded packages
rm -rf $ROOTFS/var/cache/pacman/pkg/*

# udev doesn't work in containers, rebuild /dev
DEV=$ROOTFS/dev
rm -rf $DEV
mkdir -p $DEV
mknod -m 666 $DEV/null c 1 3
mknod -m 666 $DEV/zero c 1 5
mknod -m 666 $DEV/random c 1 8
mknod -m 666 $DEV/urandom c 1 9
mkdir -m 755 $DEV/pts
mkdir -m 1777 $DEV/shm
mknod -m 666 $DEV/tty c 5 0
mknod -m 600 $DEV/console c 5 1
mknod -m 666 $DEV/tty0 c 4 0
mknod -m 666 $DEV/full c 1 7
mknod -m 600 $DEV/initctl p
mknod -m 666 $DEV/ptmx c 5 2
ln -sf /proc/self/fd $DEV/fd

# make systemd a bit happier (disable everything except journald)
find $ROOTFS -type l -iwholename "*.wants*" -delete
SYSD=/usr/lib/systemd/system
ln -sf $SYSD/systemd-journald.socket $SYSD/sockets.target.wants/
ln -sf $SYSD/systemd-journald.service $SYSD/sysinit.target.wants/

echo "Compressing filesystem..."
UNTEST=arch-rootfs-untested.tar.xz
tar --xz -f $UNTEST --numeric-owner -C $ROOTFS -c .
rm -rf $ROOTFS

echo "Testing filesystem..."
cat $UNTEST | docker import - archtest
docker run -ti --rm archtest echo Success.
docker rmi archtest

echo "Approving filesystem..."
mv $UNTEST arch-rootfs-${DATE}.tar.xz

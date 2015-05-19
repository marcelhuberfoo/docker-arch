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

ROOTFS=$(mktemp -d ${TMPDIR:-/var/tmp}/rootfs-archlinux-XXXXXXXXXX)
chmod 755 $ROOTFS

# packages to ignore for space savings
PKGIGNORE=(
    cryptsetup
    device-mapper
    dhcpcd
    groff
    iproute2
    jfsutils
    linux
    lvm2
    man-db
    man-pages
    mdadm
    nano
    netctl
    pciutils
    pcmciautils
    reiserfsprogs
    s-nail
    systemd-sysvcompat
    usbutils
    xfsprogs
)
IFS=','
PKGIGNORE="${PKGIGNORE[*]}"
unset IFS

expect <<EOF
  set send_slow {1 .1}
  proc send {ignore arg} {
      sleep .1
      exp_send -s -- \$arg
  }
  set timeout 60

  #spawn pacstrap -C ./mkimage-arch-pacman.conf -c -d -G -i $ROOTFS base haveged systemd --ignore $PKGIGNORE
  spawn pacstrap -C ./mkimage-arch-pacman.conf -c -d -G -i $ROOTFS base haveged --ignore $PKGIGNORE
  expect {
      -exact "anyway? \[Y/n\] " { send -- "n\r"; exp_continue }
      -exact "(default=all): " { send -- "\r"; exp_continue }
      -exact "installation? \[Y/n\]" { send -- "y\r"; exp_continue }
  }
EOF

arch-chroot $ROOTFS /bin/sh -c "sed -i -r -e 's/^#?(TotalDownload|VerbosePkgLists)/\1/g' -e'/TotalDownload/ a\ILoveCandy' /etc/pacman.conf"
arch-chroot $ROOTFS /bin/sh -c "haveged -w 1024; pacman-key --init; pkill haveged; pacman -Rs --noconfirm haveged; pacman-key --populate archlinux; pkill gpg-agent"

arch-chroot $ROOTFS /bin/sh -c "ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime"
echo 'en_US.UTF-8 UTF-8' > $ROOTFS/etc/locale.gen
arch-chroot $ROOTFS locale-gen
#arch-chroot $ROOTFS /bin/sh -c 'echo "Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist'

# add my repository
#echo -e "[archlinuxfr]\nSigLevel = Optional TrustAll\nServer = http://repo.archlinux.fr/\$arch/" >> $ROOTFS/etc/pacman.conf
#echo -e "[ownrepo]\nSigLevel = Optional TrustAll\nServer = file:///root" >> $ROOTFS/etc/pacman.conf
cp localepurge-* $ROOTFS/root
#arch-chroot $ROOTFS /bin/sh -c 'cd /root && repo-add --new --quiet ownrepo.db.tar.gz localepurge-*; repo-add --files --new --quiet ownrepo.files.tar.gz localepurge-*'

# remove locale information
#arch-chroot $ROOTFS /bin/sh -c 'pacman -Sy --noconfirm localepurge && sed -i "/NEEDSCONFIGFIRST/d" /etc/locale.nopurge && localepurge && pacman -R --noconfirm localepurge'
arch-chroot $ROOTFS /bin/sh -c 'pacman -U --noconfirm /root/localepurge-*.tar.xz && sed -i "/NEEDSCONFIGFIRST/d" /etc/locale.nopurge && localepurge && pacman -R --noconfirm localepurge'

# clean up downloaded packages
arch-chroot $ROOTFS /bin/sh -c 'printf "y\\ny\\n" | pacman -Scc'
#rm -rf $ROOTFS/var/cache/pacman/pkg/*
#rm -f $ROOTFS/root/localepurge-* $ROOTFS/root/ownrepo.*

# clean up manpages and docs
rm -rf $ROOTFS/usr/share/{man,doc}

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
tar --xz -f $UNTEST --numeric-owner --xattrs --acls -C $ROOTFS -c .
rm -rf $ROOTFS

echo "Testing filesystem..."
cat $UNTEST | docker import - archtest
docker run -t --rm archtest echo "Hello from Image"
docker rmi archtest

echo "Approving filesystem..."
mv $UNTEST arch-rootfs-${DATE}.tar.xz

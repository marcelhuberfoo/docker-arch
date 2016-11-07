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

IMGTAG=$1

echo Building Arch Linux container for ${IMGTAG}...

INSTARCH_KEY=051680AC
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
    openresolv
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

  spawn pacstrap -C ./mkimage-arch-pacman.conf -c -d -G -i $ROOTFS base systemd haveged sudo git vim-minimal --ignore $PKGIGNORE
  expect {
      -exact "anyway? \[Y/n\] " { send -- "n\r"; exp_continue }
      -exact "(default=all): " { send -- "\r"; exp_continue }
      -exact "installation? \[Y/n\]" { send -- "y\r"; exp_continue }
  }
EOF

arch-chroot $ROOTFS /bin/sh -c "haveged -w 1024; pacman-key --init; pkill haveged; pacman -Rs --noconfirm haveged; pacman-key --populate archlinux; pkill gpg-agent"

# enable multilib repo
arch-chroot $ROOTFS /bin/sh -c "sed -i -r -e 's/^#?(Color|TotalDownload|VerbosePkgLists)/\1/g' -e'/TotalDownload/ a\ILoveCandy' -e ':a;N;\$!ba' -e 's|#(\[multilib\]\n)#([^\n]*\n)|\1\2|' /etc/pacman.conf"

# add my repository
mkdir -p $ROOTFS/root/.gnupg
touch $ROOTFS/root/.gnupg/dirmngr_ldapservers.conf
arch-chroot $ROOTFS /bin/sh -c "pacman-key -r ${INSTARCH_KEY} && pacman-key --lsign-key ${INSTARCH_KEY}; pkill dirmngr; pkill gpg-agent"
echo -e "[instarch]\nServer = http://instarch.codekoala.com/\$arch/" >> $ROOTFS/etc/pacman.conf

arch-chroot $ROOTFS /bin/sh -c "ln -sf /usr/share/zoneinfo/UTC /etc/localtime"
echo 'LANG=en_US.UTF-8' > $ROOTFS/etc/locale.conf
echo 'en_US.UTF-8 UTF-8' > $ROOTFS/etc/locale.gen
arch-chroot $ROOTFS locale-gen
arch-chroot $ROOTFS /bin/sh -c 'echo "Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist'

# remove locale information
arch-chroot $ROOTFS /bin/sh -c 'pacman --sync --refresh --noconfirm localepurge && sed -i "/NEEDSCONFIGFIRST/d" /etc/locale.nopurge && localepurge && pacman --remove --nosave --noconfirm localepurge'

# clean up downloaded packages
arch-chroot $ROOTFS /bin/sh -c 'printf "y\\ny\\n" | pacman -Scc'
rm -rf $ROOTFS/var/cache/pacman/*

# clean up downloaded packages
arch-chroot $ROOTFS /bin/sh -c 'systemctl set-default multi-user.target'

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
UNTEST=arch-rootfs-untested.tar
tar --create --file $UNTEST --utc --numeric-owner --xattrs --acls -C $ROOTFS . >/dev/null
rm -rf $ROOTFS

echo "Testing filesystem..."
cat $UNTEST | docker import - archtest
docker run -t --name arch_cont archtest echo "Hello from Image"
docker rm arch_cont
docker rmi archtest

echo "Approving filesystem..."
mv $UNTEST ${UNTEST/untested/${IMGTAG}}
xz --compress --force -7e --threads=0 ${UNTEST/untested/${IMGTAG}}

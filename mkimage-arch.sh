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

  spawn pacstrap -C ./mkimage-arch-pacman.conf -c -d -G -i $ROOTFS pacman grep shadow procps-ng sed --ignore $PKGIGNORE
  expect {
      -exact "anyway? \[Y/n\] " { send -- "n\r"; exp_continue }
      -exact "(default=all): " { send -- "\r"; exp_continue }
      -exact "installation? \[Y/n\]" { send -- "y\r"; exp_continue }
  }
EOF

arch-chroot $ROOTFS /bin/sh -c "sed -i -r -e 's/^#?(Color|TotalDownload|VerbosePkgLists)/\1/g' -e'/TotalDownload/ a\ILoveCandy' -e ':a;N;\$!ba' -e 's|#(\[multilib\]\n)#([^\n]*\n)|\1\2|' /etc/pacman.conf"
arch-chroot $ROOTFS /bin/sh -c "pacman-key --init; pacman-key --populate archlinux; pkill gpg-agent"

arch-chroot $ROOTFS /bin/sh -c "ln -sf /usr/share/zoneinfo/UTC /etc/localtime"
echo 'en_US.UTF-8 UTF-8' > $ROOTFS/etc/locale.gen
arch-chroot $ROOTFS locale-gen

cp localepurge-* $ROOTFS/root

# remove locale information
arch-chroot $ROOTFS /bin/sh -c 'pacman --upgrade --noconfirm /root/localepurge-*.tar.xz && sed -i "/NEEDSCONFIGFIRST/d" /etc/locale.nopurge && localepurge && pacman --remove --nosave --noconfirm localepurge'

# clean up downloaded packages
arch-chroot $ROOTFS /bin/sh -c 'printf "y\\ny\\n" | pacman -Scc'

# clean up manpages and docs
rm -rf $ROOTFS/usr/share/{man,doc}
rm -f $ROOTFS/root/localepurge-*
rm -f $ROOTFS/var/lib/pacman/sync/*.db

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


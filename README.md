# ArchLinux Container

Docker build for a basic [Arch Linux docker image][archimage] with gosu. I update the container regularly.

This image is built from scratch.

## Purpose

This docker image is build from scratch with a minimal [Arch Linux][archlinux] installation.
It provides several key features:

* A non-root user and group `docky` for executing programs inside the container.
* A umask of 0002 for user `docky`.
* Exported variables `UNAME`, `GNAME`, `UID` and `GID` to make use of the user settings from within scripts.
* Timezone (`/etc/localtime`) is linked to `Europe/Zurich`, adjust if required in a derived image.

## Usage

For example:

```bash
docker run --interactive --tty --rm marcelhuberfoo/arch env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=935562be7aff
TERM=xterm
UID=654321
GID=654321
UNAME=docky
GNAME=docky
LANG=en_US.utf8
HOME=/root
```

## Permissions

This image provides a user and group `docky` to run programs as user `docky`. It is best used with [`gosu`][gosu], as it allows to handle signals of the started process properly within the container.

If you map in a volume, permissions on the host folder must allow user or group `docky` to write to it. I recommend adding at least a group `docky` with GID of `654321` to your host system and change the group of the folder to `docky`. Don't forget to add yourself to the `docky` group.
The user `docky` has a `UID` of `654321` and a `GID` of `654321` which should not interfere with existing ids on regular Linux systems.

Add user and group docky, group might be sufficient:
```bash
groupadd -g 654321 docky
useradd --system --uid 654321 --gid docky --shell '/sbin/nologin' docky
```

Add yourself to the docky group:
```bash
gpasswd --add myself docky
```

Set group permissions to the entire project directory:
```bash
chmod -R g+w /tmp/my-data
chgrp -R docky /tmp/my-data
```

## systemd - *not yet functional*

**Note:** It is not yet possible to use systemd with this container due to docker limitations (at least with versions <= 1.6.2). *Therefor, the package `systemd` is not installed.*

### If it worked

Enabled services would be started in your container if run with something like:

```bash
docker run --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
       marcelhuberfoo/arch /usr/lib/systemd/systemd
```

To stop the container, you could execute ``systemctl poweroff``.

[archlinux]: https://www.archlinux.org
[gosu]: https://github.com/tianon/gosu
[archimage]: https://registry.hub.docker.com/u/marcelhuberfoo/arch/

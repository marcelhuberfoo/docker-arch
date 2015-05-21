# ArchLinux Container

Docker build for a basic Arch Linux image with gosu. I update the container regularly.

This image is built from scratch.

## Purpose

This docker image is build from scratch with a minimal [Arch Linux][archlinux] installation.
It provides several key features:

* A non-root user and group `docky` (uid:gid=654321:654321) for executing programs inside the container.
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

This image provides a user and group `docky` to run programs as if you like. It is best used with [`gosu`][gosu], as it allows to handle signals properly within the container.

This means that if you map in a volume, the permissions must allow this user to write to it. 
This user has a `UID` of `654321` and a `GID` of `654321` which should not interfere with existing ids on regular
Linux systems. You have to ensure that such a `UID:GID` combination is allowed to write to
your mapped volume. The easiest way is to add group write permissions for the mapped volume
and change the group id of the volume to 654321.

```bash
# To give permissions to the entire project directory, do:
chmod -R g+w /tmp/my-data
chgrp -R 654321 /tmp/my-data
```

## systemd - *not yet functional*

It's possible to use systemd with this container if you enable services in your
Dockerfile and run your container with something like:

    docker run --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
           marcelhuberfoo/arch /usr/lib/systemd/systemd

To stop the container, you could execute ``systemctl poweroff``.

[archlinux]: https://www.archlinux.org
[gosu]: https://github.com/tianon/gosu

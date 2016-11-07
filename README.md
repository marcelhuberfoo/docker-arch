# ArchLinux Container [![](https://images.microbadger.com/badges/version/marcelhuberfoo/arch.svg)](https://microbadger.com/images/marcelhuberfoo/arch "Get your own version badge on microbadger.com")

Docker build for a basic [Arch Linux docker image][archimage] with [`gosu`][gosu].

This image is built from scratch.

## Purpose

This docker image is build from scratch with a somewhat minimal [Arch Linux][archlinux] installation containing `systemd`.
It provides several key features:

* Non-root user and group `nobody` for executing programs inside the container.
* nobody  - even using `sudo`.
* [`gosu`][gosu] to execute binaries as different user forwarding container signals.
* A umask of 0002 for user `nobody`.
* Exported variables `UNAME` and `GNAME` to make use of the user settings from within scripts.

## Usage

For example:

```bash
docker run --interactive --tty --rm marcelhuberfoo/arch env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=935562be7aff
TERM=xterm
UNAME=nobody
GNAME=nobody
HOME=/root
```

## Permissions

This image provides a user and group `nobody` to run programs as user `nobody`. It is best used with [`gosu`][gosu], as it allows to handle signals of the started process properly within the container.

If you map in a volume, permissions on the host folder must allow user or group `nobody` to write to it. You can add yourself to the `nobody` group.

Add yourself to the nobody group:
```bash
gpasswd --add myself nobody
```

Set group permissions to the entire project directory:
```bash
chmod -R g+w /tmp/my-data
chgrp -R nobody /tmp/my-data
```

## systemd

Enabled services would be started in your container if run with something like:

```bash
docker run --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
       --entrypoint /lib/systemd/systemd marcelhuberfoo/arch
```

To stop the container, you could execute ``docker exec -ti <containerid> systemctl poweroff``.

[archlinux]: https://www.archlinux.org
[gosu]: https://github.com/tianon/gosu
[archimage]: https://registry.hub.docker.com/u/marcelhuberfoo/arch/

ArchLinux Container
===================

Docker build for a basic Arch Linux image with sudo and my custom repository
(http://instarch.codekoala.com/). I update the container regularly.

systemd
-------

It's possible to use systemd with this container if you enable services in your
Dockerfile and run your container with something like:

    docker run --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro codekoala/arch /usr/bin/init

To stop the container, you can enable SSH, login remotely, and run ``systemctl
poweroff``.

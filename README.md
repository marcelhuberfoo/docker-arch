ArchLinux Container
===================

Docker build for a basic Arch Linux image with gosu. I update the container regularly.

systemd - *not yet functional*
------------

It's possible to use systemd with this container if you enable services in your
Dockerfile and run your container with something like:

    docker run --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro marcelhuberfoo/arch /usr/lib/systemd/systemd

To stop the container, you could execute ``systemctl poweroff``.

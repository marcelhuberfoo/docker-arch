FROM scratch
MAINTAINER Josh VanderLinden <codekoala@gmail.com>

ENV container docker
ADD arch-rootfs-2014.07.13.tar.xz /

CMD ["/bin/bash"]

# vim:ft=Dockerfile:

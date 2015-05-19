FROM scratch
MAINTAINER Marcel Huber <marcelhuberfoo@gmail.com>

ADD arch-rootfs-2015.05.15.tar.xz /

# allow use of gosu to execute commands as different user
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -sSL https://github.com/tianon/gosu/releases/download/1.4/gosu-amd64 && \
    curl -o /usr/local/bin/gosu.asc -sSL https://github.com/tianon/gosu/releases/download/1.4/gosu-amd64.asc && \
    gpg --verify /usr/local/bin/gosu.asc && rm /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu

ENV UID=1000 GID=100 LANG=en_US.utf8
# add non root user as convenience
RUN useradd --uid $UID --gid $GID --key UMASK=0002 --create-home --comment "Non root user" user
RUN gosu user bash -c 'echo umask 0002 >> $HOME/.bashrc'

CMD ["/bin/bash"]

# vim:ft=Dockerfile:

FROM scratch
MAINTAINER Marcel Huber <marcelhuberfoo@gmail.com>

ADD arch-rootfs-20151109-4.2.5-1.tar.xz /

# allow use of gosu to execute commands as different user
RUN mkdir -p /usr/local/bin && \
    curl -o /usr/local/bin/gosu -sSL https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64 && \
    chmod +x /usr/local/bin/gosu

ENV UID=654321 GID=654321 UNAME=docky GNAME=docky LANG=en_US.utf8
# add non root user as convenience
RUN groupadd -g $GID $GNAME && \
    useradd --uid $UID --gid $GID --key UMASK=0002 --create-home --comment "docker user" $UNAME
USER $UNAME
RUN bash -l -c 'echo umask 0002 >> $HOME/.bashrc'
USER root

CMD ["/bin/bash"]


FROM scratch
MAINTAINER Marcel Huber <marcelhuberfoo@gmail.com>

ADD arch-rootfs-20151109-4.2.5-1.tar.xz /

# allow use of gosu to execute commands as different user
ADD https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64 /usr/local/bin/gosu
RUN chmod +rx /usr/local/bin/gosu

ENV UID=654321 GID=654321 UNAME=docky GNAME=docky LANG=en_US.utf8
# add non root user as convenience
RUN groupadd -g $GID $GNAME && \
    useradd --uid $UID --gid $GID --key UMASK=0002 --create-home --comment "docker user" $UNAME
USER $UNAME
RUN bash -l -c 'echo -e "umask 0002\ncd \$HOME\n" >> $HOME/.bashrc'
USER root

CMD ["/bin/bash"]


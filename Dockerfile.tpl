FROM scratch
MAINTAINER Marcel Huber <marcelhuberfoo@gmail.com>

ADD arch-rootfs-TAG.tar.xz /

USER root

# allow use of gosu to execute commands as different user
RUN mkdir -p /usr/local/bin && \
    curl -o /usr/local/bin/gosu -sSL https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64 && \
    chmod +x /usr/local/bin/gosu

ENV UID=654321 \
    GID=654321 \
    UNAME=docky \
    GNAME=docky \
    LANG=en_US.utf8
# add non root user as convenience
RUN groupadd -g $GID $GNAME && \
    useradd --uid $UID --gid $GID --key UMASK=0002 --create-home --comment "docker user" $UNAME
USER $UNAME
# remove section which disables executing the script in non-interactive mode
RUN sed -ri -e '/If not.*/ d' -e '/\*i\*/ d' $HOME/.bashrc
RUN echo -e "umask 0002\ncd \$HOME\n" >> $HOME/.bashrc
USER root

CMD ["/bin/bash"]


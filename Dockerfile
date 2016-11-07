FROM scratch
MAINTAINER Marcel Huber <marcelhuberfoo@gmail.com>

ARG KERNEL_VERSION
ARG BUILD_TIME
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_TIME \
      org.label-schema.docker.dockerfile="Dockerfile" \
      org.label-schema.name="ArchLinux minimal systemd image" \
      org.label-schema.url="https://github.com/marcelhuberfoo/arch" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/marcelhuberfoo/arch" \
      org.label-schema.version=${BUILD_DATE}_${KERNEL_VERSION} \
      org.label-schema.schema-version="1.0"
ENV KERNEL_VERSION=$KERNEL_VERSION
ENV BUILD_DATE=$BUILD_DATE

ADD arch-rootfs-20161107-4.8.6-1.tar.xz /

USER root

# allow use of gosu to execute commands as different user
RUN mkdir -p /usr/local/bin && \
    curl -o /usr/local/bin/gosu -sSL https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64 && \
    chmod +x /usr/local/bin/gosu

ENV EDITOR=vim \
    UNAME=nobody \
    GNAME=nobody

# prepare non root user
ADD sudo_USER /etc/sudoers.d/$UNAME
RUN mkdir /$UNAME && usermod --home /$UNAME $UNAME && \
    sed -r -e '/If not.*/ d' -e '/\*i\*/ d' /etc/skel/.bashrc >$UNAME/.bashrc && ln -s -r $UNAME/.bashrc $UNAME/.bash_profile && echo -e "umask 0002\ncd \$HOME\n" >> $UNAME/.bashrc && \
    chown -R $UNAME:$GNAME /$UNAME && \
    sed -i "s|USER|$UNAME|" /etc/sudoers.d/$UNAME && chmod 0440 /etc/sudoers.d/$UNAME

CMD ["/bin/bash"]


#
# NOTE: THIS DOCKERFILE IS GENERATED VIA update.sh from Dockerfile.template
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#
FROM gcc:11 as compile-stage

RUN apt update ; \
      apt install cvs -y

RUN useradd opentracker

WORKDIR /usr/src

# http://erdgeist.org/arts/software/opentracker/#build-instructions
RUN cvs -d :pserver:cvs@cvs.fefe.de:/cvs -z9 co libowfat ; \
      cd libowfat ; \
      make ; \
      cd .. ; \
      git clone git://erdgeist.org/opentracker ; \
      cd opentracker ; \
      # Makefile blacklist sed expressions
      sed -ri -e '\
        /^#.*DWANT_ACCESSLIST_BLACK/s/^#//; \
      ' Makefile ; \
      # Build opentracker statically to use it in scratch image
      make CC="gcc -static" ; \
      bash -c 'mkdir -pv /tmp/stage/{etc/opentracker,bin}' ; \
      cp -v opentracker.conf.sample /tmp/stage/etc/opentracker/opentracker.conf ; \
      # Opentrack conf blacklist sed expressions
      sed -ri -e '\
        s!(.*)(tracker.user)(.*)!\2 opentracker!g; \
        s!(.*)(access.blacklist)(.*)!\2 /etc/opentracker/blacklist!g; \
      ' /tmp/stage/etc/opentracker/opentracker.conf ; \
      touch /tmp/stage/etc/opentracker/blacklist ; \
      install -m 755 opentracker.debug /tmp/stage/bin ; \
      make DESTDIR=/tmp/stage BINDIR="/bin" install

FROM scratch

COPY --from=compile-stage /tmp/stage /
COPY --from=compile-stage /etc/passwd /etc/passwd

WORKDIR /etc/opentracker

USER opentracker

EXPOSE 6969

ENTRYPOINT ["/bin/opentracker"]
CMD ["-f", "/etc/opentracker/opentracker.conf"]
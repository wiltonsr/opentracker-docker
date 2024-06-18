#
# NOTE: THIS DOCKERFILE IS GENERATED VIA update.sh from Dockerfile.template
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#
FROM gcc:11 as compile-stage

RUN apt update ; \
  apt install cvs -y

RUN useradd farmhand && \
  usermod -u 6969 farmhand

WORKDIR /usr/src

# Run libowfat compilation in separated layer to benefit from docker layer cache
RUN cvs -d :pserver:cvs@cvs.fefe.de:/cvs -z9 co libowfat ; \
  git clone git://erdgeist.org/opentracker ; \
  cd /usr/src/libowfat ; \
  make

# http://erdgeist.org/arts/software/opentracker/#build-instructions
RUN cd /usr/src/opentracker ; \
      # Makefile whitelist sed expressions
      sed -ri -e '\
        /^#.*DWANT_ACCESSLIST_WHITE/s/^#//; \
      ' Makefile ; \
  # Build opentracker statically to use it in scratch image
  LDFLAGS=-static make ; \
  bash -c 'mkdir -pv /tmp/stage/{etc/opentracker,bin}' ; \
  cp -v opentracker.conf.sample /tmp/stage/etc/opentracker/opentracker.conf ; \
      # Opentrack conf whitelist sed expressions
      sed -ri -e '\
        s!(.*)(tracker.user)(.*)!\2 farmhand!g; \
        s!(.*)(access.whitelist)(.*)!\2 /etc/opentracker/whitelist!g; \
      ' /tmp/stage/etc/opentracker/opentracker.conf ; \
      touch /tmp/stage/etc/opentracker/whitelist ; \
  install -m 755 opentracker.debug /tmp/stage/bin ; \
  make DESTDIR=/tmp/stage BINDIR="/bin" install

FROM scratch

COPY --from=compile-stage /tmp/stage /
COPY --from=compile-stage /etc/passwd /etc/passwd

WORKDIR /etc/opentracker

USER 6969

EXPOSE 6969/udp
EXPOSE 6969/tcp

ENTRYPOINT ["/bin/opentracker"]
CMD ["-f", "/etc/opentracker/opentracker.conf"]

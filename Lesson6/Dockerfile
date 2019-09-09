FROM centos:7
MAINTAINER AcCkAyA SaTaNA (satana@from.hell)
WORKDIR ~/docker-build
ADD fluent-bit-1.2.2-1.el7.x86_64.rpm /
RUN rpm -i /fluent-bit-1.2.2-1.el7.x86_64.rpm
ENTRYPOINT ["/usr/local/bin/fluent-bit"]

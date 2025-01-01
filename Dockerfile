# Dockerfile for beanstalkd
# BUILD
# =====

FROM ubuntu:22.04 AS buildstep
LABEL maintainer="Richard Bullington-McGuire <richard.bullington.mcguire@gmail.com>"

ENV BEANSTALKD_VERSION="1.10"
# This is really key; 0 makes beanstalkd fsync after every write.
# For Freezing Saddles, we want maximum durability and can afford the minor
# performance hit.
ENV BEANSTALKD_FSYNC_AFTER="0"
# Enable verbose log output
ENV BEANSTALKD_VERBOSE="-V"

RUN apt-get update && apt-get install -y software-properties-common build-essential git curl


RUN curl -sL https://github.com/kr/beanstalkd/archive/v${BEANSTALKD_VERSION}.tar.gz | tar xvz -C /tmp

WORKDIR /tmp/beanstalkd-${BEANSTALKD_VERSION}
RUN make
RUN cp beanstalkd /tmp/

# DEPLOY
# =====

FROM ubuntu:22.04 AS deploystep
LABEL maintainer="Richard Bullington-McGuire <richard.bullington.mcguire@gmail.com>"

COPY --from=buildstep /tmp/beanstalkd /usr/bin/beanstalkd

RUN mkdir -p /data
VOLUME /data

EXPOSE 11300

# use a binlog that can be recovered after power failure: -b
# Make beanstalkd sync after every write (This is really key): -f 0
# - For Freezing Saddles, we want maximum durability and can afford the minor performance hit.
# Enable verbose log output:  -V
CMD ["beanstalkd", "-p", "11300", "-f", "0", "-b", "/data", "-V"]

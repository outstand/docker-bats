FROM bats/bats:1.5.0
LABEL maintainer="Ryan Schlesinger <ryan@outstand.com>"

WORKDIR /plugin

RUN addgroup -g 1000 -S ci && adduser --uid 1000 -S -G ci ci && addgroup -g 900 docker && addgroup ci docker && chown ci:ci /plugin

RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
  apk --no-cache add \
		ncurses \
		curl \
		jq \
		docker \
		su-exec \
    docker-cli-compose@edge

ENV COMPOSE_SWITCH_VERSION 1.0.4
RUN curl -fL https://github.com/docker/compose-switch/releases/download/v${COMPOSE_SWITCH_VERSION}/docker-compose-linux-amd64 -o /usr/local/bin/compose-switch && \
    chmod +x /usr/local/bin/compose-switch && \
    ln -s /usr/local/bin/compose-switch /usr/local/bin/docker-compose

# Install bats-support
ENV BATS_SUPPORT_VERSION=0.3.0
RUN mkdir -p /usr/local/lib/bats/bats-support \
    && curl -sSL https://github.com/ztombol/bats-support/archive/v${BATS_SUPPORT_VERSION}.tar.gz -o /tmp/bats-support.tgz \
    && tar -zxf /tmp/bats-support.tgz -C /usr/local/lib/bats/bats-support --strip 1 \
    && printf 'source "%s"\n' "/usr/local/lib/bats/bats-support/load.bash" >> /usr/local/lib/bats/load.bash \
    && rm -rf /tmp/bats-support.tgz

# Install bats-assert
ENV BATS_ASSERT_VERSION=0.3.0
RUN mkdir -p /usr/local/lib/bats/bats-assert \
    && curl -sSL https://github.com/ztombol/bats-assert/archive/v${BATS_ASSERT_VERSION}.tar.gz -o /tmp/bats-assert.tgz \
    && tar -zxf /tmp/bats-assert.tgz -C /usr/local/lib/bats/bats-assert --strip 1 \
    && printf 'source "%s"\n' "/usr/local/lib/bats/bats-assert/load.bash" >> /usr/local/lib/bats/load.bash \
    && rm -rf /tmp/bats-assert.tgz

# Install lox's fork of bats-mock
ENV BATS_MOCK_VERSION=1.3.0
RUN mkdir -p /usr/local/lib/bats/bats-mock \
    && curl -sSL https://github.com/lox/bats-mock/archive/v${BATS_MOCK_VERSION}.tar.gz -o /tmp/bats-mock.tgz \
    && tar -zxf /tmp/bats-mock.tgz -C /usr/local/lib/bats/bats-mock --strip 1 \
    && printf 'source "%s"\n' "/usr/local/lib/bats/bats-mock/stub.bash" >> /usr/local/lib/bats/load.bash \
    && rm -rf /tmp/bats-mock.tgz

ENV BATS_FILE_VERSION=0.3.0
RUN mkdir -p /usr/local/lib/bats/bats-file \
    && curl -sSL https://github.com/bats-core/bats-file/archive/v${BATS_FILE_VERSION}.tar.gz -o /tmp/bats-file.tgz \
		&& tar -zxf /tmp/bats-file.tgz -C /usr/local/lib/bats/bats-file --strip 1 \
		&& printf 'source "%s"\n' "/usr/local/lib/bats/bats-file/load.bash" >> /usr/local/lib/bats/load.bash \
		&& rm -rf /tmp/bats-file.tgz

# Make sure /bin/bash is available, as bats/bats only has it at
# /usr/local/bin/bash and many plugin hooks (and shellscripts in general) use
# `#!/bin/bash` as their shebang
RUN if [[ -e /bin/bash ]]; then echo "/bin/bash already exists"; exit 1; else ln -s /usr/local/bin/bash /bin/bash; fi

# Expose BATS_PATH so people can easily use load.bash
ENV BATS_PATH=/usr/local/lib/bats

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bats", "tests/"]

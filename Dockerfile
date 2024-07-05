ARG DEBIAN_VERSION=11.8-slim
FROM golang:1.22.4-bullseye AS bypass4netns
ENV DEBIAN_FRONTEND=noninteractive
ENV BYPASS4NETNS_VERSION=0.4.1
RUN apt-get update \
    && apt-get install -y \
        curl \
        ca-certificates \
        build-essential \
        libseccomp2 \
        libseccomp-dev \
        --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://github.com/rootless-containers/bypass4netns/archive/refs/tags/v${BYPASS4NETNS_VERSION}.tar.gz > /tmp/bypass4netns.tar.gz \
    && tar -C /tmp -zxvf /tmp/bypass4netns.tar.gz \
    && cd /tmp/bypass4netns-${BYPASS4NETNS_VERSION} \
    && make \
    && mkdir -p /bin/bypass4netns \
    && cp bypass4netns* /bin/bypass4netns


FROM debian:${DEBIAN_VERSION} AS main

ENV ROOTLESS_UID=1000
ENV DOCKER_GID=998
ENV HOME=/home/rootless
ENV DOCKERD_ROOTLESS_ROOTLESSKIT_DEBUG=false

ENV PATH="${PATH}:${HOME}/.local/bin:${HOME}/bin"
ENV DOCKER_HOST="unix:///run/user/${ROOTLESS_UID}/docker.sock"
ENV XDG_RUNTIME_DIR="/run/user/${ROOTLESS_UID}"
ENV XDG_CONFIG_HOME="${HOME}/.config"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y \
        curl \
        ca-certificates \
        iproute2 \
        iptables \
        slirp4netns \
        jq \
        sudo \
        uidmap \
        procps \
        libseccomp2 \
        --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

COPY --from=bypass4netns /bin/bypass4netns/* /bin
COPY bypass4netns-seccomp.json /home/rootless/.config/docker/bypass4netns-seccomp.json

RUN --mount=type=bind,source=build-scripts,target=/opt/build-scripts \
    /opt/build-scripts/setup-rootless-users.sh \
    && /opt/build-scripts/install-docker-rootlesskit.sh ${HOME}/bin

COPY runtime-scripts/* /usr/bin/

USER rootless
VOLUME /var/lib/docker
VOLUME /home/rootless/.local/share/docker
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
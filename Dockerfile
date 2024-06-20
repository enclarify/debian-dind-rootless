ARG DEBIAN_VERSION=11.8-slim
FROM debian:${DEBIAN_VERSION}

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
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        iproute2 \
        jq \
        sudo \
        uidmap \
        procps \
        --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=bind,source=build-scripts,target=/opt/build-scripts \
    /opt/build-scripts/setup-rootless-users.sh \
    && /opt/build-scripts/install-docker-rootlesskit.sh ${HOME}/bin

COPY runtime-scripts/* /usr/bin/

USER rootless
VOLUME /var/lib/docker
VOLUME /home/rootless/.local/share/docker
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
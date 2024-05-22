ARG DEBIAN_VERSION=11.8-slim
FROM debian:${DEBIAN_VERSION}

ENV ROOTLESS_UID=1000
ENV HOME=/home/rootless

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

# Add users for rootlesskit
RUN --mount=type=bind,source=setup-rootless-users.sh,target=/usr/bin/setup-rootless-users.sh \
    setup-rootless-users.sh

RUN --mount=type=bind,source=install-docker-rootlesskit.sh,target=/usr/bin/install-docker-rootlesskit.sh \
    install-docker-rootlesskit.sh ${HOME}/bin

COPY entrypoint.sh /usr/bin/    

USER rootless
VOLUME /var/lib/docker
VOLUME /home/rootless/.local/share/docker
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
ARG DEBIAN_VERSION=11.8-slim
FROM debian:${DEBIAN_VERSION}

ENV CHANNEL=stable
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

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh \
    && chown rootless:rootless /run

# rootlesskit needs to be installed by the rootless user
USER rootless
RUN export SKIP_IPTABLES=1 \
    && curl -fsSL https://get.docker.com/rootless | sh \
    && echo "Removing the '--copy-up=/run' from the dockerd-rootless.sh to allow /run/docker.sock" \
    && sed -i 's| --copy-up=/run||g' /home/rootless/bin/dockerd-rootless.sh \
    && /home/rootless/bin/docker -v

VOLUME /var/lib/docker
VOLUME /home/rootless/.local/share/docker
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
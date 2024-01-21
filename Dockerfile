ARG DEBIAN_VERSION=11.8-slim
FROM debian:${DEBIAN_VERSION}

ENV ROOTLESS_UID=1000
ENV HOME=/home/rootless

ENV PATH="${PATH}:${HOME}/.local/bin:${HOME}/bin"
ENV DOCKER_HOST="unix:///run/user/${ROOTLESS_UID}/docker.sock"
ENV XDG_RUNTIME_DIR="/run/user/${ROOTLESS_UID}"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        iproute2 \
        iptables \
        sudo \
        uidmap \
        fuse-overlayfs \
        --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Add users for rootlesskit
RUN --mount=type=bind,source=setup-rootless-users.sh,target=/usr/bin/setup-rootless-users.sh \
    setup-rootless-users.sh

USER rootless
ENTRYPOINT ["/bin/bash", "-c"]

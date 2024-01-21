ARG DEBIAN_VERSION=11.8-slim
FROM debian:${DEBIAN_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        iproute2 \
        iptables \
        uidmap \
        fuse-overlayfs \
        --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/bash", "-c"]

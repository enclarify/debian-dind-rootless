#!/bin/bash


set -e 

DOCKER_VERSION="26.1.2"
DOCKER_STATIC_BINARY_URL="https://download.docker.com/linux/static/stable/$(uname -m)/docker-${DOCKER_VERSION}.tgz"
DOCKER_ROOTLESS_EXTRAS_STATIC_BINARY_URL="https://download.docker.com/linux/static/stable/$(uname -m)/docker-rootless-extras-${DOCKER_VERSION}.tgz"

# https://docs.kernel.org/networking/ip-sysctl.html
cat << EOF > /etc/sysctl.conf
kernel.unprivileged_userns_clone=1
user.max_user_namespaces=28633
net.ipv4.ping_group_range=0 4294967294
net.ipv4.ip_unprivileged_port_start=0
EOF

mkdir -p /tmp/docker-download

curl -sSL -o /tmp/docker-download/docker.tgz ${DOCKER_STATIC_BINARY_URL}
curl -sSL -o /tmp/docker-download/rootless.tgz ${DOCKER_ROOTLESS_EXTRAS_STATIC_BINARY_URL}

tar -zxf /tmp/docker-download/docker.tgz -C /usr/bin --strip-components=1
tar -zxf /tmp/docker-download/rootless.tgz -C /usr/bin --strip-components=1

/usr/bin/docker -v

chown rootless:rootless /run
# Owned by rootless so we can turn on debugging at runtime
chown rootless:rootless /usr/bin/dockerd-rootless.sh

echo "Removing the '--copy-up=/run' from the dockerd-rootless.sh to allow /run/docker.sock"
sed -i 's| --copy-up=/run||g' /usr/bin/dockerd-rootless.sh

rm -rf /tmp/docker-download
#!/bin/bash

set -e

# allows all system groups to be mapping into 
# rootless user namespace. This allows supplimental groups
# like 'docker' on the host to be properly mapped into 
# rootless containers
# TODO scope this smaller in the future
echo "rootless:1:999" >> /etc/subgid

echo "Adding rootless user"
adduser --disabled-password --gecos "" --uid ${ROOTLESS_UID} rootless
usermod -aG sudo rootless
echo "Creating XDG_RUNTIME_DIR"
mkdir -p ${XDG_RUNTIME_DIR}
chown rootless:rootless ${XDG_RUNTIME_DIR}
chmod a+x ${XDG_RUNTIME_DIR}
mkdir -p ${HOME}/bin
mkdir -p ${HOME}/.config/docker
mkdir -p ${HOME}/.local/share/docker
chown -R rootless:rootless ${HOME}
chown rootless:rootless /run

echo "Creating docker group membership"
addgroup docker --gid ${DOCKER_GID}
usermod -aG docker rootless

echo "Setting up passwordless sudo"
echo "%sudo   ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers
echo "Defaults !env_reset" >> /etc/sudoers
echo "Defaults !always_set_home" >> /etc/sudoers
echo "Defaults env_keep += \"HOME\"" >> /etc/sudoers
echo "Defaults env_keep += \"PATH\"" >> /etc/sudoers
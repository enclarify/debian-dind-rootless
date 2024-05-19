#!/bin/bash

set -eux

echo "Adding rootless user"
adduser --disabled-password --gecos "" --uid ${ROOTLESS_UID} rootless
usermod -aG sudo rootless
mkdir -p ${XDG_RUNTIME_DIR}
chown -R rootless:rootless ${XDG_RUNTIME_DIR}
chmod a+x ${XDG_RUNTIME_DIR}
mkdir -p ${HOME}/bin
mkdir -p ${HOME}/.config/docker
mkdir -p ${HOME}/.local/share/docker
chown -R rootless:rootless ${HOME}

# Reference https://docs.docker.com/engine/security/userns-remap/
echo 'Creating subuid and subgid to enable "--userns-remap=default"'
addgroup --system dockremap
adduser --system --ingroup dockremap dockremap
echo 'dockremap:165536:65536' >> /etc/subuid
echo 'dockremap:165536:65536' >> /etc/subgid

echo "Setting up passwordless sudo"
echo "%sudo   ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers
echo "Defaults !env_reset" >> /etc/sudoers
echo "Defaults !always_set_home" >> /etc/sudoers
echo "Defaults env_keep += \"HOME\"" >> /etc/sudoers
echo "Defaults env_keep += \"PATH\"" >> /etc/sudoers
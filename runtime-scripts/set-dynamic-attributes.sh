#!/bin/bash

set -e

# setup dynamic user/group mapping
echo "Updating rootless gid permissions"
sudo usermod --uid ${ROOTLESS_UID} rootless
sudo chown rootless:rootless ${XDG_RUNTIME_DIR}
sudo chown -R rootless:rootless ${HOME}
sudo chown rootless:rootless /run

echo "Updating docker gid"
sudo groupmod --gid ${DOCKER_GID} docker

if [ "${DOCKERD_ROOTLESS_ROOTLESSKIT_DEBUG}" = true ]; then
    echo "Turning on rootlesskit debugging"
    sed -i 's|exec $rootlesskit|exec $rootlesskit --debug|' /usr/bin/dockerd-rootless.sh
fi

# apply kernel parameters
sudo sysctl --system
#!/bin/bash

set -e

# setup dynamic user/group mapping
echo "Updating rootless gid permissions"
sudo usermod --uid ${ROOTLESS_UID} rootless
sudo chown rootless:rootless ${XDG_RUNTIME_DIR}
sudo chown -R rootless:rootless ${HOME}

# apply kernel parameters
sudo sysctl --system
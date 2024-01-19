#!/bin/sh

sudo apt-get update && sudo apt-get install -y \
    curl \
    procps \
    git \
    --no-install-recommends
sudo rm -rf /var/lib/apt/lists/*
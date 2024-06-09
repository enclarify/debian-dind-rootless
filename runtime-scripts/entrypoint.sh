#!/bin/bash

set -e

echo "Setting dynamic user attributes"
/usr/bin/set-dynamic-attributes.sh

echo "Start rootless with exec"
exec /usr/bin/start-rootless.sh "$@"
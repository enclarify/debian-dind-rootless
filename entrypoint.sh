#!/bin/bash

set -e

create-attribute() {
    local key=$1
    local value=$2

    if [ -n "${value}" ]; then
        jq -n "{ \"${key}\": ${value}}"
    fi
}

create-string-attribute() {
    local key=$1
    local value=$2

    if [ -n "${value}" ]; then
        create-attribute "${key}" "\"${value}\""
    fi
}

create-array() {
    local key=$1
    local value=$2

    if [ -n "${value}" ]; then
        jq -n "{ \"${key}\": \"${value}\" | split(\",\") }"
    fi
}

debug=$(create-attribute "debug" "${DEBUG}")
hosts=$(create-array "hosts" "${HOSTS}")
registry_mirrors=$(create-array "registry-mirrors" "${REGISTRY_MIRRORS}")
insecure_registries=$(create-array "insecure-registries" "${INSECURE_REGISTRIES}")
dns=$(create-array "dns" "${DNS}")
dns_opts=$(create-array "dns-opts" "${DNS_OPTS}")
dns_search=$(create-array "dns-search" "${DNS_SEARCH}")
labels=$(create-array "labels" "${LABELS}")

echo "${debug} ${hosts} ${registry_mirrors} ${insecure_registries} ${dns} ${dns_opts} ${dns_search} ${labels}" \
| jq -s add > ${HOME}/.config/docker/daemon.json

exec ${HOME}/bin/dockerd-rootless.sh --config-file ${HOME}/.config/docker/daemon.json

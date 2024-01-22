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

create-default-address-pool() {
    local pool_base=$1
    local pool_size=$2

    if [ -n "${pool_base}" ] && [ -n "${pool_size}" ]; then
        jq -n "{\"default-address-pools\": [{\"base\": \"${pool_base}\", \"size\": ${pool_size}}]}"
    fi
}

existing_config="{}"
if [ -f ${HOME}/.config/docker/daemon.json ]; then
    existing_config=$(cat ${HOME}/.config/docker/daemon.json)
fi
debug=$(create-attribute "debug" "${DEBUG}")
hosts=$(create-array "hosts" "${HOSTS}")
registry_mirrors=$(create-array "registry-mirrors" "${REGISTRY_MIRRORS}")
insecure_registries=$(create-array "insecure-registries" "${INSECURE_REGISTRIES}")
dns=$(create-array "dns" "${DNS}")
dns_opts=$(create-array "dns-opts" "${DNS_OPTS}")
dns_search=$(create-array "dns-search" "${DNS_SEARCH}")
labels=$(create-array "labels" "${LABELS}")
default_pool=$(create-default-address-pool ${POOL_BASE} ${POOL_SIZE})

echo "${existing_config} ${debug} ${hosts} ${registry_mirrors} ${insecure_registries} ${dns} ${dns_opts} ${dns_search} ${labels} ${default_pool}" \
| jq -s add > ${HOME}/.config/docker/daemon.json

exec ${HOME}/bin/dockerd-rootless.sh --config-file ${HOME}/.config/docker/daemon.json

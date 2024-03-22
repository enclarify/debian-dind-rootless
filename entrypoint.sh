#!/bin/bash

set -e

wait-for-proc-stop() {
    local pid=$1
    while [ -e /proc/${pid} ]
    do
        echo "Process: ${pid} is still running"
        sleep .5
    done
    echo "Process ${pid} has finished"
}

cleanup() {
    echo "Stopping any running containers"
    local container_pids=$(docker ps -aq -f "status=running")

    if [ -n "${container_pids}" ]; then
        echo "Sending SIGHUP to shutdown any containers running a shell like bash"
        docker stop -s SIGHUP ${container_pids}
        echo "Sending SIGINT to any running containers"
        docker stop -s SIGINT ${container_pids}
        echo "Sending SIGTERM to any running containers"
        docker stop -s SIGTERM ${container_pids}
        echo "Waiting for containers to stop"
        docker wait ${container_pids}
    fi

    local containerd_pid=$(pgrep containerd)
    local dockerd_pid=$(pgrep dockerd)

    echo "Sending SIGTERM to dockerd"
    kill -s SIGTERM ${dockerd_pid}

    wait-for-proc-stop ${containerd_pid}
    wait-for-proc-stop ${dockerd_pid}
}

trap cleanup SIGTERM

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

${HOME}/bin/dockerd-rootless.sh --config-file ${HOME}/.config/docker/daemon.json &

ROOTLESS_PID=$!
wait "${ROOTLESS_PID}"
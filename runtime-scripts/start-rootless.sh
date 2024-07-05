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

BYPASS4NETNS_DEBUG_OPTION=
if [ "${BYPASS4NETNS_DEBUG}" = true ]; then
    echo "Turning on bypass4netns debugging"
    BYPASS4NETNS_DEBUG_OPTION="--debug"
fi

bypass4netns ${BYPASS4NETNS_DEBUG_OPTION} --ignore="127.0.0.0/8,10.0.0.0/8,172.0.0.0/8,auto" -p="8080:80" &
${HOME}/bin/dockerd-rootless.sh --seccomp-profile=/home/rootless/.config/docker/bypass4netns-seccomp.json -H unix://${XDG_RUNTIME_DIR}/docker.sock -H unix:///run/docker.sock "$@" &

ROOTLESS_PID=$!
wait "${ROOTLESS_PID}"
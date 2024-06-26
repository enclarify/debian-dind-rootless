# Debian based Rootless Docker-in-Docker

![Build and Push Image](https://github.com/enclarify/debian-dind-rootless/actions/workflows/build_push_image.yml/badge.svg)

## Summary

A Docker image similar to https://hub.docker.com/\_/docker but based on Debian and Rootless Docker only. The image at https://hub.docker.com/\_/docker is based on Alpine Linux which makes using some Docker extensions like the `nvidia-container-toolkit` impossible since it relies on glibc.

The core purpose this project and it's use of rootless dind is the simplicity it brings for developement and CI/CD use cases, not security. The user namespace mapping solves many quality of life issues when files are being shared and modified on the host and in the container at the same time.

## Features

- Rootless dockerd running on Debian
- Use existing projects simpler because dockerd listens at both:
    - ${XDG_RUNTIME_DIR}/docker.sock 
    - /var/run/docker.sock 

## Configuration

All configuration as described on https://hub.docker.com/\_/docker for the rootless tags are supported by this project.

Rootlesskit specific variables can be supplied to override defaults:

- DOCKERD_ROOTLESS_ROOTLESSKIT_DEBUG=(true|false): Toggle rootlesskit debugging. Defaults to "false".
- DOCKERD_ROOTLESS_ROOTLESSKIT_STATE_DIR=DIR: the rootlesskit state dir. Defaults to "$XDG_RUNTIME_DIR/dockerd-rootless".
- DOCKERD_ROOTLESS_ROOTLESSKIT_NET=(slirp4netns|vpnkit|pasta|lxc-user-nic): the rootlesskit network driver. Defaults to "slirp4netns" if slirp4netns (>= v0.4.0) is installed. Otherwise defaults to "vpnkit".
- DOCKERD_ROOTLESS_ROOTLESSKIT_MTU=NUM: the MTU value for the rootlesskit network driver. Defaults to 65520 for slirp4netns, 1500 for other drivers.
- DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER=(builtin|slirp4netns|implicit): the rootlesskit port driver. Defaults to "builtin".
- DOCKERD_ROOTLESS_ROOTLESSKIT_SLIRP4NETNS_SANDBOX=(auto|true|false): whether to protect slirp4netns with a dedicated mount namespace. Defaults to "auto".
- DOCKERD_ROOTLESS_ROOTLESSKIT_SLIRP4NETNS_SECCOMP=(auto|true|false): whether to protect slirp4netns with seccomp. Defaults to "auto".

## Usage example

All the usage examples related to rootless at https://hub.docker.com/\_/docker should work the same with this project. The simplest way to start the rootless container is:

```bash
docker run --name rootless-docker --privileged -d \
enclarify/debian-dind-rootless:11.8-slim-<debian-dind-rootless version>
```
The rootless container can be tested by `docker exec rootless-docker docker info --format "{{.SecurityOptions}}"`. The output should show `[name=seccomp,profile=builtin name=rootless name=cgroupns]`. 

A more practical example adds volumes to persist docker state, such as container images, and mounts the rootless docker socket back to the host. In order to write the docker socket with the correct permissions the `ROOTLESS_UID` environment variable is required to supply the UID of the current host user. The default value of `ROOTLESS_UID` is `1000` which should be the default for most users of a Linux host. 

```bash
docker run --name rootless-docker --privileged -d \
-e ROOTLESS_UID=$(id -u) \
--mount type=volume,src=rootless-storage,dst=/var/lib/docker \
--mount type=volume,src=rootless-user-storage,dst=/home/rootless/.local/share/docker \
--mount type=bind,src=${XDG_RUNTIME_DIR},dst=${XDG_RUNTIME_DIR} \
enclarify/debian-dind-rootless:11.8-slim-<debian-dind-rootless version>
```

The rootless container can be tested by `docker -H unix://${XDG_RUNTIME_DIR}/docker.sock info --format "{{.SecurityOptions}}"`. The output should show `[name=seccomp,profile=builtin name=rootless name=cgroupns]`

[!WARNING]
It shoud be noted that if the rootless docker is bind mounted to the host then it must be gracefully stopped with `docker stop rootless-docker`. Otherwise stale socket and pid files will be left on disk which will prevent the rootless container from starting again until they are manually removed from `XDG_RUNTIME_DIR`. Usuually `XDG_RUNTIME_DIR` is located at `/var/run/user/1000`. In the case of an unclean shutdown the files that need to be removed manually are:

```
drwxr-xr-x  2 user1  group1  200 Mar 16 07:51 dockerd-rootless
-rw-r--r-T  1 user1  group1    2 Mar 16 07:51 docker.pid
srw-rw---T  1 user1  group1    0 Mar 16 07:51 docker.sock
```


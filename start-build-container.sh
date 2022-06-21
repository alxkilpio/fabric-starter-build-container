#!/usr/bin/env bash

export GRADLE_UID=$(id -u)
export DOCKER_GID=$(grep "^docker:" /etc/group | awk -F: '{print $3}')

docker-compose up --force-recreate -d


#!/usr/bin/env bash

BUILDING_CONTAINER_NAME="fabric_starter_builder_container"
CONTAINER_USER="gradle"
CONTAINER_SSH_CONF_DIR="/home/${CONTAINER_USER}/.ssh"
KEYS_DIR='./keys'

mkdir -p ${KEYS_DIR}
find ${KEYS_DIR} -type f -exec rm {} \;

ls -la

containerIP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${BUILDING_CONTAINER_NAME})
echo "${BUILDING_CONTAINER_NAME} container IP address: ${containerIP}"

ls -la

ssh-keygen -t rsa -b 4096 -f ${KEYS_DIR}/id_rsa_builder -C "jenkins@jenkins" -N "" -q

ls -la

docker container exec --user ${CONTAINER_USER} ${BUILDING_CONTAINER_NAME} bash -c \
    "mkdir -p ${CONTAINER_SSH_CONF_DIR}; chmod 700 ${CONTAINER_SSH_CONF_DIR}"

docker cp ${KEYS_DIR}/id_rsa_builder.pub ${BUILDING_CONTAINER_NAME}:${CONTAINER_SSH_CONF_DIR}/

docker container exec --user ${CONTAINER_USER} ${BUILDING_CONTAINER_NAME} bash -c \
    "cat ${CONTAINER_SSH_CONF_DIR}/id_rsa_builder.pub >> ${CONTAINER_SSH_CONF_DIR}/authorized_keys; chmod 700 ${CONTAINER_SSH_CONF_DIR}/authorized_keys"

ssh-keygen -R ${containerIP}
ssh -o StrictHostKeyChecking=no ${CONTAINER_USER}@${containerIP} -i ${KEYS_DIR}/id_rsa_builder hostname
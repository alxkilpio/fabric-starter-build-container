#!/usr/bin/env bash
#docker image build -t kilpio/jenkins_dockerized .
repo=${1:-'kilpio'}
docker image build --no-cache -t ${repo}/fabric-starter-builder-container:latest .




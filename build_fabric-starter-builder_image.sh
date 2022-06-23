#!/usr/bin/env bash
#docker image build -t alxkilpio/jenkins_dockerized .
repo=${1:-'alxkilpio'}
docker image build --no-cache -t ${repo}/fabric-starter-builder-container:latest .




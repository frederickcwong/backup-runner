#!/bin/bash

SRC_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z "$1" ] 
then
    echo "Error: need versioning argument"
    echo "e.g. ./build.sh 0.1.0"
    exit 1
fi

docker buildx build --platform=linux/amd64 \
    --no-cache \
    --build-arg VERSION=$1 \
    -t frederickwong/backup-runner:$1 \
    -t frederickwong/backup-runner:latest \
    --push ${SRC_DIR}


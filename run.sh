#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo
echo ========================================================================
echo "Backup started on $(date)"

DOCKER_DIR=${SCRIPT_DIR}/docker
DATA_DIR=${SCRIPT_DIR}/data
MEDIA_DIR=${SCRIPT_DIR}/media
WORKING_DIR=${SCRIPT_DIR}/temp

DOCKER_SERVICES=${DOCKER_SERVICES:=$(
        cd ${DOCKER_DIR} && docker compose ps --services | grep -v "backup-runner" | xargs)}

TAR_TARGET=data-`date +"%F-%H-%M"`.tar.gz

echo "+------------------------------+"
echo "| Pausing docker services...   |"
echo "+------------------------------+"
# compose filename and project name are set in env
(cd ${DOCKER_DIR}; docker compose pause ${DOCKER_SERVICES})

echo
echo "+------------------------------+"
echo "| rsync'ing...                 |"
echo "+------------------------------+"
rsync -achvHXA ${DATA_DIR} ${WORKING_DIR}

echo
echo "+------------------------------+"
echo "| Unpausing docker services... |"
echo "+------------------------------+"
(cd ${DOCKER_DIR}; docker compose unpause ${DOCKER_SERVICES})

echo
echo "+------------------------------+"
echo "| tar'ing...                   |"
echo "+------------------------------+"
tar czf ${MEDIA_DIR}/${TAR_TARGET} -C ${WORKING_DIR} data

if test -f ${MEDIA_DIR}/${TAR_TARGET}; then
        echo "Backup file created: $TAR_TARGET"
else
        echo "Error creating backup file: $TAR_TARGET"
fi

echo
echo "Backup completed on $(date)"
echo ========================================================================

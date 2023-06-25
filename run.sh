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

MESSAGE_TITLE="No message title"
MESSAGE_BODY="No message body"

# create the tar ball
tar czf ${SCRIPT_DIR}/${TAR_TARGET} -C ${WORKING_DIR} data

# obtain backup storage space availability and space needed
SPACE_AVAILABLE=$(df $MEDIA_DIR | tail -1 | awk '{print $4}')
SPACE_NEEDED=$(du ${SCRIPT_DIR}/${TAR_TARGET} | awk '{print $1}')

# move the tarball to backup storage
if [[ $SPACE_AVAILABLE -gt $SPACE_NEEDED ]]; then
        mv ${SCRIPT_DIR}/${TAR_TARGET} ${MEDIA_DIR}
        if test -f ${MEDIA_DIR}/${TAR_TARGET}; then
                MESSAGE_TITLE="Success: backup file created: $TAR_TARGET"
                MESSAGE_BODY="Backup file moved to storage media successfully."
        else
                MESSAGE_TITLE="Failed: error creating backup: $TAR_TARGET"
                MESSAGE_BODY="Backup file created but failed moving to the storage media."
        fi
else
        MESSAGE_TITLE="Failed: insufficient storage space"
        MESSAGE_BODY="`du -h ${SCRIPT_DIR}/${TAR_TARGET} | \
                awk '{print \"Storage needed: \"$1}'` `df -h $MEDIA_DIR | \
                tail -1 | awk '{print \" (Total: \"$2\", Used: \"$3\", Avail: \"$4\")\"}'`"
fi

# determine if disk space is below the threshold
AVAIL_MB=$(df -BM ${MEDIA_DIR} | tail -1 | awk '{print $4}' | sed 's/M//')
if [[ $AVAIL_MB -lt $WARNING_THRESHOLD_MB ]]; then
        MESSAGE_BODY=$(cat <<EOF
${MESSAGE_BODY}
!!! Warning: Available space is less than ${WARNING_THRESHOLD_MB}M !!!
EOF
)
fi

# output result to console log
echo $MESSAGE_TITLE
echo $MESSAGE_BODY

# use shoutrrr to send notification
if [[ ! -z "$SHOUTRRR_URL" ]]; then
        echo
        echo "+------------------------------+"
        echo "| Sending notification...      |"
        echo "+------------------------------+"
        echo "Sending notification using shoutrrr..."
        MESSAGE_BODY=$(cat <<EOF
${MESSAGE_BODY}
Backup completed on: `date +"%F-%H-%M"`
EOF
)
        ${SCRIPT_DIR}/shoutrrr send -u "${SHOUTRRR_URL}" -t "${MESSAGE_TITLE}" -m "${MESSAGE_BODY}"
fi

echo
echo "Backup completed on $(date)"
echo ========================================================================

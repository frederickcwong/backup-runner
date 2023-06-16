#!/bin/bash

# make sure the environment variables are available to the cron daemon
# otherwise, the cron job will run without ENV values
printenv >> /etc/environment

# initialize the crontab for root user
echo "${CRON_SCHEDULE} bash /backup/run.sh > /proc/1/fd/1 2>&1" | crontab -

echo
echo ========================================================================
echo "Backup Runner version: ${VERSION} running on Ubuntu $(cat /etc/os-release | grep VERSION_ID | awk -F= '{print $2}')"
echo "Cron schedule:            ${CRON_SCHEDULE}"
echo "Docker Info:"
echo "    Compose Version:      $(docker compose version | awk '{print $4}')"
echo "    Compose Filename:     ${COMPOSE_FILE}"
echo "    Compose Project Name: ${COMPOSE_PROJECT_NAME}"
echo "    Docker Services:      ${DOCKER_SERVICES}"
echo ========================================================================
echo

# exec the CMD
exec "$@"

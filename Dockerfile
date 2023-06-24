FROM ubuntu:latest

ARG VERSION=default
ENV VERSION=${VERSION} \
    CRON_SCHEDULE="0 2 * * *" \
    COMPOSE_FILE="docker-compose.yml" \
    COMPOSE_PROJECT_NAME="home-automation" \
    DOCKER_SERVICES=

RUN \
    # setup for docker repo
    apt-get update && apt-get upgrade -y && \
    apt-get install -y ca-certificates curl gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    # install docker
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    # install cron and rsync
    apt-get install -y cron rsync

# copy init and backup script
COPY --chmod=744 ["init.sh", "run.sh", "/backup/"]

# setup crontab using init.sh, then execute CMD from init.sh
# note: because CMD will be appended to entrypoint as arguments
ENTRYPOINT ["/backup/init.sh"]
CMD ["cron", "-f"]

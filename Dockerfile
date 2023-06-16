FROM ubuntu:latest

ARG VERSION=default
ENV VERSION=${VERSION}
ENV CRON_SCHEDULE="0 2 * * *"
ENV COMPOSE_FILE="docker-compose.yml"
ENV COMPOSE_PROJECT_NAME="home-automation"
ENV DOCKER_SERVICES=

# setup for docker install
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y ca-certificates curl gnupg
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

# install docker
RUN apt-get update
RUN apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# setup backup script
RUN mkdir -p /backup
COPY --chmod=744 init.sh /backup
COPY --chmod=744 run.sh /backup
RUN apt-get install -y cron rsync

# setup crontab using init.sh, then execute CMD from init.sh
# note: because CMD will be appended to entrypoint as arguments
ENTRYPOINT ["/backup/init.sh"]
CMD ["cron", "-f"]

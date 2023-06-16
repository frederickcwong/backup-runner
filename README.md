# backup-runner

Docker container to backup data periodically using cron.

The container runs a backup script based on a cron schedule. It copies data that needs to be
backup, and creates a compressed tar archive with date and timestamp in this format:
`data-yyyy-mm-dd-hh-mm.tar.gz`. The script will pause docker containers while copying
the data, and it will resume all paused containers once the data is transferred. The following is
a sample docker compose that uses the `backup-runner` container.

```yaml
version: "3"
services:
  backup-runner:
    image: frederickwong/backup-runner:latest
    restart: unless-stopped
    environment:
      - COMPOSE_PROJECT_NAME=<docker compose project name>
      - COMPOSE_FILE=<docker compose filename>
      - DOCKER_SERVICES=<list of services to be paused before backup process>
      - CRON_SCHEDULE=<cron schedule>
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock
      - /docker/compose/directory:/backup/docker
      - /data/directory:/backup/data
      - /backup/directory:/backup/media
```

[Docker Hub Image](https://hub.docker.com/repository/docker/frederickwong/backup-runner/general)

## Environment Variables

- **COMPOSE_FILE** - the name of the docker compose file in the docker compose project directory
  (_default: docker-compose.yml_)

- **COMPOSE_PROJECT_NAME** - the docker compose's project name. It is default to the directory name
  where the docker compose file is located. e.g. "/root/my-project/docker-compose.yml" will have a
  default compose project name "my-project" assigned by docker. The project name is needed in order for
  the `backup-runner` to pause/unpause the containers. (_default: home-automation_, because I used
  this container for my home automation system).

- **DOCKER_SERVICES** - a space-separated list of services to be paused before the backup process.
  Do not include the `backup-runner` in the list. The backup script will default to all services
  listed in the compose file (except the service named contains the word "backup-runner")
  if this value is not provided or is an empty string. For example:

  ```yaml
  - DOCKER_SERVICES=nginx homeassistant my-other-service
  ```

- **CRON_SCHEDULE** - standard 5-field cron schedule expression. Use [this site](https://crontab.guru/) to
  help setting the desire schedule (\*default: 0 2 \* \* \*\*, at 2am daily).

## Volume Mappings

- `/etc/localtime:/etc/localtime:ro` - to set the timezone using host machine's timezone

- `/var/run/docker.sock:/var/run/docker.sock` - the backup script needs to be able to access the host's
  docker socket (to pause and unpause the services)

- `/docker/compose/directory:/backup/docker` - map the host directory that contains the docker compose
  file to `/backup/docker` in the container. For example, if your docker compose file is in `/root/private-project/docker-compose.yml`:

  ```yaml
  - /root/private-project:/backup/docker
  ```

  Note: in this example, the environment variable settings are

  - `COMPOSE_PROJECT_NAME=private-project`
  - `COMPOSE_FILE=docker-compose.yml`

- `/data/directory:/backup/data` - indicates the source directory for the backup process. Everything in
  `/data/directory` will be backup. If more than one directory needs to be backup, it can be done by
  mapping directories into separate "sub-directories" in `/backup/data`. For example, if `/root/myproject/data`
  and `/root/myproject/secrets` need to be backup, it can be done as follows:
  ```yaml
  - /root/myproject/data:/backup/data/data
  - /root/myproject/secrets:/backup/data/secrets
  ```
- `/backup/directory:/backup/media` - indicates the destination directory to store the compressed tar archive.
  It can be an external storage device as long as it is permanently mounted to the filesystem.

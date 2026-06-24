# Docker Setup

This directory contains the Docker Compose configuration for running PIH Lesotho EMR locally or in CI.

For most use cases, use [`docker.sh`](../docker.sh) from the repository root rather than invoking compose directly.

## Compose files

| File | Purpose |
|---|---|
| `compose.yaml` | Main stack: `db` (MySQL 5.6) + `openmrs` |
| `compose.seed.yaml` | Uses a pre-seeded Docker image for fast startup |
| `compose.override.yaml` | Exposes MySQL and Tomcat debug ports (opt-in) |

`compose.yaml` builds the OpenMRS image from `distro/target/distro/web`, which requires a prior `mvn clean package`. The `--build` option in `docker.sh` handles this automatically.

To expose the database and Tomcat debug ports, edit `default.env`:

```
COMPOSE_FILE=compose.yaml:compose.override.yaml
```

## Environment variables

All variables are defined in `default.env` and can be overridden with shell environment variables.

| Variable | Default | Description |
|---|---|---|
| `SERVICE_NAME` | `lesotho-emr` | Docker Compose project name |
| `OPENMRS_IMAGE_TAG` | `latest` | Tag of the OpenMRS Docker image to pull |
| `DB_IMAGE` | `mysql:5.6` | MySQL image |
| `OMRS_DB_USER` | `openmrs` | Database user |
| `OMRS_DB_PASSWORD` | `openmrs` | Database password |
| `MYSQL_ROOT_PASSWORD` | `openmrs` | MySQL root password |
| `TOMCAT_HTTP_PORT` | `8080` | Port OpenMRS is exposed on |
| `MYSQL_PORT` | `3306` | Port MySQL is exposed on (override only) |
| `TOMCAT_DEBUG_PORT` | `1044` | Tomcat remote debug port (override only) |
| `PIH_CONFIG` | `lesotho,lesotho-botsabelo-demo` | PIH configuration profile |
| `DBEVENT_ENABLED` | `false` | Enable DB event module |
| `ACTIVITYLOG_ENABLED` | `false` | Enable activity log module |
| `DB_MEMORY_LIMIT` | `2g` | Docker memory limit for the database container |
| `OPENMRS_MEMORY_LIMIT` | `4g` | Docker memory limit for the OpenMRS container |
| `OMRS_JAVA_MEMORY_OPTS` | `-Xms512m -Xmx2g -XX:NewSize=128m` | JVM memory settings |
| `DB_MAX_ALLOWED_PACKET` | `1G` | MySQL max allowed packet size |
| `DB_INNODB_BUFFER_POOL_SIZE` | `2G` | MySQL InnoDB buffer pool size |

## Using compose directly

To invoke compose directly without `docker.sh` (e.g. in CI):

```bash
# Start fresh (full initialization, ~30 minutes)
SITE=botsabelo-demo \
  PIH_CONFIG=lesotho,lesotho-botsabelo-demo \
  docker compose -f docker/compose.yaml --env-file docker/default.env up -d

# Start with pre-seeded image (~5 minutes)
SITE=botsabelo-demo \
  PIH_CONFIG=lesotho,lesotho-botsabelo-demo \
  docker compose -f docker/compose.seed.yaml --env-file docker/default.env up -d
```

To wipe all volumes for a clean restart, pass `-v` to `down`:

```bash
docker compose -f docker/compose.seed.yaml --env-file docker/default.env down -v
```

## Seeded environments

> **Note:** Nightly seeded image builds are not yet configured for this repository.

Once configured, nightly CI will publish pre-seeded images per site. A seeded image has OpenMRS fully initialized, so startup takes ~5 minutes instead of ~30 minutes. `docker.sh start` will use the seeded image by default; pass `--fresh` to initialize from scratch using `compose.yaml`.

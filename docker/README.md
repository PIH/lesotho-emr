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

A nightly CI workflow builds and publishes pre-initialized seed images to Docker Hub for each site. A seeded image has OpenMRS fully initialized, so startup takes ~5 minutes instead of ~30 minutes. `docker.sh start` uses the seeded image by default; pass `--fresh` to initialize from scratch using `compose.yaml`.

| Site | Image |
|---|---|
| `botsabelo-demo` | [`partnersinhealth/lesotho-emr-seed-botsabelo-demo`](https://hub.docker.com/r/partnersinhealth/lesotho-emr-seed-botsabelo-demo) |

To pin to a specific version, set `SEED_IMAGE_TAG=<version>`. To wipe all volumes for a clean re-seed, pass `-v` to `down`:

```bash
SITE=botsabelo-demo \
  PIH_CONFIG=lesotho,lesotho-botsabelo-demo \
  docker compose -f docker/compose.seed.yaml --env-file docker/default.env down -v
```

## Running on Windows

This section walks through how to run a local OpenMRS instance on a Windows machine — no programming experience required.

### What you need

- Windows 10 (version 2004 or later) or Windows 11
- At least 8 GB RAM (16 GB recommended — OpenMRS uses a lot of memory)
- A reliable internet connection for the initial download

### One-time setup

**Step 1 — Install Windows Subsystem for Linux**

Open PowerShell in administrator mode by right-clicking and selecting "Run as administrator" and enter the following command:

```powershell
wsl --install
```

Reboot your computer.

**Step 2 — Download the setup script and run it**

Open the Ubuntu terminal from your start menu and paste the following command:

```bash
curl https://raw.githubusercontent.com/PIH/lesotho-emr/refs/heads/main/docker/setup.sh | sudo bash
```

When the process is complete, close the Ubuntu terminal window and relaunch it from the Start Menu.
You only need to do this once. The `lesotho-emr` folder now contains everything needed to run the environment.

### Starting an environment

In the Ubuntu terminal (make sure you are inside the `lesotho-emr` folder — run `cd lesotho-emr` if needed), run:

```bash
./docker.sh botsabelo-demo start
```

The first time you start, Docker will download the pre-initialized image from the internet. This can take 10–20 minutes depending on your connection. Subsequent starts will be much faster.

Once the download is complete, run the following command to be notified when OpenMRS is fully ready:

```bash
./docker.sh botsabelo-demo wait
```

When you see **OpenMRS is ready**, open a browser and go to:

**http://localhost:8080/openmrs**

### Stopping

When you are done, stop the environment to free up memory. Your data is preserved and will be there when you start again.

```bash
./docker.sh botsabelo-demo stop
```

To wipe all data and start completely fresh next time:

```bash
./docker.sh botsabelo-demo destroy
```

### Keeping the scripts up to date

Periodically run the following in the Ubuntu terminal from inside the `lesotho-emr` folder to pick up any script updates:

```bash
git pull
```

### Troubleshooting

**"Permission denied when connecting to Docker" or similar error**
Close the Ubuntu terminal and reopen it from the Start Menu. The docker group change applied by the setup script only takes effect in new sessions.

**OpenMRS runs very slowly or runs out of memory**
WSL2 limits how much memory it can use by default. Create or edit `C:\Users\<YourName>\.wslconfig` with the following content, then restart WSL (`wsl --shutdown` in PowerShell):

```
[wsl2]
memory=8GB
```

**"Permission denied" when running `./docker.sh`**
Run this once to make the script executable:
```bash
chmod +x docker.sh
```

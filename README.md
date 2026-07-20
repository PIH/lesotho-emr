# PIH Lesotho EMR Distribution

This repository defines the OpenMRS distribution for PIH Lesotho. It packages together the [PIH EMR](https://github.com/PIH/openmrs-distro-pihemr) parent distribution, Lesotho-specific content, and the PIH EMR frontend into a single deployable artifact. For background on OpenMRS distributions, see the [OpenMRS wiki](https://wiki.openmrs.org/display/docs/OpenMRS+Distributions).

## Repository Structure

| Directory | Description |
|---|---|
| [`content/`](content/README.md) | Lesotho-specific OpenMRS content package (Initializer configuration files) |
| [`distro/`](distro/README.md) | Distribution definition — resolves all component versions into `openmrs-distro.properties` |
| [`docker/`](docker/README.md) | Docker Compose setup for local and CI environments |

## Components

| Component | Artifact |
|---|---|
| PIH EMR parent distro | `org.openmrs.distro:pihemr` |
| PIH EMR shared content | `org.pih.openmrs:pihemr-content` |
| Lesotho content | `org.pih.openmrs:lesotho-content` |
| PIH EMR frontend | `org.pih.openmrs:openmrs-frontend-pihemr` |

Component versions are defined in `distro/pom.xml` and resolved into `distro/openmrs-distro.properties` at build time.

## Sites

| Site | PIH Config |
|---|---|
| `botsabelo-demo` | `lesotho,lesotho-botsabelo-demo` |

## Running on Windows

For step-by-step instructions to run a local environment on Windows, see the [Running on Windows](docker/README.md#running-on-windows) section of the Docker setup guide.

## Developer Guide

Local development runs through the shared
[`openmrs-contrib-distro-tools`](https://github.com/PIH/openmrs-contrib-distro-tools) CLI
(`docker.sh`/`sdk.sh`), installed once per machine rather than embedded in this repo. See
[`docker/README.md`](docker/README.md) for the full quick start, environment variable reference,
and Windows walkthrough.

### Docker (`docker.sh`)

Create a `botsabelo-demo` instance pointing at this repo, then run day-to-day commands by instance
name:

```bash
IMAGE_NAME=partnersinhealth/lesotho-emr \
  SEED_IMAGE_NAME=partnersinhealth/lesotho-emr-seed-botsabelo-demo \
  PIH_CONFIG=lesotho,lesotho-botsabelo-demo \
  DISTRO_SOURCE_DIR="$(pwd)" \
  ~/openmrs-contrib-distro-tools/docker.sh create botsabelo-demo

~/openmrs-contrib-distro-tools/docker.sh botsabelo-demo start
~/openmrs-contrib-distro-tools/docker.sh botsabelo-demo wait
```

| Command | Description |
|---|---|
| `start` | Start the stack |
| `wait` | Wait for OpenMRS to finish initializing |
| `update` | Stop and restart the stack |
| `build` | Build the distribution from source and create a local Docker image |
| `pull` | Pull the images this instance would use, without starting anything |
| `stop` | Stop the running stack |
| `logs` | Tail container logs |
| `destroy` | Stop the stack, delete all volumes, and remove the instance directory |

| Option | Description |
|---|---|
| `--build` | Build the distribution from source before starting |
| `--fresh` | Initialize OpenMRS from scratch instead of using a pre-seeded image |
| `--dev` | Expose debug ports and mount a locally-built distro over the image |
| `--force` | Skip the confirmation prompt (`destroy` only) |

By default, `start` uses a pre-seeded image for fast startup (~5 minutes). Pass `--fresh` to
initialize from scratch (~30 minutes).

**Example — build from source and start:**
```bash
~/openmrs-contrib-distro-tools/docker.sh botsabelo-demo start --build
```

**Example — run on a different port:** edit `TOMCAT_HTTP_PORT` in the instance's own env file
(`~/openmrs/botsabelo-demo/env`) rather than passing it on the command line — `docker.sh` sources
that file directly, so a value already set there always wins over a same-named shell override.

See [`docker/README.md`](docker/README.md) for the full instance `env` file reference.

### OpenMRS SDK (`sdk.sh`)

Use `sdk.sh` to run a site using the [OpenMRS SDK](https://wiki.openmrs.org/display/docs/OpenMRS+SDK), which sets up a local Tomcat server with its own MySQL instance.

```
~/openmrs-contrib-distro-tools/sdk.sh <command> <server-id>
```

The server ID is a local name of your choosing — it controls the server directory
(`~/openmrs/<server-id>`) and defaults the database name. Examples below use `lesotho` but you can
use anything.

| Command | Description |
|---|---|
| `create` | Set up a new SDK server |
| `update` | Redeploy updated artifacts to an existing server |
| `update-config` | Redeploy configuration only to an existing server |
| `run` | Start the server (Ctrl+C to stop) |
| `destroy` | Delete the server and all its data |

**Example — first-time setup:**
```bash
DISTRO_SOURCE_DIR="$(pwd)" PIH_CONFIG=lesotho,lesotho-botsabelo-demo \
  ~/openmrs-contrib-distro-tools/sdk.sh create lesotho
~/openmrs-contrib-distro-tools/sdk.sh run lesotho
```

**Example — after updating component versions:**
```bash
DISTRO_SOURCE_DIR="$(pwd)" ~/openmrs-contrib-distro-tools/sdk.sh update lesotho
~/openmrs-contrib-distro-tools/sdk.sh run lesotho
```

**Example — redeploy configuration only:**
```bash
DISTRO_SOURCE_DIR="$(pwd)" ~/openmrs-contrib-distro-tools/sdk.sh update-config lesotho
~/openmrs-contrib-distro-tools/sdk.sh run lesotho
```

#### Environment variable overrides

| Variable | Default | Commands | Description |
|---|---|---|---|
| `SERVER_ID` | positional arg | all | SDK server directory name |
| `DISTRO_SOURCE_DIR` | current directory | all | Path to this repo's checkout |
| `PIH_CONFIG` | _(required)_ | `create` | PIH config profile passed to SDK setup — e.g. `lesotho,lesotho-botsabelo-demo` |
| `SERVER_PORT` | `8080` | `create` | Tomcat HTTP port |
| `DEBUG_PORT` | `1044` | `create` | Remote debug port |
| `JMX_PORT` | _(disabled)_ | `run` | Enable JMX monitoring on this port |
| `DB_CONTAINER` | _(SDK-managed)_ | `create`, `destroy` | Connect to an existing Docker MySQL container |
| `DB_HOST` | `localhost` | `create` | Database host (when `DB_CONTAINER` is set) |
| `DB_PORT` | `3308` | `create` | Database port (when `DB_CONTAINER` is set) |
| `DB_NAME` | server ID | `create`, `destroy` | Database name |
| `DB_USER` | `root` | `create`, `destroy` | Database user |
| `DB_PASSWORD` | `root` | `create`, `destroy` | Database password |

**Example — run with JMX monitoring:**
```bash
JMX_PORT=9000 ~/openmrs-contrib-distro-tools/sdk.sh run lesotho
```

**Example — connect to an existing Docker MySQL container:**
```bash
DISTRO_SOURCE_DIR="$(pwd)" DB_CONTAINER=mysql56 DB_PORT=3306 PIH_CONFIG=lesotho,lesotho-botsabelo-demo \
  ~/openmrs-contrib-distro-tools/sdk.sh create lesotho
~/openmrs-contrib-distro-tools/sdk.sh run lesotho
```

### Seeded Environments

`docker.sh start` uses a pre-seeded image by default for fast startup (~5 minutes). Pass `--fresh` to initialize from scratch (~30 minutes). See the [Seeded environments](docker/README.md#seeded-environments) section of the Docker setup guide for details.

## CI and Publishing

CI is handled by GitHub Actions. On every push to `main`, the [Build and deploy](.github/workflows/build-and-deploy.yml) workflow:

1. Builds and publishes the Maven artifact to [Maven Central](https://central.sonatype.com/artifact/org.pih.openmrs/lesotho-distro) as `org.pih.openmrs:lesotho-distro`.
2. Builds and pushes a multi-platform Docker image (amd64 + arm64) to Docker Hub at [`partnersinhealth/lesotho-emr`](https://hub.docker.com/r/partnersinhealth/lesotho-emr), tagged with both `latest` and the Maven project version.

A separate [Build seeded images](.github/workflows/build-seeded-images.yml) workflow runs nightly and publishes pre-initialized seed images to Docker Hub:

| Image | Tags |
|---|---|
| [`partnersinhealth/lesotho-emr-seed-botsabelo-demo`](https://hub.docker.com/r/partnersinhealth/lesotho-emr-seed-botsabelo-demo) | `latest`, version |

See [Seeded environments](docker/README.md#seeded-environments) for usage.

A separate [Update Versions](.github/workflows/update-versions.yml) workflow runs hourly and automatically commits any available snapshot dependency updates to `main`.

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

### Docker (`docker.sh`)

Use `docker.sh` to run a site locally using Docker Compose.

```
./docker.sh <site> <command> [options]
```

| Command | Description |
|---|---|
| `start` | Start the stack |
| `wait` | Wait for OpenMRS to finish initializing |
| `update` | Stop and restart the stack |
| `build` | Build the distribution from source and create a local Docker image |
| `stop` | Stop the running stack |
| `logs` | Tail container logs |
| `destroy` | Stop the stack and delete all volumes (wipes database) |

| Option | Description |
|---|---|
| `--build` | Build the distribution from source before starting |
| `--fresh` | Initialize OpenMRS from scratch instead of using a pre-seeded image |

By default, `start` uses a pre-seeded image for fast startup (~5 minutes). Pass `--fresh` to initialize from scratch (~30 minutes).

**Example — start with pre-seeded image (default):**
```bash
./docker.sh botsabelo-demo start
```

**Example — wait for OpenMRS to be ready:**
```bash
./docker.sh botsabelo-demo wait
```

**Example — build from source and start:**
```bash
./docker.sh botsabelo-demo start --build
```

**Example — run on a different port:**
```bash
TOMCAT_HTTP_PORT=9090 ./docker.sh botsabelo-demo start
```

See [`docker/README.md`](docker/README.md) for the full Docker Compose reference including all environment variables.

### OpenMRS SDK (`sdk.sh`)

Use `sdk.sh` to run a site using the [OpenMRS SDK](https://wiki.openmrs.org/display/docs/OpenMRS+SDK), which sets up a local Tomcat server with its own MySQL instance.

```
./sdk.sh <site> <command>
```

| Command | Description |
|---|---|
| `create` | Set up a new SDK server for the given site |
| `update` | Redeploy updated artifacts to an existing server |
| `update-config` | Redeploy configuration only to an existing server |
| `run` | Start the server (Ctrl+C to stop) |
| `destroy` | Delete the server and all its data |

**Example — first-time setup:**
```bash
./sdk.sh botsabelo-demo create
./sdk.sh botsabelo-demo run
```

**Example — after updating component versions:**
```bash
./sdk.sh botsabelo-demo update
./sdk.sh botsabelo-demo run
```

**Example — redeploy configuration only:**
```bash
./sdk.sh botsabelo-demo update-config
./sdk.sh botsabelo-demo run
```

#### Environment variable overrides

| Variable | Default | Description |
|---|---|---|
| `SERVER_ID` | site name | SDK server directory name |
| `SERVER_PORT` | `8080` | Tomcat HTTP port |
| `DEBUG_PORT` | `1044` | Remote debug port |
| `JMX_PORT` | _(disabled)_ | Enable JMX monitoring on this port |
| `DB_CONTAINER` | _(SDK-managed)_ | Connect to an existing Docker MySQL container |
| `DB_HOST` | `localhost` | Database host (when `DB_CONTAINER` is set) |
| `DB_PORT` | `3308` | Database port (when `DB_CONTAINER` is set) |
| `DB_NAME` | server ID | Database name |
| `DB_USER` | `root` | Database user |
| `DB_PASSWORD` | `root` | Database password |

**Example — run with JMX monitoring:**
```bash
JMX_PORT=9000 ./sdk.sh botsabelo-demo run
```

**Example — connect to an existing Docker MySQL container:**
```bash
DB_CONTAINER=mysql56 DB_PORT=3306 ./sdk.sh botsabelo-demo create
./sdk.sh botsabelo-demo run
```

### Seeded Environments

> **Note:** Nightly seeded image builds are not yet configured for this repository. This section will be updated when CI is set up.

Once configured, `docker.sh start` will use pre-seeded images by default for fast startup. For programmatic use, `docker/compose.seed.yaml` can be invoked directly:

```bash
SITE=botsabelo-demo \
  PIH_CONFIG=lesotho,lesotho-botsabelo-demo \
  docker compose -f docker/compose.seed.yaml --env-file docker/default.env up -d
```

## CI and Publishing

> **Note:** GitHub Actions CI is not yet configured for this repository.

When CI is configured, it will handle:
- Building and publishing the Maven artifact to Maven Central as `org.pih.openmrs:lesotho-distro`
- Building and pushing a Docker image to Docker Hub at `partnersinhealth/lesotho-emr`
- Nightly seeded image builds per site
- Automated snapshot dependency updates

# PIH Lesotho EMR Distribution

This repository defines the OpenMRS distribution for PIH Lesotho. It packages together the [PIH EMR](https://github.com/PIH/openmrs-distro-pihemr) parent distribution, 
Lesotho-specific content, and the PIH EMR frontend into a single deployable artifact. 
For more background on OpenMRS distributions, see the [OpenMRS wiki](https://wiki.openmrs.org/display/docs/OpenMRS+Distributions).

## Repository Structure

| Directory | Description                                                                                |
|---|--------------------------------------------------------------------------------------------|
| [`content/`](content/README.md) | Lesotho-specific OpenMRS content package (Initializer and O3 configuration files)          |
| [`distro/`](distro/README.md) | Distribution definition — resolves all component versions into `openmrs-distro.properties` |

## Components

| Component | Artifact |
|---|---|
| PIH EMR parent distro | `org.openmrs.distro:pihemr` |
| PIH EMR shared content | `org.pih.openmrs:pihemr-content` |
| Lesotho content | `org.pih.openmrs:lesotho-content` |
| PIH EMR frontend | `org.pih.openmrs:openmrs-frontend-pihemr` |

Component versions are defined in `distro/pom.xml` and resolved into `distro/openmrs-distro.properties` at build time.

## Supported Configuration Profiles

| Site | PIH Config |
|---|---|
| `kol-ci` | `lesotho,lesotho-kol-ci` |

## Developer Guide

Local development runs through the shared
[`openmrs-contrib-distro-tools`](https://github.com/PIH/openmrs-contrib-distro-tools) CLI
(`openmrs-docker`/`openmrs-sdk`), installed once per machine rather than embedded in this repo.
Follow that repo's [Install](https://github.com/PIH/openmrs-contrib-distro-tools#install) section first — the commands below assume `openmrs-docker`/`openmrs-sdk` are already on your `PATH`.

### Docker (`openmrs-docker`)

For each supported configuration profile, an example environment file is provided in the repo root to enable getting started quickly.
This preserves most of the default settings.  If you need to change anything, you can either create a new environment file
and store it somewhere on your own machine for later reuse or set additional environment variables directly in the shell.
Because this file is found in the distribution repository, it is assumed that this is checked out on your machine, and 
that `openmrs-docker` commands are running from the root of the distribution repository.  For this reason, it sets the `DISTRO_SOURCE_DIR` 
environment variable to this location.  If you are using this file as an example for running elsewhere, you may need to change or remove this.

To use the example environment file for `kol-ci` to get up and running with a new instance:

```bash
source kol-ci.env  # Example kol-ci.env is supplied OR you can create your own OR set environment variables explicitly
openmrs-docker create kol-ci
openmrs-docker kol-ci initialize # This step is optional, but highly recommended to speed initial startup time
openmrs-docker kol-ci start
openmrs-docker kol-ci wait  # This step will tail the logs until OpenMRS is ready and then terminate
openmrs-docker kol-ci logs  # Alternatively, this will tail the logs indefinitely
```

Once created, day-to-day commands only need the instance name:

```bash
openmrs-docker kol-ci stop
openmrs-docker kol-ci logs
openmrs-docker kol-ci destroy
```

| Command | Description |
|---|---|
| `initialize` | Pre-load a brand-new instance's data volumes from a seed image (see [Seeded Environments](#seeded-environments)) |
| `start` | Start the stack |
| `stop` | Stop the running stack |
| `restart` | Restart the running containers in place (no rebuild, no recreate) |
| `status` | Show the state of this instance's containers |
| `update` | Pull latest images and reconcile the stack (recreates only what changed) |
| `sync` | Refresh this instance's copied service fragments from the tool's current templates |
| `add-service <svc>` | Attach a canonical service fragment |
| `remove-service <svc>` | Detach a service fragment and remove its now-orphaned container |
| `wait` | Wait for OpenMRS to finish initializing |
| `build` | Build the distribution from source and create a local Docker image |
| `pull` | Pull the images this instance would use, without starting anything |
| `logs [service]` | Tail container logs; defaults to every service |
| `destroy` | Stop the stack, delete all volumes, and remove the instance directory |

| Option | Description |
|---|---|
| `--build` | Build the distribution from source before starting |
| `--dev` | Expose debug ports and mount a locally-built distro over the image |
| `--force` | Skip the confirmation prompt (`destroy` only) |

If you are a developer and want to make local changes to the distro (including content), you can use the `--build` option
to build the distro from source and use the resulting image.  To do so, you need to ensure that you either pass the `DISTRO_SOURCE_DIR`
environment variable when running the `create` command that points to your locally check out of this repository, or you 
will need to manually update it in your already created instances env file.

**Example — build from source and start:**
```bash
openmrs-docker kol-ci start --build
```

**Example — develop against a locally-built distro with debug ports exposed:**
```bash
openmrs-docker kol-ci start --dev --build
```

**Example — run on a different port:** edit `OPENMRS_HTTP_PORT` in the instance's own env file
(`~/openmrs/kol-ci/env`) rather than passing it on the command line — `openmrs-docker` sources
that file directly, so a value already set there always wins over a same-named shell override.

See [`openmrs-contrib-distro-tools`'s README](https://github.com/PIH/openmrs-contrib-distro-tools#env-file-reference)
for the full instance `env` file reference.

### OpenMRS SDK (`openmrs-sdk`)

Use `openmrs-sdk` to run a site using the [OpenMRS SDK](https://wiki.openmrs.org/display/docs/OpenMRS+SDK), which sets up a local Tomcat server with its own MySQL instance.

```
openmrs-sdk <command> <server-id>
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
PIH_CONFIG=lesotho,lesotho-kol-ci openmrs-sdk create lesotho
openmrs-sdk run lesotho
```

**Example — after updating component versions:**
```bash
openmrs-sdk update lesotho
openmrs-sdk run lesotho
```

**Example — redeploy configuration only:**
```bash
openmrs-sdk update-config lesotho
openmrs-sdk run lesotho
```

#### Environment variable overrides

| Variable | Default | Commands | Description |
|---|---|---|---|
| `SERVER_ID` | positional arg | all | SDK server directory name |
| `DISTRO_SOURCE_DIR` | current directory | all | Path to this repo's checkout |
| `PIH_CONFIG` | _(required)_ | `create` | PIH config profile passed to SDK setup — e.g. `lesotho,lesotho-kol-ci` |
| `SERVER_PORT` | `8080` | `create` | Tomcat HTTP port |
| `DEBUG_PORT` | `1044` | `create` | Remote debug port |
| `JMX_PORT` | _(disabled)_ | `run` | Enable JMX monitoring on this port |
| `DB_CONTAINER` | _(SDK-managed)_ | `create`, `destroy` | Connect to an existing Docker MySQL container |
| `DB_HOST` | `localhost` | `create` | Database host (when `DB_CONTAINER` is set) |
| `DB_PORT` | `3306` | `create` | Database port (when `DB_CONTAINER` is set) |
| `DB_NAME` | server ID | `create`, `destroy` | Database name |
| `DB_USER` | `root` | `create`, `destroy` | Database user |
| `DB_PASSWORD` | `root` | `create`, `destroy` | Database password |

**Example — run with JMX monitoring:**
```bash
JMX_PORT=9000 openmrs-sdk run lesotho
```

**Example — connect to an existing Docker MySQL container:**
```bash
DB_CONTAINER=mysql56 DB_PORT=3308 PIH_CONFIG=lesotho,lesotho-kol-ci \
openmrs-sdk create lesotho
openmrs-sdk run lesotho
```

### Seeded Environments

Run `openmrs-docker <name> initialize` once, right after `create` and before the first `start` —
it refuses to run if the instance already has data volumes, so it only ever applies to a
brand-new instance. It pre-loads the data/database volumes from `SEED_IMAGE_NAME`
(`partnersinhealth/lesotho-emr-seed-kol-ci` by default in `kol-ci.env`), cutting the first
`start` down from a full migration (~30 minutes) to a normal boot (~5 minutes). `start`/`update`
behave identically afterward whether or not `initialize` was ever run. See [CI and
Publishing](#ci-and-publishing) below for which seed images are published and how to pin a
specific version.

## Running on Windows

Follow [openmrs-contrib-distro-tools' Windows walkthrough](https://github.com/PIH/openmrs-contrib-distro-tools#running-on-windows)
for installing WSL/Docker, starting/stopping an instance, keeping the tool up to date, and
troubleshooting. The one step specific to this distro is Step 3, creating the instance:

```bash
OPENMRS_IMAGE_NAME=partnersinhealth/lesotho-emr \
OPENMRS_PIH_CONFIG=lesotho,lesotho-kol-ci \
openmrs-docker create kol-ci
```

Then continue that walkthrough from "Starting an environment" onward, using `kol-ci` as the instance name.

## CI and Publishing

CI is handled by GitHub Actions. On every push to `main`, the [Build and deploy](.github/workflows/build-and-deploy.yml) workflow:

1. Builds and publishes the Maven artifact to [Maven Central](https://central.sonatype.com/artifact/org.pih.openmrs/lesotho-distro) as `org.pih.openmrs:lesotho-distro`.
2. Builds and pushes a multi-platform Docker image (amd64 + arm64) to Docker Hub at [`partnersinhealth/lesotho-emr`](https://hub.docker.com/r/partnersinhealth/lesotho-emr), tagged with both `latest` and the Maven project version.

A separate [Build seeded images](.github/workflows/build-seeded-images.yml) workflow runs nightly and publishes pre-initialized seed images to Docker Hub:

| Image | Tags |
|---|---|
| [`partnersinhealth/lesotho-emr-seed-kol-ci`](https://hub.docker.com/r/partnersinhealth/lesotho-emr-seed-kol-ci) | `latest`, version |

Run `openmrs-docker <name> initialize` to pre-load an instance from this seed image (see
[Seeded Environments](#seeded-environments) above). To pin to a specific version, set
`SEED_IMAGE_TAG=<version>` in the instance's `env` file before running `initialize`.

A separate [Update Versions](.github/workflows/update-versions.yml) workflow runs hourly and automatically commits any available snapshot dependency updates to `main`.

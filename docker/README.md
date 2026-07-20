# Docker Setup

`lesotho-emr` is run locally via the shared
[`openmrs-contrib-distro-tools`](https://github.com/PIH/openmrs-contrib-distro-tools) CLI, installed once per
machine — see that repo's README for the full instance model and `docker.sh`/`sdk.sh` reference.

## Quick start

Clone `openmrs-contrib-distro-tools` and create a `botsabelo-demo` instance pointing at this repo.
The commands below use the full path to the clone; if you add it to `PATH` instead (as the Windows
setup script below does automatically), drop the `~/openmrs-contrib-distro-tools/` prefix and just
run `docker.sh`/`sdk.sh` directly.

```bash
git clone --branch v0.1.0 https://github.com/PIH/openmrs-contrib-distro-tools.git ~/openmrs-contrib-distro-tools

IMAGE_NAME=partnersinhealth/lesotho-emr \
  SEED_IMAGE_NAME=partnersinhealth/lesotho-emr-seed-botsabelo-demo \
  PIH_CONFIG=lesotho,lesotho-botsabelo-demo \
  DISTRO_SOURCE_DIR="$(pwd)" \
  ~/openmrs-contrib-distro-tools/docker.sh create botsabelo-demo

~/openmrs-contrib-distro-tools/docker.sh botsabelo-demo start
~/openmrs-contrib-distro-tools/docker.sh botsabelo-demo wait
```

Once created, day-to-day commands only need the instance name:

```bash
~/openmrs-contrib-distro-tools/docker.sh botsabelo-demo stop
~/openmrs-contrib-distro-tools/docker.sh botsabelo-demo logs
~/openmrs-contrib-distro-tools/docker.sh botsabelo-demo destroy
```

To develop against a locally-built distro with debug ports exposed:

```bash
~/openmrs-contrib-distro-tools/docker.sh botsabelo-demo start --dev --build
```

## Recommended instance values

| Site | `IMAGE_NAME` | `SEED_IMAGE_NAME` | `PIH_CONFIG` |
|---|---|---|---|
| `botsabelo-demo` | `partnersinhealth/lesotho-emr` | `partnersinhealth/lesotho-emr-seed-botsabelo-demo` | `lesotho,lesotho-botsabelo-demo` |

## Seeded environments

A nightly CI workflow builds and publishes pre-initialized seed images to Docker Hub for each site. A
seeded image has OpenMRS fully initialized, so startup takes ~5 minutes instead of ~30 minutes.
`docker.sh start` uses the seeded image by default; pass `--fresh` to initialize from scratch.

| Site | Image |
|---|---|
| `botsabelo-demo` | [`partnersinhealth/lesotho-emr-seed-botsabelo-demo`](https://hub.docker.com/r/partnersinhealth/lesotho-emr-seed-botsabelo-demo) |

To pin to a specific version, set `SEED_IMAGE_TAG=<version>` in the instance's `env` file.

## Running on Windows

This section walks through how to run a local OpenMRS instance on a Windows machine — no programming
experience required.

### What you need

- Windows 10 (version 2004 or later) or Windows 11
- At least 8 GB RAM (16 GB recommended — OpenMRS uses a lot of memory)
- A reliable internet connection for the initial download

### One-time setup

**Step 1 — Install Windows Subsystem for Linux**

Open PowerShell in administrator mode by right-clicking and selecting "Run as administrator" and
enter the following command:

```powershell
wsl --install
```

Reboot your computer.

**Step 2 — Download the setup script and run it**

Open the Ubuntu terminal from your start menu and paste the following command:

```bash
curl -fsSL https://raw.githubusercontent.com/PIH/openmrs-contrib-distro-tools/v0.1.0/docker/setup.sh | sudo bash
```

When the process is complete, close the Ubuntu terminal window and relaunch it from the Start Menu.
You only need to do this once — `openmrs-contrib-distro-tools` is now installed and on your `PATH`.

**Step 3 — Create the instance**

```bash
IMAGE_NAME=partnersinhealth/lesotho-emr \
  SEED_IMAGE_NAME=partnersinhealth/lesotho-emr-seed-botsabelo-demo \
  PIH_CONFIG=lesotho,lesotho-botsabelo-demo \
  docker.sh create botsabelo-demo
```

### Starting an environment

```bash
docker.sh botsabelo-demo start
```

The first time you start, Docker will download the pre-initialized image from the internet. This can
take 10–20 minutes depending on your connection. Subsequent starts will be much faster.

Once the download is complete, run the following command to be notified when OpenMRS is fully ready:

```bash
docker.sh botsabelo-demo wait
```

When you see **OpenMRS is ready**, open a browser and go to:

**http://localhost:8080/openmrs**

### Stopping

When you are done, stop the environment to free up memory. Your data is preserved and will be there
when you start again.

```bash
docker.sh botsabelo-demo stop
```

To wipe all data and start completely fresh next time:

```bash
docker.sh botsabelo-demo destroy
```

### Keeping the tool up to date

```bash
cd ~/openmrs-contrib-distro-tools && git fetch --tags && git checkout <new-version-tag>
```

### Troubleshooting

**"Permission denied when connecting to Docker" or similar error**
Close the Ubuntu terminal and reopen it from the Start Menu. The docker group change applied by the
setup script only takes effect in new sessions.

**OpenMRS runs very slowly or runs out of memory**
WSL2 limits how much memory it can use by default. Create or edit `C:\Users\<YourName>\.wslconfig`
with the following content, then restart WSL (`wsl --shutdown` in PowerShell):

```
[wsl2]
memory=8GB
```

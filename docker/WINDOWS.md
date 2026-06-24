# Running on Windows

This guide walks through how to run a local OpenMRS instance on a Windows machine using Docker. No programming experience is required.

## What you need

- Windows 10 (version 2004 or later) or Windows 11
- At least 8 GB RAM (16 GB recommended — OpenMRS uses a lot of memory)
- A reliable internet connection for the initial download

## One-time setup

**Step 1 — Install Docker Desktop**

Download and install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/). It will ask to enable WSL2 during installation — allow it. WSL2 is a lightweight Linux environment built into Windows that the scripts require.

After installation, restart your computer if prompted to do so.

**Step 2 — Configure Docker Desktop**

Start Docker Desktop. On first startup it will prompt you to create an account and sign in — you can choose to do so or skip. You don't need an account for this to work.

Wait until the whale icon in the system tray is steady (not animated), which means Docker is running.

Then open **Settings → Resources → WSL Integration**, enable the toggle next to **Ubuntu**, and click **Apply & restart**.

**Step 3 — Open an Ubuntu terminal**

Open the Start menu, search for **Ubuntu**, and open it. The first time you open it, it will spend a minute setting itself up and ask you to choose a username and password — these are just for this Linux environment and don't need to match your Windows login.

**Step 4 — Allow your account to run Docker without administrator privileges**

In the Ubuntu terminal, run:

```bash
sudo usermod -aG docker $USER
```

Then close the Ubuntu terminal and reopen it from the Start menu before continuing.

**Step 5 — Install Git and download the scripts**

In the Ubuntu terminal, paste the following commands one at a time and press Enter after each:

```bash
sudo apt-get update && sudo apt-get install -y git
```

```bash
git clone https://github.com/PIH/lesotho-emr.git
cd lesotho-emr
```

You only need to do this once. The `lesotho-emr` folder now contains everything needed to run the environment.

## Starting an environment

In the Ubuntu terminal (make sure you are inside the `lesotho-emr` folder), run:

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

## Stopping

When you are done, stop the environment to free up memory. Your data is preserved and will be there when you start again.

```bash
./docker.sh botsabelo-demo stop
```

To wipe all data and start completely fresh next time:

```bash
./docker.sh botsabelo-demo destroy
```

## Keeping the scripts up to date

Periodically run the following in the Ubuntu terminal from inside the `lesotho-emr` folder to pick up any script updates:

```bash
git pull
```

## Troubleshooting

**"Docker is not running" or similar error**
Make sure Docker Desktop is open and the whale icon in the system tray is steady before running any commands.

**OpenMRS runs very slowly or runs out of memory**
Docker Desktop limits how much memory it can use by default. Open Docker Desktop, go to **Settings → Resources → Memory**, and increase it to at least 6 GB. Click **Apply & restart**.

**"Permission denied" when running `./docker.sh`**
Run this once to make the script executable:
```bash
chmod +x docker.sh
```

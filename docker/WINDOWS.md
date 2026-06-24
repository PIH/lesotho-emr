# Running on Windows

This guide walks through how to run a local OpenMRS instance on a Windows machine — no programming experience required.

## What you need

- Windows 10 (version 2004 or later) or Windows 11
- At least 8 GB RAM (16 GB recommended — OpenMRS uses a lot of memory)
- A reliable internet connection for the initial download

## One-time setup

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

## Starting an environment

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

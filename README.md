# Ubuntu MATE 24.04 XRDP Development Desktop

The lightweight MATE edition of the Ubuntu XRDP development desktop: an Ubuntu 24.04 LTS
Docker container with a MATE desktop over RDP, developer tooling, and the upstream Hermes
AI agent in the terminal.

## Prerequisites

Docker, installed and running. Check:

```bash
docker --version
docker info >/dev/null && echo "Docker is working"
```

About 8 GB of free disk space.

## Quick start

**1. Build** (roughly 10 minutes the first time):

```bash
git clone https://github.com/jjkh1673-tech/ubuntu-mate-xrdp.git
cd ubuntu-mate-xrdp
docker build -t ubuntu-mate-xrdp .
```

**2. Start.** Replace the password. Without it you cannot log in.

```bash
docker run -d \
  --name ubuntu-mate-xrdp \
  -p 3389:3389 \
  -e XRDP_PASSWORD='choose-a-strong-password' \
  -v ubuntu-mate-home:/home/ubuntu \
  ubuntu-mate-xrdp
```

**3. Wait ~30 seconds**, then check:

```bash
docker inspect --format '{{.State.Health.Status}}' ubuntu-mate-xrdp
```

Wait until it prints `healthy`.

**4. Connect** with any RDP client to `localhost:3389` (or the host's IP). Username `ubuntu`,
password from step 2. The client will warn about a self-signed certificate; accept it.

## Using the AI agent

Open a terminal (or `docker exec -it ubuntu-mate-xrdp bash`) and run:

```bash
ai
```

`ai`, `hermes`, `hermes-ai` and `hermes-agent` all launch the same real Hermes agent.
First run: `hermes setup`.

## What is included

- Ubuntu 24.04 LTS with a MATE desktop over XRDP on TCP 3389
- Python 3 with pip, venv and dev headers; C/C++ via build-essential and cmake; gdb
- Node.js and npm; Git; ripgrep, jq, shellcheck, htop
- Network/security tools: net-tools, iproute2, dnsutils, tcpdump, nmap; ffmpeg
- Upstream Nous Research Hermes Agent

## Persistence

The `-v ubuntu-mate-home:/home/ubuntu` volume keeps shell config and Hermes credentials
across container recreation.

## Troubleshooting

**Cannot log in:** `XRDP_PASSWORD` is applied only at container start. Recreate with
`-e XRDP_PASSWORD=...` if it was missing.

**Not `healthy`:** `docker logs ubuntu-mate-xrdp`; both `xrdp` and `xrdp-sesman` must run.

**Connection refused:** check `docker ps` and `docker exec ubuntu-mate-xrdp ss -ltn`.

## Known limitations

- Self-signed TLS certificate (client warns on first connect).
- Image is around 7 GB (desktop + build toolchain).
- No GPU acceleration.

## Security notes

Do not commit API keys or bake secrets into image layers; set `XRDP_PASSWORD` at runtime;
configure Hermes via `hermes setup`.

## Verification status

See the sibling project `ubuntu-xrdp`, built the same way; this MATE edition follows the
same Dockerfile/start.sh structure with `ubuntu-mate-core` and `mate-session`.

# Ubuntu MATE 24.04 XRDP Development Desktop

The lightweight MATE edition of the Ubuntu XRDP development desktop: an Ubuntu 24.04 LTS
Docker container with a MATE desktop over RDP, developer tooling, and the upstream Hermes
AI agent in the terminal.

## Desktop preview

What a user sees after connecting over RDP, captured in a real `xfreerdp` session logged in as
`ubuntu` (1280x800, first login, nothing hand-edited afterwards):

![Ubuntu MATE XRDP desktop: the reference wallpaper, single top panel, left Plank dock with Hermes Desktop and the terminal pinned, frameless analog clock widget over the drawn clock](assets/preview.png)

The layout follows the wallpaper: the analog clock widget sits over the drawn clock so the live
one replaces it, the Plank dock on the left pins Hermes Desktop and the terminal, and only the
top panel is kept (the default bottom window-list panel and the snap Firefox launcher are
removed at build time, because snapd does not exist inside a container).

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
- Image is around 8 GB (desktop + build toolchain).
- No GPU acceleration.

## Security notes

Do not commit API keys or bake secrets into image layers; set `XRDP_PASSWORD` at runtime;
configure Hermes via `hermes setup`.

## Verification status

Verified on a GitHub Codespace (`standardLinux32gb`: 4 vCPU, 16 GB RAM, root through
passwordless sudo) with Docker 29.7.2, building `main` at b8d9a1f into an image store that
had been pruned to nothing, so no layer was inherited from an earlier build.

| Check | Result |
| --- | --- |
| `docker build` from scratch | PASS - exit 0, image 7.91 GB |
| GitHub Actions CI build | PASS - run #13 on the same commit |
| Container starts and stays up | PASS - `healthy`, restart count 0 |
| Healthcheck (`xrdp` + `xrdp-sesman`) | PASS - both processes running, TCP 3389 listening |
| Real RDP login as `ubuntu` | PASS - username and password typed into the XRDP login window through an `xfreerdp` client session; server log: `login successful for user ubuntu on display 10` |
| MATE session after login | PASS - session, window manager, panel and Plank all start; no black screen, no disconnect |
| Desktop layout | PASS - single top panel with menu and clock, left Plank dock pinning Hermes Desktop and the terminal, 110px frameless analog clock widget over the clock drawn in the wallpaper, no bottom panel, no leftover home/filesystem/trash icons |
| Root access for the RDP user | PASS - `whoami`, `sudo -i`, `id`, `nproc`, `free -g` and `apt-get -s upgrade` typed into a terminal inside the RDP session (`uid=0(root)`, 4 CPUs, 15 GB); `sudo -l` shows `(ALL) NOPASSWD: ALL`, `/etc/sudoers.d/ubuntu` is `0440` |
| Image is already patched | PASS - `apt-get update && apt-get -s upgrade` inside the container reports `0 upgraded`; base is Ubuntu 24.04.5 LTS |
| Hermes CLI | PASS - `hermes --version` -> `Hermes Agent v0.21.1 (2026.9.7)`; `ai` opens the real agent prompt (19 tools, skill list, `/help`) |
| Hermes Desktop app | PASS - `/usr/local/bin/hermes-desktop-launch` opens the app window inside the RDP session (`Web UI v0.6.7`) |
| First-run state | PASS - `hermes status` and `hermes doctor` run; no provider configured; `~/.hermes/.env` is `600` and owned by `ubuntu`, never baked into an image layer |
| Persistence (the `-v ...:/home/ubuntu` volume) | PASS - a file written in the session survived `docker rm` plus a fresh `docker run` on the same volume |
| `docker restart` | PASS - back to `healthy`, 3389 listening, RDP reconnects to the session |
| Secret scan (repo, image history, image env) | PASS - no `ghp_`, token or password values found |

Not verified: a live request to a model provider - that needs your own API key (`hermes setup`).
`hermes doctor` also reports npm advisories inside the upstream Hermes workspaces; those belong
to the upstream install, not to this image.

## Hermes Desktop (GUI)

Bundles the Electron **Hermes Desktop** app (fork: `jjkh1673-tech/hermes-desktop`, upstream
`sir1st/hermes-desktop`): pinned in the Plank dock, listed in the Applications menu, and the
black-and-white Hermes artwork as its application icon. The CLI agent stays available as
`hermes` / `ai`. There is deliberately no copy of the launcher on the desktop itself - the dock is
where the reference layout puts it, and a desktop icon would end up under the clock widget.
Both editions share the dock and clock-widget styling; the wallpaper and the clock geometry are
what differ - this MATE edition uses the blue reference art with the widget over the drawn clock,
the XFCE edition (ubuntu-xrdp) keeps the classic dark Ubuntu wallpaper, a desktop launcher and the
widget further to the right.

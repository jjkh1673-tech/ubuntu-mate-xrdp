#!/bin/bash
# Starts the desktop services for the XRDP container. Kept deliberately simple: dbus, audio,
# then xrdp, and the log tail so `docker logs` shows what a connecting user is doing.
set -euo pipefail

echo "=== Ubuntu MATE XRDP container starting ==="

# The image already sets the ubuntu account to the documented default password (1122).
# Setting XRDP_PASSWORD at run time replaces it, which is what you want on a shared machine.
if [[ -n "${XRDP_PASSWORD:-}" ]]; then
    printf 'ubuntu:%s\n' "$XRDP_PASSWORD" | chpasswd
    echo "RDP password for 'ubuntu' was replaced from the XRDP_PASSWORD environment variable."
else
    echo "RDP password for 'ubuntu' is the image default (1122). Change it inside the session:"
    echo "    passwd    - or start the container with  -e XRDP_PASSWORD='<new password>'."
fi

# Ubuntu 26.04's base image ships /home/ubuntu as 750, and a volume created from it inherits that.
# xrdp's connection worker runs as the `xrdp` user and must read /home/ubuntu/.Xauthority to attach
# the client to the session, so traversal is opened every start (existing volumes included).
chmod 755 /home/ubuntu

service dbus start

# Audio redirection is optional and must never block the desktop, so it is daemonized and allowed
# to fail (26.04 uses PipeWire by default; PulseAudio is what xrdp's module talks to).
pulseaudio --system --disallow-exit --disable-shm --daemonize=yes >/var/log/pulseaudio.log 2>&1 || true

# A container restart keeps the old pid files while the processes are gone, so they are cleared
# before starting.
mkdir -p /var/run/xrdp/sockdir
rm -f /var/run/xrdp/xrdp.pid /var/run/xrdp/xrdp-sesman.pid

# xrdp 0.10 gives every logged-in user a runtime directory (/run/xrdp/sockdir/<uid>) holding the
# session's X authority and API socket, and creates it as that user with mode 2770. Ubuntu's sysvinit
# script starts the daemons as the unprivileged `xrdp` user, which then cannot enter it: the login is
# accepted, the desktop starts, and the client is dropped with "Error connecting to user session".
# So the two daemons are started here as root, which is also what the upstream systemd units do.
# Sessions themselves still run as the logged-in user, because sesman drops privileges on its own.
if [ -x /usr/sbin/xrdp ] && [ -x /usr/sbin/xrdp-sesman ]; then
    /usr/sbin/xrdp-sesman
    /usr/sbin/xrdp
else
    service xrdp start
fi

mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

printf '\nUbuntu 26.04 MATE XRDP desktop is ready.\n'
printf '  RDP port      : 3389 (published as -p 3389:3389)\n'
printf '  RDP user      : ubuntu\n'
printf '  Root access   : sudo -i   (passwordless for the ubuntu user)\n'
printf '  Hermes        : ai   or   hermes   (hermes setup for a model provider)\n'
printf '  System Upgrade: ubuntu-migrate --check   (also an icon in the dock)\n\n'

tail -F /var/log/xrdp.log /var/log/xrdp-sesman.log

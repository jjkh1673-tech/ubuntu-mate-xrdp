#!/bin/bash
set -euo pipefail

echo "=== Ubuntu XRDP container starting ==="

# Set the RDP user's password only at runtime; never bake credentials into the image.
if [[ -n "${XRDP_PASSWORD:-}" ]]; then
    printf 'ubuntu:%s\n' "$XRDP_PASSWORD" | chpasswd
else
    echo "WARNING: XRDP_PASSWORD is not set; the ubuntu account cannot be used for password login."
fi

service dbus start

# PulseAudio is optional and must not block startup, so it is daemonized.
pulseaudio --system --disallow-exit --disable-shm --daemonize=yes >/var/log/pulseaudio.log 2>&1 || true

# A container restart keeps the old pid files while the processes are gone,
# which makes the xrdp init script refuse to start.
rm -f /var/run/xrdp/xrdp.pid /var/run/xrdp/xrdp-sesman.pid

service xrdp start

mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

printf '\nUbuntu XRDP is ready.\n'
printf 'RDP endpoint: <host>:3389\n'
printf 'RDP user: ubuntu\n'
printf 'Hermes commands: hermes, hermes-ai, hermes-agent\n'
printf 'Set XRDP_PASSWORD at container runtime for RDP login.\n\n'

tail -F /var/log/xrdp.log /var/log/xrdp-sesman.log

# Ubuntu MATE XRDP desktop: Ubuntu 26.04 LTS + MATE + RDP + the Hermes Agent, in one image.
#
# The light edition of ubuntu-xrdp: same process, same tooling, same layout ideas - MATE instead
# of XFCE, and the wallpaper the reference asks for.

FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
LABEL org.opencontainers.image.title="ubuntu-mate-xrdp" \
      org.opencontainers.image.description="Ubuntu 26.04 LTS desktop (MATE) over RDP with the Hermes Agent" \
      org.opencontainers.image.licenses="MIT"

# One layer: refresh index, take every pending update, then install the desktop, the everyday
# applications and the development toolchain. Doing the upgrade in the same layer is what makes
# `apt-get upgrade` inside the container report "0 upgraded" right after a fresh start.
RUN apt-get update && \
    apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    xrdp \
    xorgxrdp \
    xorg \
    xserver-xorg-legacy \
    ubuntu-mate-core \
    mate-themes \
    mate-menu \
    mate-terminal \
    mate-utils \
    caja \
    pluma \
    eom \
    engrampa \
    mate-system-monitor \
    dbus \
    dbus-x11 \
    dconf-cli \
    zenity \
    libnotify-bin \
    xdg-utils \
    pulseaudio \
    pulseaudio-utils \
    ubuntu-release-upgrader-core \
    update-manager-core \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-tk \
    build-essential \
    cmake \
    gdb \
    nodejs \
    npm \
    ripgrep \
    ffmpeg \
    git \
    curl \
    wget \
    sudo \
    nano \
    vim \
    less \
    net-tools \
    iproute2 \
    dnsutils \
    tcpdump \
    nmap \
    procps \
    openssh-client \
    unzip \
    zip \
    jq \
    htop \
    shellcheck \
    mate-calc \
    papirus-icon-theme \
    yaru-theme-gtk \
    plank \
    && rm -rf /var/lib/apt/lists/*

# ubuntu:26.04 ships an `ubuntu` user (uid 1000, /bin/bash, sudo group); nothing is created here.
# The xrdp daemon runs as the `xrdp` user and must read the TLS private key, which requires
# membership in the ssl-cert group.
# The account password is 1122 by design - see the README's first-login section for changing it.
RUN usermod -aG ssl-cert xrdp && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu && \
    echo 'ubuntu:1122' | chpasswd && \
    chmod 755 /home/ubuntu

# The xrdp connection worker runs as its own user and has to read the session cookie in
# /home/ubuntu/.Xauthority to attach the RDP client to the display sesman just started. The Ubuntu
# 26.04 base image keeps a home directory closed to everyone but its owner, so the login itself
# succeeds, the desktop comes up, and the client is then dropped with "Error connecting to user
# session" - which is exactly what a build of this image did before this line existed. Only
# traversal is opened; the files inside keep their own permissions.

# Start MATE for the RDP session and let anybody open a session.
RUN printf 'mate-session\n' > /home/ubuntu/.xsession && \
    chown ubuntu:ubuntu /home/ubuntu/.xsession && \
    chmod 700 /home/ubuntu/.xsession && \
    printf 'exec mate-session\n' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh && \
    sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config

# Ubuntu 26.04 ships rootless X, which needs a login session with a VT - something a container does
# not have. xserver-xorg-legacy puts the setuid wrapper back and allowed_users above lets any user
# start the Xorg that xrdp runs per session; without these two lines the session dies at "X server
# problem" and the RDP login never reaches a desktop.
RUN grep -q allowed_users=anybody /etc/X11/Xwrapper.config

# The real upstream Hermes Agent - installed exactly the way its own documentation says, for the
# ubuntu user, so its home, memory and skills live in the mounted volume and no key is baked in.
# The installer clones the upstream repo anonymously and GitHub throttles bursts of anonymous
# fetches (HTTP 429), so the whole install is retried with a backoff and fails the build loudly if
# every attempt fails.
RUN ok=0; \
    for attempt in 1 2 3 4 5; do \
      if su - ubuntu -c 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash'; then ok=1; break; fi; \
      echo "Hermes install attempt $attempt failed (GitHub may be rate-limiting this network); retrying in 60s"; \
      sleep 60; \
    done; \
    [ "$ok" = 1 ] || { echo "Hermes Agent install failed after 5 attempts"; exit 1; }; \
    HERMES_BIN="$(find /home/ubuntu/.local/bin /home/ubuntu/.hermes/bin -type f -name hermes -perm -111 -print -quit 2>/dev/null)" && \
    test -n "$HERMES_BIN" && \
    ln -sf "$HERMES_BIN" /usr/local/bin/hermes && \
    ln -sf "$HERMES_BIN" /usr/local/bin/hermes-ai && \
    ln -sf "$HERMES_BIN" /usr/local/bin/hermes-agent && \
    ln -sf "$HERMES_BIN" /usr/local/bin/ai && \
    printf 'export PATH="/home/ubuntu/.local/bin:$PATH"\n' > /etc/profile.d/hermes.sh

# Hermes Desktop: the same upstream project's own GUI, built by `hermes desktop --build-only`.
# No third-party .deb is installed. If the build cannot run (no network on a custom builder) the
# image is still fine - the launcher then compiles it on first start. The caches are deleted in the
# same layer, because the electron download and the npm cache are ~1 GB of data nothing needs after
# the packaged app exists.
RUN su - ubuntu -c 'export PATH="/home/ubuntu/.local/bin:$PATH"; cd ~ && timeout 1800 hermes desktop --build-only' \
      || echo 'WARNING: Hermes Desktop pre-build did not finish; it will be built on first launch.'; \
    rm -rf /home/ubuntu/.cache/electron /home/ubuntu/.cache/electron-builder \
           /home/ubuntu/.npm /home/ubuntu/.hermes/hermes-agent/node_modules/.cache \
           /var/lib/apt/lists/* /tmp/*

# MATE ships a panel layout that does not fit this desktop: the Brisk menu is replaced by the
# stock menu bar (the Mint-style mate-menu applet races at first login and its button stays
# empty), the top bar gets the stock clock applet, and the bottom window-list panel plus the snap
# Firefox launcher are removed - snapd cannot exist inside a container.
RUN sed -i 's/BriskMenuFactory::BriskMenu/MateMenuAppletFactory::MateMenuApplet/g' /usr/share/mate-panel/layouts/*.layout
RUN printf '%s\n' '' '[Object clock]' 'object-type=applet' 'applet-iid=ClockAppletFactory::ClockApplet' 'toplevel-id=top' 'position=10' 'relative-to-edge=end' 'locked=true' >> /usr/share/mate-panel/layouts/familiar.layout

RUN python3 - <<'EOF'
p = '/usr/share/mate-panel/layouts/familiar.layout'
lines = open(p, encoding='utf-8').read().split('\n')
assert '[Object briskmenu]' in lines, 'briskmenu block not found in familiar.layout'
i = lines.index('[Object briskmenu]')
j = next((k for k in range(i + 1, len(lines)) if lines[k] == ''), len(lines) - 1)
lines[i:j + 1] = ['[Object menu-bar]', 'object-type=menu-bar', 'toplevel-id=top',
                  'position=0', 'locked=true', '']
open(p, 'w', encoding='utf-8').write('\n'.join(lines))
print('briskmenu replaced with stock menu-bar')
EOF
RUN python3 - <<'EOF'
import re
p = '/usr/share/mate-panel/layouts/familiar.layout'
lines = open(p, encoding='utf-8').read().split('\n')
out, i, removed = [], 0, []
while i < len(lines):
    line = lines[i]
    if line.strip() == '[Toplevel bottom]':
        removed.append('Toplevel bottom')
        i += 1
        while i < len(lines) and lines[i].strip() and not lines[i].startswith('['):
            i += 1
        continue
    m = re.match(r'^\[Object ([^\]]+)\]\s*$', line)
    if m:
        j = i + 1
        while j < len(lines) and lines[j].strip():
            j += 1
        block = lines[i:j]
        if any(b.strip() == 'toplevel-id=bottom' for b in block) or m.group(1) == 'firefox':
            removed.append('Object ' + m.group(1))
            i = j
            continue
    out.append(line)
    i += 1
open(p, 'w', encoding='utf-8').write('\n'.join(out))
print('removed from familiar.layout:', ', '.join(removed) or 'nothing')
EOF

# Desktop look: theme, wallpaper, icons, and the terminal colours that mate-terminal and
# xfce4-terminal read from the dconf system database.
COPY assets/wallpaper.jpg /usr/share/backgrounds/wallpaper.jpg
COPY assets/hermes-ai.png /usr/share/icons/hicolor/256x256/apps/hermes-ai.png
COPY assets/apply-theme.sh /usr/local/bin/apply-theme.sh
COPY assets/apply-theme.desktop /etc/xdg/autostart/apply-theme.desktop
COPY assets/plank.desktop /etc/xdg/autostart/plank.desktop
COPY assets/dconf-local /etc/dconf/db/local.d/60-hermes-terminal
COPY assets/dconf-profile /etc/dconf/profile/user
RUN chmod +x /usr/local/bin/apply-theme.sh && \
    dconf update && \
    (gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true)

# The desktop apps and launchers: Hermes Desktop, System Upgrade, and the dock items.
COPY assets/hermes-desktop-launch /usr/local/bin/hermes-desktop-launch
COPY assets/ubuntu-migrate /usr/local/bin/ubuntu-migrate
COPY assets/first-run-notice /usr/local/bin/first-run-notice
COPY assets/ubuntu-migrate.desktop /usr/share/applications/ubuntu-migrate.desktop
COPY assets/ubuntu-migrate-notice.desktop /etc/xdg/autostart/ubuntu-migrate-notice.desktop
COPY assets/first-run-notice.desktop /etc/xdg/autostart/first-run-notice.desktop
RUN chmod +x /usr/local/bin/hermes-desktop-launch /usr/local/bin/ubuntu-migrate /usr/local/bin/first-run-notice && \
    printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Hermes Desktop' \
    'Comment=Hermes Agent desktop app (from hermes-agent.nousresearch.com)' \
    'Exec=/usr/local/bin/hermes-desktop-launch' \
    'Icon=/usr/share/icons/hicolor/256x256/apps/hermes-ai.png' \
    'Terminal=false' \
    'Type=Application' \
    'Categories=Development;Utility;' \
    > /usr/share/applications/hermes-ai.desktop

COPY assets/hermes.dockitem /home/ubuntu/.config/plank/dock1/launchers/hermes.dockitem
COPY assets/mate-terminal.dockitem /home/ubuntu/.config/plank/dock1/launchers/mate-terminal.dockitem
COPY assets/caja.dockitem /home/ubuntu/.config/plank/dock1/launchers/caja.dockitem
COPY assets/ubuntu-migrate.dockitem /home/ubuntu/.config/plank/dock1/launchers/ubuntu-migrate.dockitem

# The Hermes launcher also sits on the desktop, and the shell look is one sourced file so nothing
# of the distro ~/.bashrc is rewritten.
COPY assets/bash-prompt.sh /etc/skel/.hermes-shell.sh
COPY assets/bash-prompt.sh /home/ubuntu/.hermes-shell.sh
RUN mkdir -p /home/ubuntu/Desktop && \
    cp /usr/share/applications/hermes-ai.desktop /home/ubuntu/Desktop/ && \
    chmod +x /home/ubuntu/Desktop/hermes-ai.desktop && \
    chown -R ubuntu:ubuntu /home/ubuntu/.config /home/ubuntu/Desktop && \
    chown ubuntu:ubuntu /home/ubuntu/.hermes-shell.sh && \
    for f in /home/ubuntu/.bashrc /etc/skel/.bashrc; do \
      grep -q hermes-shell.sh "$f" || printf '\n[ -f ~/.hermes-shell.sh ] && . ~/.hermes-shell.sh\n' >> "$f"; \
    done && \
    chown ubuntu:ubuntu /home/ubuntu/.bashrc

# The image reference the System Upgrade tool prints in its migration plan.
RUN printf '%s\n' 'ghcr.io/jjkh1673-tech/ubuntu-mate-xrdp:latest' > /etc/ubuntu-image-ref

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

# xrdp is useless without its session manager, so both must be alive.
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD pgrep -x xrdp >/dev/null && pgrep -x xrdp-sesman >/dev/null || exit 1

CMD ["/start.sh"]

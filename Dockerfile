FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    sudo \
    xrdp \
    xorgxrdp \
    ubuntu-mate-core \
    mate-themes \
    mate-menu \
    xorg \
    dbus-x11 \
    dbus \
    pulseaudio \
    pulseaudio-utils \
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
    papirus-icon-theme \
    yaru-theme-gtk \
    && rm -rf /var/lib/apt/lists/*

# ubuntu:24.04 already ships an `ubuntu` user (uid 1000, /bin/bash, sudo group).
# The xrdp daemon runs as the `xrdp` user and must read the TLS private key,
# which requires membership in the ssl-cert group.
RUN usermod -aG ssl-cert xrdp && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

# Configure XFCE for XRDP and allow Xorg sessions.
RUN printf 'mate-session\n' > /home/ubuntu/.xsession && \
    chown ubuntu:ubuntu /home/ubuntu/.xsession && \
    chmod 700 /home/ubuntu/.xsession && \
    printf 'exec mate-session\n' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh && \
    sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || true

# Install the real upstream Hermes Agent. No custom wrapper and no API key is baked into the image.
RUN su - ubuntu -c 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash' && \
    HERMES_BIN="$(find /home/ubuntu/.local/bin /home/ubuntu/.hermes/bin -type f -name hermes -perm -111 -print -quit 2>/dev/null)" && \
    test -n "$HERMES_BIN" && \
    ln -sf "$HERMES_BIN" /usr/local/bin/hermes && \
    ln -sf "$HERMES_BIN" /usr/local/bin/hermes-ai && \
    ln -sf "$HERMES_BIN" /usr/local/bin/hermes-agent && \
    ln -sf "$HERMES_BIN" /usr/local/bin/ai && \
    printf 'export PATH="/home/ubuntu/.local/bin:$PATH"\n' > /etc/profile.d/hermes.sh

# Modern theme, wallpaper and icons.
RUN sed -i 's/BriskMenuFactory::BriskMenu/MateMenuAppletFactory::MateMenuApplet/g' /usr/share/mate-panel/layouts/*.layout
COPY assets/wallpaper.png /usr/share/backgrounds/wallpaper.png
COPY assets/hermes-ai.png /usr/share/icons/hicolor/256x256/apps/hermes-ai.png
COPY assets/apply-theme.sh /usr/local/bin/apply-theme.sh
COPY assets/apply-theme.desktop /etc/xdg/autostart/apply-theme.desktop
RUN chmod +x /usr/local/bin/apply-theme.sh && \
    (gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true)

RUN mkdir -p /usr/share/applications && \
    printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Hermes AI' \
    'Comment=Upstream Hermes Agent terminal' \
    'Exec=mate-terminal -e hermes' \
    'Icon=/usr/share/icons/hicolor/256x256/apps/hermes-ai.png' \
    'Terminal=false' \
    'Type=Application' \
    'Categories=Development;Utility;' \
    > /usr/share/applications/hermes-ai.desktop

RUN mkdir -p /home/ubuntu/Desktop && \
    cp /usr/share/applications/hermes-ai.desktop /home/ubuntu/Desktop/ && \
    chmod +x /home/ubuntu/Desktop/hermes-ai.desktop && \
    chown -R ubuntu:ubuntu /home/ubuntu/Desktop

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD pgrep -x xrdp >/dev/null && pgrep -x xrdp-sesman >/dev/null || exit 1

CMD ["/start.sh"]

#!/bin/bash
# Applies a modern MATE theme + wallpaper once the session is up.
sleep 4
gsettings set org.mate.interface gtk-theme "BlackMATE" 2>/dev/null
gsettings set org.mate.interface icon-theme "Papirus-Dark" 2>/dev/null
gsettings set org.mate.background picture-filename /usr/share/backgrounds/wallpaper.jpg 2>/dev/null
gsettings set org.mate.background picture-options "zoom" 2>/dev/null
# Reference-desktop style: dock on the left (plank reads gsettings/dconf).
gsettings set "net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/" position left 2>/dev/null
gsettings set org.mate.caja.desktop home-icon-visible false 2>/dev/null
gsettings set org.mate.caja.desktop trash-icon-visible false 2>/dev/null
gsettings set org.mate.background show-desktop-background true 2>/dev/null
gsettings set "net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/" icon-size 40 2>/dev/null
exit 0

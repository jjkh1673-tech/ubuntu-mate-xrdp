#!/bin/bash
# Applies a modern MATE theme + wallpaper once the session is up.
sleep 4
gsettings set org.mate.interface gtk-theme "BlackMATE" 2>/dev/null
gsettings set org.mate.interface icon-theme "Papirus-Dark" 2>/dev/null
gsettings set org.mate.background picture-filename /usr/share/backgrounds/wallpaper.png 2>/dev/null
gsettings set org.mate.background picture-options "zoom" 2>/dev/null
exit 0

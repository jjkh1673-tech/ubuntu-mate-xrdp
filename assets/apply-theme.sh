#!/bin/bash
# Applies a modern MATE theme + wallpaper once the session is up.
sleep 4
gsettings set org.mate.interface gtk-theme "BlackMATE" 2>/dev/null
gsettings set org.mate.interface icon-theme "Papirus-Dark" 2>/dev/null
gsettings set org.mate.background picture-filename /usr/share/backgrounds/wallpaper.png 2>/dev/null
gsettings set org.mate.background picture-options "zoom" 2>/dev/null
# Reference-desktop style: dock on the left (plank reads gsettings/dconf).
gsettings set "net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/" position left 2>/dev/null
gsettings set org.mate.caja.desktop home-icon-visible false 2>/dev/null
# --- DESKTOP CLOCK WIDGET ---------------------------------------------
# Analog clock on the wallpaper (reference look), frameless and out of the
# taskbar: Motif hints drop the title bar, the state atoms keep it sticky,
# below normal windows and absent from the pager/taskbar.
pkill -x xclock 2>/dev/null
( xclock -analog -update 1 -norepeat -background white -foreground black \
    -hd black -hl black -bd white -geometry 160x160+170+75 & )
for i in $(seq 1 30); do
  WID=$(xdotool search --class xclock 2>/dev/null | head -1)
  [ -n "$WID" ] && break
  sleep 0.5
done
if [ -n "$WID" ]; then
  xprop -id "$WID" -f _MOTIF_WM_HINTS 32c -set _MOTIF_WM_HINTS "0x2, 0x0, 0x0, 0x0, 0x0" 2>/dev/null
  xprop -id "$WID" -f _NET_WM_STATE 32a -set _NET_WM_STATE \
    _NET_WM_STATE_SKIP_TASKBAR,_NET_WM_STATE_SKIP_PAGER,_NET_WM_STATE_STICKY,_NET_WM_STATE_BELOW 2>/dev/null
fi

exit 0

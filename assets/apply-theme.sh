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
# --- DESKTOP CLOCK WIDGET -------------------------------------------------------
# Analog clock on the wallpaper (reference layout). xclock cannot ask for an
# unframed window, so once it appears the widget hints are rewritten: Motif hints
# (honoured by marco) plus the DOCK window type, which xfwm4 only re-reads after a
# remap. The result is a frameless clock that is absent from the panel's window list
# and from plank, and that stays below application windows. The position matches the
# clock drawn in the wallpaper, so the live clock replaces it instead of doubling up.
pkill -x xclock 2>/dev/null
( setsid xclock -analog -padding 1 -update 1 -background white -foreground black \
    -hd black -hl black -bd white -geometry 130x130+0+30 >/dev/null 2>&1 & )
for i in $(seq 1 20); do
  WID=$(xdotool search --name xclock 2>/dev/null | head -1)
  [ -n "$WID" ] && break
  sleep 0.5
done
if [ -n "$WID" ]; then
  xprop -id "$WID" -f _MOTIF_WM_HINTS 32c -set _MOTIF_WM_HINTS "0x2, 0x0, 0x0, 0x0, 0x0" 2>/dev/null
  xprop -id "$WID" -f _NET_WM_STATE 32a -set _NET_WM_STATE \
    _NET_WM_STATE_SKIP_TASKBAR,_NET_WM_STATE_SKIP_PAGER,_NET_WM_STATE_STICKY 2>/dev/null
  xprop -id "$WID" -f _NET_WM_WINDOW_TYPE 32a -set _NET_WM_WINDOW_TYPE _NET_WM_WINDOW_TYPE_DOCK 2>/dev/null
  xdotool windowunmap "$WID" 2>/dev/null; sleep 1
  xdotool windowmap "$WID" 2>/dev/null
  xdotool windowmove "$WID" 0 30 2>/dev/null
fi
gsettings set "net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/" icon-size 40 2>/dev/null
exit 0

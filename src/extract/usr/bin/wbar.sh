#!/bin/sh
cd "$HOME"
if [ "$ICONS" == "wbar" ]; then
   WBARPID=$(pidof wbar)
   [ -n "$WBARPID" ] && killall wbar
   [ -e .wbar ] && read OPTIONS < .wbar
   wbar  $OPTIONS  -config /usr/local/tce.icons  >/dev/null &
fi

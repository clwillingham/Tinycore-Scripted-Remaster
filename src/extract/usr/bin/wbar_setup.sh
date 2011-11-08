#!/bin/sh
2>/dev/null read TCEDIR < /opt/.tce_dir || exit 1
TCEWBAR="/usr/local/tce.icons"

[ -e "$TCEWBAR" ] && sudo rm -rf "$TCEWBAR"
sudo cp /usr/share/wbar/dot.wbar "$TCEWBAR"
sudo chown root.staff "$TCEWBAR"
sudo chmod g+w "$TCEWBAR"

XWBAR=${TCEDIR}/xwbar.lst
[ ! -e "$XWBAR" ] && touch "$XWBAR"

SYSWBAR=/usr/share/wbar/dot.wbar
if [ -s "$XWBAR" ]; then
  for F in `awk '/t: /{print $2}' < ${SYSWBAR}` ; do
    if grep -qw "$F" ${XWBAR}; then
      wbar_rm_icon "$F"
    fi
  done
fi

INSTALLED=/usr/local/tce.installed
ONDEMAND="$TCEDIR"/ondemand
for F in `ls -1 "$ONDEMAND"/*.img 2>/dev/null`; do
  IMG="${F##/*/}"
  APPNAME="${IMG%.img}"
  if [ ! -e "$INSTALLED"/"$APPNAME" ]; then
    if ! grep -qw "^t: *${APPNAME}$" "${TCEDIR}"/xwbar.lst 2>/dev/null; then
      echo "i: $ONDEMAND/$IMG" >> "$TCEWBAR"
      echo "t: $APPNAME" >> "$TCEWBAR"
      echo "c: $ONDEMAND/$APPNAME" >> "$TCEWBAR"
    fi
  fi
done

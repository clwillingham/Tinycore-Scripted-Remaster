#!/bin/sh
. /etc/init.d/tc-functions
xvesa_select()
{
   Xvesa -listmodes 2>&1 | grep ^0x | awk '{ printf "%s\n",$2 }' | sort -n | grep x[1-2][4-6] > "$TMP"
   echo "${GREEN}"
   select "Tiny Core Linux - Xvesa Resolution Setup" "$TMP"
   echo "${NORMAL}"
   ANS="$(cat /tmp/select.ans)"
   rm "$TMP"
   [ "$ANS" == "q" ] && exit_script
   XRES="-screen $ANS"
}

mouse_select()
{
   echo "USB & IMPS/2 Wheel" > "$TMP"
   echo "USB 2 Button" >> "$TMP"
   echo "Legacy IMPS/2 Wheel"  >> "$TMP"
   echo "PS2 2 Button"  >> "$TMP"
   echo "PS2 3 Button"  >> "$TMP"
   echo "COM1 2 Button"  >> "$TMP"
   echo "COM1 3 Button"  >> "$TMP"
   echo "COM2 2 Button"  >> "$TMP"
   echo "COM2 3 Button"  >> "$TMP"
   echo "COM3 2 Button"  >> "$TMP"
   echo "COM3 3 Button"  >> "$TMP"
   echo "COM4 2 Button"  >> "$TMP"
   echo "COM4 3 Button"  >> "$TMP"
   echo "${GREEN}"
   select "Tny Core Linux - Mouse Setup" "$TMP" 0
   echo "${NORMAL}"
   ANS="$(cat /tmp/select.ans)"
   rm "$TMP"
   [ "$ANS" == "q" ] && exit_script
   XMOUSE="$ANS"
}

mouse_clause() {
case $XMOUSE in
  13) XMOUSE="-mouse /dev/ttyS3" ;;
  12) XMOUSE="-2button -mouse /dev/ttyS3" ;;
  11) XMOUSE="-mouse /dev/ttyS2" ;;
  10) XMOUSE="-2button -mouse /dev/ttyS2" ;;
  9) XMOUSE="-mouse /dev/ttyS1" ;;
  8) XMOUSE="-2button -mouse /dev/ttyS1" ;;
  7) XMOUSE="-mouse /dev/ttyS0" ;;
  6) XMOUSE="-2button -mouse /dev/ttyS0" ;;
  5) XMOUSE="-mouse /dev/psaux" ;;
  4) XMOUSE="-2button -mouse /dev/psaux" ;;
  3) XMOUSE="-mouse /dev/psaux,5" ;;
  2) XMOUSE="-2button -mouse /dev/input/mice" ;;
  1) XMOUSE="-mouse /dev/input/mice,5" ;;
  *) XMOUSE="-mouse /dev/input/mice,5"
esac
}

exit_script()
{
   rm /tmp/select.ans 2>/dev/null
   sudo rm /tmp/xsetup_requested 2>/dev/null
   exit 0
}

TMP=/tmp/xsetup.$$.tmp
XSERVER=$(which Xorg || which Xfbdev || which Xvesa)
TYPE=$(basename "$XSERVER")
case $TYPE in
  Xvesa )
    xvesa_select
    mouse_select
    mouse_clause
    XCOMMAND="$XSERVER -br $XRES -shadow $XMOUSE -nolisten tcp -I >/dev/null 2>&1 &"
    ;;
  Xfbdev )
    if [ "$1" == "booting" ]; then
	XCOMMAND="$XSERVER -mouse /dev/input/mice,5 -nolisten tcp -I >/dev/null 2>&1 &"
    else
	mouse_select
	mouse_clause
	XCOMMAND="$XSERVER $XMOUSE -nolisten tcp -I >/dev/null 2>&1 &"
    fi
    ;;
  Xorg )
    XCOMMAND="$XSERVER -nolisten tcp &"
    ;;
  * )
    XCOMMAND=""
esac

echo "$XCOMMAND" > /tmp/.xsession
TARGET="$HOME"
[ -f "$TARGET"/.xsession ] || TARGET=/etc/skel
# Skips Xserver line and retains the rest of the .xsession file.
awk -v outfile="/tmp/.xsession" '
{
  if ( index($1, "Xvesa" ) == 0 && index($1, "Xfbdev") == 0 && index($1, "Xorg") == 0 )
  {
     print $0 >> outfile
  }
} ' "$TARGET"/.xsession
[ "$?" == 0 ] && mv /tmp/.xsession "$HOME"/.xsession
sudo chown ${USER}.staff "$HOME"/.xsession
chmod 700 "$HOME"/.xsession
exit_script

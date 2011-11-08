#!/bin/sh
# (c) Robert Shingledecker 2010
# Called from desktop.sh to update wbar icons.

writeWBARitem() {
busybox awk -v output="$TMP" -v target="$TARGET" -v wbaricons="$TCEWBAR" '
BEGIN {
  FS = "="
}
function rtrim(s) { sub(/[ \t]+$/, "", s); return s }
{
  if ( $1 == "Name") {
    name = rtrim($2)
    gsub(/ /, "", name)
  } else if ( $1 == "Exec" ) {
    exec = $2
    test = match(exec,"%")
    if ( test ) exec = substr(exec,0,test-1)
  } else if ( $1 == "X-FullPathIcon" ) {
    icon = $2
  } else if ( $1 == "Terminal" ) {
    terminal = $2
  }
}
END {
  found = 0
  while (( getline item < wbaricons ) > 0 )
  {
    if ( index(item, target) > 0 )
    {
      found = 1
      print "i: " icon >> output
      print "t: " name > output
      if ( terminal == "true" ) {
	print "c: exec aterm +tr +sb -T \""name"\" -e " exec > output
      } else {
	print "c: exec " exec > output
      }
      getline item < wbaricons
      getline item < wbaricons
    } else {
      print item > output
    }
  }
  if ( found == 0 )
  {
  print "i: " icon >> output
  print "t: " name > output
  if ( terminal == "true" ) {
     print "c: exec aterm +tr +sb -T \""name"\" -e " exec > output
  } else {
    print "c: exec " exec > output
  }

  }
  close(wbaricons)
} ' "$1"
sudo mv "$TMP" "$TCEWBAR"
sudo chmod g+w "$TCEWBAR"
}

TCEWBAR="/usr/local/tce.icons"
TCEDIR="$(cat /opt/.tce_dir)"
APPNAME="$1"
#OnDemand xwbar check
if grep -qw "^t: *${APPNAME}$" "${TCEDIR}"/xwbar.lst 2>/dev/null; then exit 0; fi
TMP=/tmp/wbar.$$

#
FREEDESK=/usr/local/share/applications/"$APPNAME".desktop
if [ -e "$FREEDESK" ]; then
   ICONCHECK="$(awk 'BEGIN{FS = "="}$1=="X-FullPathIcon"{print $2}' "$FREEDESK")"
   NAMECHECK="$(awk 'BEGIN{FS = "="}$1=="Name"{print $2}' "$FREEDESK")"
   if grep -qw "^t: *${NAMECHECK// /}$" "${TCEDIR}"/xwbar.lst 2>/dev/null; then exit 0; fi
   TARGET="$APPNAME".img
   [ -f "$ICONCHECK" ] && writeWBARitem "$FREEDESK" && [ -G /tmp/.X11-unix/X0 ] && wbar.sh
fi

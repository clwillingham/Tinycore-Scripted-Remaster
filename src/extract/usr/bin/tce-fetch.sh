#!/bin/sh
#(c) Robert Shingledecker 2004-2008
#
. /etc/init.d/tc-functions

getMirror
[ -f "$1" ] && rm -f "$1"
busybox wget -cq "$MIRROR"/"$1"

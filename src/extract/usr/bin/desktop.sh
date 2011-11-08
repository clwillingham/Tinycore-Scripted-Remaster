#!/bin/sh
#(c) Robert Shingledecker 2004-2010
#
. /etc/init.d/tc-functions
#
[ "$USER" ] || USER="$(cat /etc/sysconfig/tcuser)" || USER="tc"
if [ "$HOME" == "/root" ]; then HOME=/home/"$USER"; fi
# The following two cannot use EXPORTS as also called during boot via tc-setup
DESKTOP=`cat /etc/sysconfig/desktop`
ICONS=`cat /etc/sysconfig/icons 2>/dev/null`
APPNAME="$1"
#
[ $(which "$DESKTOP"_makemenu) ] && "$DESKTOP"_makemenu "$APPNAME" 2>/dev/null
[ $(which "$ICONS"_update.sh ) ] && "$ICONS"_update.sh  "$APPNAME" 2>/dev/null

#!/bin/sh
# Check for optional local shutdown before actual shutdown/reboot.
# Called from exittc
# (c) Robert Shingledecker 2006-2010
. /etc/init.d/tc-functions


[ -x /opt/shutdown.sh ] && /opt/shutdown.sh

ACTION="$1"
case "$ACTION" in
  reboot )
    sudo reboot
  ;;
  shutdown )
    sudo poweroff
  ;;
  * )
    sudo poweroff
  ;;
esac

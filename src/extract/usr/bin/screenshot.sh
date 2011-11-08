#!/bin/sh
[ -z ${DISPLAY} ] && echo "Requires X" &&  exit 1
filename=screenshot_`date "+%m%d%H%M%S"`.png
/bin/sh -c "sleep 1 && /usr/bin/imlib2_grab $filename"                          
exec popup "Screenshot saved to $HOME/$filename"
#!/bin/sh
# $1 is the target starting characters of extension name
[ -z "$1" ] && exit 1
[ -e info.lst.gz ] || tce-fetch.sh info.lst.gz 2>/dev/null
[ "$?" == 0 ] || exit 1
gunzip -c info.lst.gz > info.lst
grep -i ^$1 info.lst > /tmp/info.$$
mv -f /tmp/info.$$ info.lst

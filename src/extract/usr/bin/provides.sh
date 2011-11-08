#!/bin/sh
# $1 is the filename
[ -z "$1" ] && exit 1
FILENAME='whatprovides4xx86.cgi?'$1
OUT=`mktemp`

wget -O "$OUT" -q http://www.tinycorelinux.net/cgi-bin/"$FILENAME"
grep -v "^  <" "$OUT" > info.lst
rm "$OUT"
sed -i 's/\.list$//' info.lst

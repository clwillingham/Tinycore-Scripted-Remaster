#!/bin/sh
# $1 is the target
[ -z "$1" ] && exit 1
TARGET=`echo $1 | tr '[A-Z]' '[a-z]'`
FILENAME='words4xx86.cgi?'$TARGET
OUT=`mktemp`

wget -O "$OUT" -q http://www.tinycorelinux.net/cgi-bin/"$FILENAME"
grep -v "^  <" "$OUT" > info.lst
rm "$OUT"
sed -i 's/\.list$//' info.lst

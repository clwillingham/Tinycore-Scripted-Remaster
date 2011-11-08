#!/bin/bash
rm squashfs-root
for i in $( ls ); do
if [ ! $i == "unsquashall.sh" ] && [ -f $i ]; then
unsquashfs -f $i
fi
done

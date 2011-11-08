#!/bin/sh
if ! pidof appbrowser >/dev/null; then exit 1; fi
read command
while [ "${command}" != "quit" ] && [ "${command}X" != "X" ]; do
    ${command}
    if ! pidof appbrowser >/dev/null; then exit 1; fi
    read command
done
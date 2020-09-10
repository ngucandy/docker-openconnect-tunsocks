#!/bin/bash
set -e

echo -n -e "${PASSWORD}" | exec openconnect --script-tun --script="tunsocks -k 60 -D 0.0.0.0:9000 -H 0.0.0.0:80 -u 22222 $OCPROXY_OPTIONS" -u $USERNAME $URL

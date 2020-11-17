#!/bin/bash
set -e

echo -n -e "${PASSWORD}" | openconnect --script-tun --script='tunsocks -k 60 -D 0.0.0.0:9000 -H 0.0.0.0:8080 -u 22222 $TUNSOCKS_OPTS' -u $USERNAME $URL

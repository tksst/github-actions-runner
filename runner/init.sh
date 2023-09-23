#!/bin/dash

set -e
set -u

./config.sh  --unattended --name "$( date '+%Y%m%dT%H%M%S%z' )" "$@"

trap './config.sh remove --token "${TOKEN}"' EXIT

./run.sh

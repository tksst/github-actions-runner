#!/bin/bash

set -e
set -u

./config.sh  --unattended --name "$( hostname )-$( date '+%Y%m%dT%H%M%S%z' )" "$@"

# get token from "--token XXXX"
while [ $# -gt 0 ]; do
  case $1 in
    --token) TOKEN=$2; break;;
	*) shift ;;
  esac
done

# dash needs this to run the EXIT handler when it receives SIGTERM/INT/HUP.
trap 'echo "init.sh: Received signal, terminating the runner"; kill -TERM $pid' INT TERM HUP
trap 'echo "init.sh: Removing this runner from GitHub"; ./config.sh remove --token "${TOKEN}"' EXIT

./run.sh &
pid=$!
wait -f $pid

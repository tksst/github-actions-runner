#!/bin/bash

set -e
set -u
set -o pipefail

function get_token(){

  local access_token
  access_token=$( cat "$1" )

  curl -sSfL \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $access_token" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$url_for_token" \
    | jq -r .token
}

if [[ -z $TOKEN_FILE ]]; then
  echo "TOKEN_FILE not specified" >&2
  exit 1
fi

if [[ ! -r $TOKEN_FILE  ]]; then
  echo "$TOKEN_FILE not readable" >&2
  exit 1
fi

if [[ $GITHUB_RUNNER_FOR == "repo" ]]; then
  readonly url_for_configsh="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}"
  readonly url_for_token="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/registration-token"
elif [[ $GITHUB_RUNNER_FOR == "org" ]]; then
  readonly url_for_configsh="https://github.com/${GITHUB_OWNER}"
  readonly url_for_token="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/registration-token"
else
  echo "unknown GITHUB_RUNNER_FOR: $GITHUB_RUNNER_FOR" >&2
  exit 1
fi

TOKEN=$( get_token "$TOKEN_FILE" )

./config.sh  --unattended --name "$( hostname )-$( date '+%Y%m%dT%H%M%S%z' )" --token "$TOKEN" --url "$url_for_configsh" "$@"

# dash needs this to run the EXIT handler when it receives SIGTERM/INT/HUP.
trap 'echo "init.sh: Received signal, terminating the runner"; kill -TERM $pid' INT TERM HUP
trap 'echo "init.sh: Removing this runner from GitHub"; ./config.sh remove --token "${TOKEN}"' EXIT

./run.sh &
pid=$!
wait -f $pid

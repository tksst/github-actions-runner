# syntax=docker/dockerfile:1.4.1
FROM ubuntu:jammy@sha256:aabed3296a3d45cede1dc866a24476c4d7e093aa806263c27ddaadbdce3c1054

RUN \
  --mount=type=cache,target=/var/lib/apt/lists \
  --mount=type=cache,target=/var/cache/apt \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o posix

    # /etc/apt/apt.conf.d/docker-clean disables /var/cache/apt/archives caching
    # so disabled temporarily
    mv /etc/apt/apt.conf.d/docker-clean /

    yes | unminimize

    useradd -m -s /usr/bin/bash user

    apt-get update

    # actions-runnerインストールに必要
    apt-get -y --no-install-recommends install curl ca-certificates

    mkdir /actions-runner
    cd /actions-runner
    curl -L https://github.com/actions/runner/releases/download/v2.309.0/actions-runner-linux-x64-2.309.0.tar.gz | tar -xzf -

    ./bin/installdependencies.sh

    chown -R user:user /actions-runner

_EOFEOF_

RUN \
  --mount=type=cache,target=/var/lib/apt/lists \
  --mount=type=cache,target=/var/cache/apt \
  --mount=type=tmpfs,target=/tmp/tmp/ \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    tool_json=/tmp/tmp/toolset-2204.json

    apt-get update
    apt-get install -y software-properties-common jq unzip

    curl -fsSL https://github.com/actions/runner-images/raw/0ac9d155ab63dfebe079716d8aa343348fec34b5/images/linux/toolsets/toolset-2204.json > "$tool_json"

    export DEBIAN_FRONTEND=noninteractive

    # https://github.com/actions/runner-images/blob/0ac9d155ab63dfebe079716d8aa343348fec34b5/images/linux/scripts/installers/apt-common.sh
    # https://github.com/actions/runner-images/blob/0ac9d155ab63dfebe079716d8aa343348fec34b5/images/linux/scripts/installers/apt-vital.sh

    jq '.apt.common_packages[]' < "$tool_json" | xargs apt-get install -y --no-install-recommends
    jq '.apt.cmd_packages[]' < "$tool_json" | xargs apt-get install -y --no-install-recommends
    jq '.apt.vital_packages[]' < "$tool_json" | xargs apt-get install -y --no-install-recommends


    # Git
    add-apt-repository -y ppa:git-core/ppa
    curl -fsSL https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
    apt-get update
    apt-get -y install git git-lfs

    # Git version 2.35.2 introduces security fix that breaks action\checkout https://github.com/actions/checkout/issues/760
    cat <<EOFXXX >> /etc/gitconfig
[safe]
    directory = *
EOFXXX

    # Add well-known SSH host keys to known_hosts
    ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> /etc/ssh/ssh_known_hosts
    ssh-keyscan -t rsa ssh.dev.azure.com >> /etc/ssh/ssh_known_hosts

    # GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg > /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
    apt-get update
    apt-get install -y gh

_EOFEOF_

################################
# Node.js
################################

RUN \
  --mount=type=cache,target=/var/lib/apt/lists \
  --mount=type=cache,target=/var/cache/apt \
  --mount=type=tmpfs,target=/tmp/tmp/ \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    tool_json=/tmp/tmp/toolset-2204.json
    n=/tmp/tmp/n

    curl -L https://github.com/actions/runner-images/raw/0ac9d155ab63dfebe079716d8aa343348fec34b5/images/linux/toolsets/toolset-2204.json -o "$tool_json"
    
    curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o "$n"
    bash "$n" $( jq -r '.node.default' < "$tool_json" )

_EOFEOF_

################################
# OpenJDK
################################

RUN \
  --mount=type=cache,target=/var/lib/apt/lists \
  --mount=type=cache,target=/var/cache/apt \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    apt-get update
    apt-get install -y --no-install-recommends openjdk-11-jdk-headless
    
_EOFEOF_

COPY ./init.sh /init.sh

USER user

################################
# Android Command-line tools
################################

ENV ANDROID_SDK_ROOT /home/user/android-sdk
ENV ANDROID_HOME ${ANDROID_SDK_ROOT}

RUN \
  --mount=type=tmpfs,target=/tmp/tmp/ \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    tool_json=/tmp/tmp/toolset-2204.json
    tmp_cmdline_tools=/tmp/tmp/cmdline-tools.zip

    curl -fsSL https://github.com/actions/runner-images/raw/0ac9d155ab63dfebe079716d8aa343348fec34b5/images/linux/toolsets/toolset-2204.json -o "$tool_json"

    cmdlineToolsVersion=$( jq -r '.android."cmdline-tools"' < "$tool_json" )

    curl -fsSL -o "$tmp_cmdline_tools" "https://dl.google.com/android/repository/${cmdlineToolsVersion}"

    mkdir -p "$ANDROID_SDK_ROOT"

    unzip -qq "$tmp_cmdline_tools" -d "${ANDROID_SDK_ROOT}/cmdline-tools"

    # Command line tools need to be placed in ${ANDROID_SDK_ROOT}/sdk/cmdline-tools/latest to determine SDK root
    mv "${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest"

    set +o pipefail
    yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses
    set -o pipefail
    
_EOFEOF_

WORKDIR /actions-runner

ENTRYPOINT [ "/init.sh" ]

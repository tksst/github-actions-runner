# syntax=docker/dockerfile:1.4.1
FROM ubuntu:jammy@sha256:a6d2b38300ce017add71440577d5b0a90460d0e57fd7aec21dd0d1b0761bbfb2

ARG TOOLSET_JSON_DIGEST=33875804693d2c58977c82f70dcb7a10dafad9d7

RUN \
  --mount=type=cache,target=/var/lib/apt/lists \
  --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/tmp/tmp/ \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    # /etc/apt/apt.conf.d/docker-clean disables /var/cache/apt/archives caching
    # so disabled temporarily
    mv /etc/apt/apt.conf.d/docker-clean /

    useradd -m -s /usr/bin/bash user

    apt-get update

    # 様々なインストールに必要
    apt-get -y --no-install-recommends install wget curl ca-certificates

    tool_json=/tmp/tmp/toolset-2204.json

    curl -fsSL "https://github.com/actions/runner-images/raw/${TOOLSET_JSON_DIGEST}/images/ubuntu/toolsets/toolset-2204.json" > "$tool_json"

    export DEBIAN_FRONTEND=noninteractive

    # https://github.com/actions/runner-images/blob/5d40b1e2130ee3081ebf2a5f0b75854e3a4aff2e/images/ubuntu/scripts/build/apt-common.sh
    # https://github.com/actions/runner-images/blob/1bd9214f41fdc2aa56e86e0b4043e4364fa51497/images/ubuntu/scripts/build/install-apt-vital.sh

    apt-get install -y jq
    jq '.apt.common_packages[]' < "$tool_json" | grep -v "lib32z1" | xargs apt-get install -y --no-install-recommends
    jq '.apt.cmd_packages[]' < "$tool_json" | xargs apt-get install -y --no-install-recommends
    jq '.apt.vital_packages[]' < "$tool_json" | xargs apt-get install -y --no-install-recommends


    # Git
    apt-get install -y software-properties-common
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

################################
# OpenJDK
################################

    apt-get install -y --no-install-recommends openjdk-11-jdk-headless

_EOFEOF_

################################
# Node.js
################################

RUN \
  --mount=type=cache,target=/var/lib/apt/lists \
  --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/tmp/tmp/ \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    tool_json=/tmp/tmp/toolset-2204.json
    n=/tmp/tmp/n
    
    curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o "$n"
    bash "$n" $( jq -r '.node.default' < "$tool_json" )

_EOFEOF_

################################
# Android Command-line tools
################################

ENV ANDROID_SDK_ROOT /home/user/android-sdk
ENV ANDROID_HOME ${ANDROID_SDK_ROOT}

RUN \
  --mount=type=cache,target=/tmp/tmp/ \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    tool_json=/tmp/tmp/toolset-2204.json

    cmdlineToolsVersion=$( jq -r '.android."cmdline-tools"' < "$tool_json" )

    cd /tmp/tmp/
    mkdir -p android-sdk
    cd android-sdk

    # purge old caches
    if [[ ! -f $cmdlineToolsVersion ]]; then
      rm -rf *
    fi

    wget --no-verbose --timestamping "https://dl.google.com/android/repository/${cmdlineToolsVersion}"
    mkdir -p "$ANDROID_SDK_ROOT"
    unzip -qq "$cmdlineToolsVersion" -d "${ANDROID_SDK_ROOT}/cmdline-tools"
    chown -R user:user "$ANDROID_SDK_ROOT"

_EOFEOF_

USER user

RUN \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    # Command line tools need to be placed in ${ANDROID_SDK_ROOT}/sdk/cmdline-tools/latest to determine SDK root
    mv "${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest"

    set +o pipefail
    yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses
    set -o pipefail

_EOFEOF_

USER root

ARG RUNNER_VERSION=v2.316.1

RUN \
  --mount=type=cache,target=/var/lib/apt/lists \
  --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/tmp/tmp/ \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    echo "arch command output: $( arch )"

    case $(arch) in
    "x86_64")
      package_arch=x64;;
    "aarch64")
      package_arch=arm64;;
    "armv7l")
      package_arch=arm;;
    *)
      package_arch=$(arch);;
    esac

    cd /tmp/tmp
    mkdir -p actions-runner
    cd actions-runner

    file=actions-runner-linux-${package_arch}-${RUNNER_VERSION#v}.tar.gz

    # purge old caches
    if [[ ! -e $file ]]; then
      rm -rf *
    fi

    wget --no-verbose --timestamping "https://github.com/actions/runner/releases/download/${RUNNER_VERSION}/${file}"

    mkdir /actions-runner
    cd /actions-runner

    tar -xf "/tmp/tmp/actions-runner/$file"

    ./bin/installdependencies.sh

    chown -R user:user /actions-runner

_EOFEOF_

USER user

COPY ./init.sh /init.sh

WORKDIR /actions-runner

ENTRYPOINT [ "/init.sh" ]

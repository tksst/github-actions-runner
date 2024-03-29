# syntax=docker/dockerfile:1.4.1
FROM ubuntu:jammy@sha256:77906da86b60585ce12215807090eb327e7386c8fafb5402369e421f44eff17e

RUN \
  --mount=type=tmpfs,target=/var/lib/apt/lists \
  --mount=type=tmpfs,target=/var/cache/apt \
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

    # 様々なインストールに必要
    apt-get -y --no-install-recommends install curl ca-certificates

_EOFEOF_

ARG TOOLSET_JSON_URL=https://github.com/actions/runner-images/raw/33875804693d2c58977c82f70dcb7a10dafad9d7/images/ubuntu/toolsets/toolset-2204.json

RUN \
  --mount=type=tmpfs,target=/var/lib/apt/lists \
  --mount=type=tmpfs,target=/var/cache/apt \
  --mount=type=tmpfs,target=/tmp/tmp/ \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    tool_json=/tmp/tmp/toolset-2204.json

    apt-get update
    apt-get install -y software-properties-common jq unzip

    curl -fsSL "$TOOLSET_JSON_URL" > "$tool_json"

    export DEBIAN_FRONTEND=noninteractive

    # https://github.com/actions/runner-images/blob/5d40b1e2130ee3081ebf2a5f0b75854e3a4aff2e/images/ubuntu/scripts/build/apt-common.sh
    # https://github.com/actions/runner-images/blob/1bd9214f41fdc2aa56e86e0b4043e4364fa51497/images/ubuntu/scripts/build/install-apt-vital.sh

    jq '.apt.common_packages[]' < "$tool_json" | grep -v "lib32z1" | xargs apt-get install -y --no-install-recommends
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
  --mount=type=tmpfs,target=/var/lib/apt/lists \
  --mount=type=tmpfs,target=/var/cache/apt \
  --mount=type=tmpfs,target=/tmp/tmp/ \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    tool_json=/tmp/tmp/toolset-2204.json
    n=/tmp/tmp/n

    curl -fsSL "$TOOLSET_JSON_URL" -o "$tool_json"
    
    curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o "$n"
    bash "$n" $( jq -r '.node.default' < "$tool_json" )

_EOFEOF_

################################
# OpenJDK
################################

RUN \
  --mount=type=tmpfs,target=/var/lib/apt/lists \
  --mount=type=tmpfs,target=/var/cache/apt \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    apt-get update
    apt-get install -y --no-install-recommends openjdk-11-jdk-headless

_EOFEOF_

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

    curl -fsSL "$TOOLSET_JSON_URL" -o "$tool_json"

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

USER root

ARG RUNNER_VERSION=v2.315.0

RUN \
  --mount=type=tmpfs,target=/var/lib/apt/lists \
  --mount=type=tmpfs,target=/var/cache/apt \
  <<_EOFEOF_
#!/bin/bash
    set -eu
    set -o pipefail
    set -o posix

    mkdir /actions-runner
    cd /actions-runner

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

    curl -fsSL https://github.com/actions/runner/releases/download/${RUNNER_VERSION}/actions-runner-linux-${package_arch}-${RUNNER_VERSION#v}.tar.gz | tar -xzf -

    ./bin/installdependencies.sh

    chown -R user:user /actions-runner

_EOFEOF_

USER user

COPY ./init.sh /init.sh

WORKDIR /actions-runner

ENTRYPOINT [ "/init.sh" ]

# Arch Linux image for building Expo / React Native iOS apps with pods/prepare.sh and pods/build.sh.
#   docker build -t rn-ios-linux -f pods/Dockerfile .
#   docker run --rm -v rn-ios-home:/home/b -v /path/Xcode_27.2.xip:/xcode.xip:ro rn-ios-linux \
#     sweetpad setup --sdk /xcode.xip --non-interactive          # once: Swift + Darwin SDK into the volume
#   docker run --rm -v rn-ios-home:/home/b -v $PWD:/oad -v /path/app-repo:/work rn-ios-linux \
#     sh -c '. ~/.config/sweetpad/linux-env.sh && /oad/pods/prepare.sh /work/<app> && /oad/pods/build.sh /work/<app>'
FROM archlinux:latest
ARG SWEETPAD_VERSION=0.1.29
# libarchive's bsdtar replaces GNU tar: Expo's precompiled-module check needs its member globbing.
# libxml2-legacy: the swift.org toolchain sweetpad installs links libxml2.so.2.
RUN pacman -Syu --noconfirm --needed base-devel git nodejs npm ruby rubygems ruby-erb ruby-bigdecimal \
      ruby-json ruby-stdlib python clang lld llvm unzip zip curl which cpio xz rsync file libarchive sudo libxml2-legacy \
 && ln -sf bsdtar /usr/bin/tar \
 && npm i -g corepack && corepack enable
# Arch's gem config installs per user; install CocoaPods where every user sees it.
ENV GEM_HOME=/opt/gems GEM_PATH=/opt/gems LANG=C.UTF-8
RUN gem install --no-user-install --no-document --bindir /usr/local/bin cocoapods
RUN curl -fsSLo /tmp/sp.tgz "https://github.com/sweetpad-dev/sweetpad/releases/download/cli-v${SWEETPAD_VERSION}/sweetpad-cli-${SWEETPAD_VERSION}-linux-x64.tar.gz" \
 && curl -fsSLo /tmp/sp.tgz.sha256 "https://github.com/sweetpad-dev/sweetpad/releases/download/cli-v${SWEETPAD_VERSION}/sweetpad-cli-${SWEETPAD_VERSION}-linux-x64.tar.gz.sha256" \
 && (cd /tmp && sed 's# .*# sp.tgz#' sp.tgz.sha256 | sha256sum -c -) \
 && mkdir -p /opt/sweetpad && tar -xzf /tmp/sp.tgz -C /opt/sweetpad && rm /tmp/sp.tgz* \
 && ln -s /opt/sweetpad/sweetpad /usr/local/bin/sweetpad
RUN useradd -m -u 1000 b && echo 'b ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/b
USER b
WORKDIR /work

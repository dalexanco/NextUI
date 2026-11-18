# FlexUI simulator: the desktop platform built and run on Linux, on a virtual
# screen, so a session can be driven by keys and read by screenshots.
# Started and driven by test/sim/sim.sh; see .claude/skills/sim/SKILL.md.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Build deps: the desktop job of .github/workflows/dev.yaml, plus lz4 and OpenSSL.
# Runtime: a virtual X server, key injection, screenshots, BusyBox for ash.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake git ca-certificates rsync \
        libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev \
        libzip-dev liblzma-dev libzstd-dev libbz2-dev zlib1g-dev \
        libsamplerate0-dev libsqlite3-dev liblz4-dev libssl-dev \
        xvfb xdotool imagemagick x11-utils \
        busybox shellcheck curl procps psmisc \
    && rm -rf /var/lib/apt/lists/*

COPY in-container/ /opt/sim/
RUN chmod +x /opt/sim/*.sh \
    && mkdir -p /opt/sim/bin \
    && ln -s /opt/sim/fake-minarch.sh /opt/sim/bin/minarch.elf

WORKDIR /work
CMD ["sleep", "infinity"]

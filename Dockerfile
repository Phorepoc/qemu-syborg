# qemu-syborg: the Symbian Foundation's QEMU fork (qemu-symbian-svp 0.9.1-12, CodeSourcery) with the Syborg board,
# built and run in a period Debian squeeze (2011) userland: the fork needs gcc 4.4, Python 2.6 (the Syborg device
# models are Python plugins), SDL 1.2 and libpng 1.2, which no current distribution provides.
# Source: the Phorepoc fork of oss.FCL.sf.adapt.Qemu at the commit in source.lock, plus patches/*.patch.

# 1. fetch the source (squeeze's git and TLS are too old for GitHub)
FROM ubuntu:24.04 AS source
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates git patch \
    && rm -rf /var/lib/apt/lists/*
COPY source.lock patches/ /in/
RUN set -eu; commit=$(grep -v '^#' /in/source.lock | cut -f2); \
    git init -q /src && git -C /src fetch -q --depth 1 https://github.com/Phorepoc/oss.FCL.sf.adapt.Qemu.git "$commit" \
    && git -C /src checkout -q FETCH_HEAD \
    && mkdir /out && cp -a /src/symbian-qemu-0.9.1-12 /out/ \
    && cp /src/baseport/syborg/syborg.dtb /out/ \
    && cd /out && find . -type f \( -name '*.c' -o -name '*.h' -o -name '*.py' -o -name '*.mak' -o -name '*.sh' \
        -o -name '*.in' -o -name '*.texi' -o -name 'Makefile*' -o -name '*.d' -o -name '*.ld' -o -name '*.x' \
        -o -name '*.dts' -o -name '*.cpp' -o -name configure \) -exec sed -i 's/\r$//' {} + \
    && for p in /in/*.patch; do patch -p1 --no-backup-if-mismatch < "$p"; done

# 2. build and run in squeeze (EOL: archive.debian.org; libc pinned to the one version the archive still has)
FROM debian/eol:squeeze
RUN rm -f /etc/apt/sources.list.d/* \
 && echo 'deb [trusted=yes] http://archive.debian.org/debian/ squeeze main contrib' > /etc/apt/sources.list \
 && echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid \
 && (apt-get -o Acquire::Check-Valid-Until=false update || true) \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes \
        libc6=2.11.3-4 libc-bin=2.11.3-4 libc6-dev=2.11.3-4 \
        libssl0.9.8=0.9.8o-4squeeze14 libssl-dev=0.9.8o-4squeeze14 \
        libexpat1-dev=2.0.1-7+squeeze1 \
        build-essential python2.6-dev libsdl1.2-dev libpng12-dev zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*
COPY --from=source /out/ /opt/syborg-src/
RUN set -eu; Q=/opt/syborg-src/symbian-qemu-0.9.1-12/qemu-symbian-svp; cd "$Q" \
 && sed -i 's/png_voidp_NULL/(png_voidp)NULL/g; s/png_infopp_NULL/(png_infopp)NULL/g' gui_png.c \
 && bash configure --target-list=arm-softmmu --disable-kqemu --python-config=python2.6-config \
 && make -j"$(nproc)" \
 && make -C /opt/syborg-src/symbian-qemu-0.9.1-12/model-libraries/nvmemmory \
 && mkdir -p /opt/qemu-syborg/lib \
 && cp arm-softmmu/qemu-system-arm /opt/qemu-syborg/ \
 && cp -a plugins pc-bios /opt/qemu-syborg/ 2>/dev/null || cp -a plugins /opt/qemu-syborg/ \
 && cp /opt/syborg-src/symbian-qemu-0.9.1-12/model-libraries/nvmemmory/Release/libnvmemmory.so.1.0 \
       /opt/qemu-syborg/lib/libnvmemmory.so \
 && cp /opt/syborg-src/syborg.dtb /opt/qemu-syborg/ \
 && make clean >/dev/null
COPY run-syborg /usr/local/bin/run-syborg
RUN chmod +x /usr/local/bin/run-syborg
ENV LD_LIBRARY_PATH=/opt/qemu-syborg/lib SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy
WORKDIR /work

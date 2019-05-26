FROM ubuntu:18.04

MAINTAINER Diego Nehab <diego.nehab@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

ENV BASE "/opt/riscv"

RUN \
    mkdir -p $BASE

RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        build-essential autoconf automake libtool libtool-bin autotools-dev \
        git make pkg-config patchutils gawk bison flex ca-certificates \
        device-tree-compiler libmpc-dev libmpfr-dev libgmp-dev \
        libusb-1.0-0-dev texinfo gperf bc zlib1g-dev libncurses-dev \
        wget vim wget curl zip unzip libexpat-dev python3 help2man && \
    rm -rf /var/lib/apt/lists/*

# Download and install crosstool-ng
# ----------------------------------------------------
RUN \
    cd $BASE && \
    mkdir build && \
    cd build && \
    wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.24.0.tar.xz && \
    tar -Jxvf crosstool-ng-1.24.0.tar.xz && \
    rm -rf crosstool-ng-1.24.0.tar.xz && \
    cd crosstool-ng-1.24.0/ && \
    ./bootstrap && \
    ./configure --prefix=${BASE}/build && \
    make && \
    make install && \
    cd $BASE/build && \
    rm -rf crosstool-ng-1.24.0

ENV PATH="${PATH}:${BASE}/build/bin"

# Build gcc 8.3 using crosstool-ng
# ----------------------------------------------------
COPY ct-ng-config $BASE/build/.config

# Add user to run crosstool-ng (it is dangerous to run it as root),
RUN \
    adduser ct-ng --gecos ",,," --disabled-password && \
    chmod o+w $BASE && \
    chmod o+w $BASE/build

USER ct-ng

RUN \
    cd $BASE/build && \
    (ct-ng build.$(nproc) || cat build.log) && \
    rm -rf .build && \
    rm .config

USER root

RUN \
    chmod o-w $BASE && \
    chown -R root:root $BASE && \
    deluser ct-ng --remove-home

ENV PATH="${PATH}:${BASE}/riscv64-unknown-linux-gnu/bin"

# Build linux kernel
# ----------------------------------------------------

COPY linux-config $BASE/build

RUN \
    cd ${BASE}/build && \
    wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.20.8.tar.xz && \
    tar -Jxvf linux-4.20.8.tar.xz

RUN \
    cd ${BASE}/build/linux-4.20.8 && \
    cp ../linux-config .config && \
    make ARCH=riscv olddefconfig && \
    make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- -j$(nproc) vmlinux

# Build riscv-pk and link with kernel
# ----------------------------------------------------
COPY riscv-pk.patch $BASE/build

RUN \
    cd ${BASE}/build && \
    git clone https://github.com/riscv/riscv-pk.git && \
    cd riscv-pk && \
    git config --global user.email "diego@cartesi.io" && \
    git config --global user.name "Diego Nehab" && \
    git am < ${BASE}/build/riscv-pk.patch && \
    mkdir build && \
    cd build && \
    ../configure --with-payload=${BASE}/build/linux-4.20.8/vmlinux --host=riscv64-unknown-linux-gnu && \
    make bbl && \
    riscv64-unknown-linux-gnu-objcopy -O binary bbl $BASE/kernel.bin && \
    truncate -s %4096 $BASE/kernel.bin

WORKDIR $BASE

CMD ["/bin/bash", "-l"]

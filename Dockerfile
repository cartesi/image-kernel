ARG TOOLCHAIN_VERSION=latest
FROM cartesi/image-toolchain:${TOOLCHAIN_VERSION}

LABEL maintainer="Diego Nehab <diego@cartesi.io>"

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

ENV BUILD_BASE=$BASE/kernel

# Build linux kernel
# ----------------------------------------------------

RUN \
    mkdir -p $BUILD_BASE

COPY linux-config $BUILD_BASE

RUN \
    cd ${BUILD_BASE} && \
    wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.20.8.tar.xz && \
    tar -Jxvf linux-4.20.8.tar.xz

RUN \
    cd ${BUILD_BASE}/linux-4.20.8 && \
    cp ../linux-config .config && \
    make ARCH=riscv olddefconfig && \
    make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- -j$(nproc) vmlinux

# Build riscv-pk and link with kernel
# ----------------------------------------------------
COPY riscv-pk.patch $BUILD_BASE

RUN \
    cd ${BUILD_BASE} && \
    git clone https://github.com/riscv/riscv-pk.git && \
    cd riscv-pk && \
    git config --global user.email "diego@cartesi.io" && \
    git config --global user.name "Diego Nehab" && \
    git am < ${BUILD_BASE}/riscv-pk.patch && \
    mkdir build && \
    cd build && \
    ../configure --with-payload=${BUILD_BASE}/linux-4.20.8/vmlinux --host=riscv64-unknown-linux-gnu && \
    make bbl && \
    riscv64-unknown-linux-gnu-objcopy -O binary bbl $BASE/kernel.bin && \
    truncate -s %4096 $BASE/kernel.bin

WORKDIR $BASE

CMD ["/bin/bash", "-l"]

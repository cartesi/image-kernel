FROM cartesi/image-toolchain:latest

MAINTAINER Diego Nehab <diego.nehab@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

# Build riscv's kernel and bootloader with ABI lp64 and ISA rv64ima
# (emulating rv64imafd)
# ----------------------------------------------------
ENV ARCH "rv64ima"
ENV ABI "lp64"
ENV RISCV "$BASE/toolchain/linux/$ARCH-$ABI"
ENV PATH "$RISCV/bin:${OLDPATH}"

RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        libssl-dev && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p $BASE/kernel && \
    cd $BASE/kernel && \
    git clone --branch cartesi --depth 1 \
        https://github.com/cartesi/riscv-linux.git && \
    git clone --branch cartesi --depth 1 \
        https://github.com/cartesi/riscv-pk.git

COPY cartesi-config $BASE/kernel/riscv-linux/.config

RUN \
    NPROC=$(nproc) && \
    cd $BASE/kernel/riscv-linux && \
    git pull && \
    make ARCH=riscv olddefconfig && \
    make -j$NPROC ARCH=riscv vmlinux && \
    cd $BASE/kernel/riscv-pk && \
    git pull && \
    mkdir build && \
    cd build && \
    ../configure --with-payload=$BASE/kernel/riscv-linux/vmlinux \
        --host=riscv64-unknown-linux-gnu && \
    make -j$NPROC bbl && \
    riscv64-unknown-linux-gnu-objcopy -O binary bbl $BASE/kernel.bin && \
    truncate -s %4096 $BASE/kernel.bin

USER root

WORKDIR $BASE

CMD ["/bin/bash", "-l"]

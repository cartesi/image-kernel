FROM cartesi/image-toolchain:latest

MAINTAINER Diego Nehab <diego.nehab@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

# Build riscv's kernel and bootloader with ABI lp64 and ISA rv64ima
# (emulating rv64imafd)
# ----------------------------------------------------
ENV ARCH "rv64ima"
ENV ABI "lp64"
ENV RISCV "$BASE/linux/$ARCH-$ABI"
ENV PATH "$RISCV/bin:${OLDPATH}"

RUN \
    cd $BASE && \
    mkdir -p kernel && \
    cd kernel && \
    git clone --branch cartesi --depth 1 \
        https://github.com/cartesi/riscv-linux.git && \
    git clone --branch cartesi --depth 1 \
        https://github.com/cartesi/riscv-pk.git

COPY config $BASE/kernel/riscv-linux/.config

RUN  \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        libssl-dev && \
    rm -rf /var/lib/apt/lists/*

RUN \
    NPROC=$(nproc) && \
    cd kernel/riscv-linux && \
    make ARCH=riscv olddefconfig && \
    make -j$NPROC ARCH=riscv vmlinux && \
    cd ../riscv-pk && \
    mkdir build && \
    cd build && \
    ../configure --with-payload=$BASE/kernel/riscv-linux/vmlinux \
        --host=riscv64-unknown-linux-gnu && \
    make -j$NPROC bbl && \
    riscv64-unknown-linux-gnu-objcopy -O binary bbl $BASE/kernel.bin

USER root

WORKDIR $BASE

CMD ["/bin/bash", "-l"]

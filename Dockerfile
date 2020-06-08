# Copyright 2019 Cartesi Pte. Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
#

ARG TOOLCHAIN_VERSION=latest
FROM cartesi/toolchain:${TOOLCHAIN_VERSION}

LABEL maintainer="Diego Nehab <diego@cartesi.io>"

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

ENV BUILD_BASE=$BASE/kernel

ENV KV=5.5.4

# Build linux kernel
# ----------------------------------------------------

RUN \
    mkdir -p $BUILD_BASE

RUN \
    cd ${BUILD_BASE} && \
    wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${KV}.tar.xz && \
    tar -Jxvf linux-${KV}.tar.xz

COPY kernel-patches $BUILD_BASE/kernel-patches
COPY linux-config $BUILD_BASE

RUN \
    cd ${BUILD_BASE}/linux-${KV} && \
    for p in ${BUILD_BASE}/kernel-patches/* ; do patch -p1 < $p ; done && \
    cp ../linux-config .config && \
    make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- olddefconfig && \
    make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- -j$(nproc) vmlinux && \
    make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- INSTALL_HDR_PATH=/opt/riscv/usr  headers_install

# Build riscv-pk and link with kernel
# ----------------------------------------------------
COPY riscv-pk-patches $BUILD_BASE/riscv-pk-patches
COPY cartesi-logo.txt $BUILD_BASE

RUN \
    cd ${BUILD_BASE} && \
    git clone https://github.com/riscv/riscv-pk.git && \
    cd riscv-pk && \
    git config --global user.email "diego@cartesi.io" && \
    git config --global user.name "Diego Nehab" && \
    git checkout 099c99482f7ac032bf04caad13a9ca1da7ce58ed && \
    git am ${BUILD_BASE}/riscv-pk-patches/* && \
    mkdir build && \
    cd build && \
    ../configure \
 		--with-payload=${BUILD_BASE}/linux-${KV}/vmlinux \
 		--host=riscv64-unknown-linux-gnu \
 		--with-logo=${BUILD_BASE}/cartesi-logo.txt \
 		--enable-logo && \
    make bbl && \
    riscv64-unknown-linux-gnu-objcopy -O binary bbl $BASE/linux.bin && \
    truncate -s %4096 $BASE/linux.bin

WORKDIR $BASE

CMD ["/bin/bash", "-l"]

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

ARG TOOLCHAIN_REPOSITORY=cartesi/toolchain
ARG TOOLCHAIN_VERSION=latest
FROM ${TOOLCHAIN_REPOSITORY}:${TOOLCHAIN_VERSION}

LABEL maintainer="Diego Nehab <diego@cartesi.io>"

ARG KERNEL_VERSION=5.5.19-ctsi-2
ARG RISCV_PK_VERSION=1.0.0-ctsi-1

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

ENV BUILD_BASE=$BASE/kernel

# Build linux kernel
# ----------------------------------------------------

RUN \
    mkdir -p $BUILD_BASE/artifacts

RUN \
    chown -R developer:developer $BUILD_BASE && \
    chmod go+w $BUILD_BASE

USER developer

RUN \
    cd ${BUILD_BASE} && \
    wget -O linux-${KERNEL_VERSION}.tar.gz https://github.com/cartesi/linux/archive/v${KERNEL_VERSION}.tar.gz && \
    tar -zxvf linux-${KERNEL_VERSION}.tar.gz && \
    rm -f linux-${KERNEL_VERSION}.tar.gz

COPY cartesi-linux-config $BUILD_BASE/linux-${KERNEL_VERSION}/cartesi-linux-config

RUN \
    cd ${BUILD_BASE}/linux-${KERNEL_VERSION} && \
    cp cartesi-linux-config .config && \
    make ARCH=riscv CROSS_COMPILE=riscv64-cartesi-linux-gnu- olddefconfig && \
    make ARCH=riscv CROSS_COMPILE=riscv64-cartesi-linux-gnu- -j$(nproc) vmlinux && \
    make ARCH=riscv CROSS_COMPILE=riscv64-cartesi-linux-gnu- INSTALL_HDR_PATH=/opt/riscv/kernel/linux-headers-${KERNEL_VERSION} headers_install && \
    cd ${BUILD_BASE} && \
    tar -cJf artifacts/linux-headers-${KERNEL_VERSION}.tar.xz linux-headers-${KERNEL_VERSION}

# Build riscv-pk and link with kernel
# ----------------------------------------------------
RUN \
    cd ${BUILD_BASE} && \
    wget -O riscv-pk-${RISCV_PK_VERSION}.tar.gz https://github.com/cartesi/riscv-pk/archive/v${RISCV_PK_VERSION}.tar.gz && \
    tar -zxvf riscv-pk-${RISCV_PK_VERSION}.tar.gz && \
    rm -f riscv-pk-${RISCV_PK_VERSION}.tar.gz

COPY cartesi-logo.txt ${BUILD_BASE}/riscv-pk-${RISCV_PK_VERSION}/cartesi-logo.txt

RUN \
    cd ${BUILD_BASE}/riscv-pk-${RISCV_PK_VERSION} && \
    mkdir build && \
    cd build && \
    ../configure \
 		--with-payload=${BUILD_BASE}/linux-${KERNEL_VERSION}/vmlinux \
 		--host=riscv64-cartesi-linux-gnu \
 		--with-logo=${BUILD_BASE}/riscv-pk-${RISCV_PK_VERSION}/cartesi-logo.txt \
 		--enable-logo && \
    make bbl && \
    riscv64-cartesi-linux-gnu-objcopy -O binary bbl ${BUILD_BASE}/artifacts/linux-${KERNEL_VERSION}.bin && \
    truncate -s %4096 ${BUILD_BASE}/artifacts/linux-${KERNEL_VERSION}.bin

USER root

WORKDIR $BASE

CMD ["/bin/bash", "-l"]

# Copyright Cartesi and individual authors (see AUTHORS)
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FROM debian:bookworm

ARG KERNEL_VERSION=0.0.0-ctsi-y
ARG KERNEL_TIMESTAMP="Thu, 01 Jan 1970 00:00:00 +0000"
ARG OPENSBI_VERSION=0.0.0-ctsi-y
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

ENV BASE=/opt/riscv
ENV BUILD_BASE=$BASE/kernel

# install dependencies
# ------------------------------------------------------------------------------
RUN apt-get update && \
  apt-get install --no-install-recommends -y \
    bc \
    bison \
    build-essential \
    ca-certificates \
    flex \
    gcc-riscv64-linux-gnu \
    libc6-dev-riscv64-cross \
    make \
    python3 \
    rsync \
    wget

RUN \
    wget -O /tmp/xgenext2fs.deb https://github.com/cartesi/genext2fs/releases/download/v1.5.3/xgenext2fs_${TARGETARCH}.deb && \
    case ${TARGETARCH} in \
      amd64) echo "a5e52d86d0bf4c2f9cc38370ea762dc5aee502a86abf8520798acbebd9d7f68f  /tmp/xgenext2fs.deb" | sha256sum --check ;; \
      arm64) echo "54051a31a10ba5e4f472b8eeaa47c82f3d2e744991995b8ef6981b4c1ba424c2  /tmp/xgenext2fs.deb" | sha256sum --check ;; \
    esac && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
      /tmp/xgenext2fs.deb && \
    rm -rf /var/lib/apt/lists/*

# setup dirs
# ------------------------------------------------------------------------------
RUN \
  adduser developer -u 499 --gecos ",,," --disabled-password && \
  mkdir -p ${BUILD_BASE}/artifacts && \
  chown -R developer:developer ${BUILD_BASE} && \
  chmod go+w ${BUILD_BASE}

WORKDIR ${BUILD_BASE}
USER developer

# copy kernel
# ------------------------------------------------------------------------------
COPY --chown=developer:developer dep/linux-${KERNEL_VERSION}.tar.gz ${BUILD_BASE}/dep/
RUN tar xzf ${BUILD_BASE}/dep/linux-${KERNEL_VERSION}.tar.gz \
  --strip-components=1 --one-top-level=${BUILD_BASE}/work/linux && \
  rm ${BUILD_BASE}/dep/linux-${KERNEL_VERSION}.tar.gz

# copy opensbi
# ------------------------------------------------------------------------------
COPY --chown=developer:developer dep/opensbi-${OPENSBI_VERSION}.tar.gz ${BUILD_BASE}/dep/
RUN tar xzf ${BUILD_BASE}/dep/opensbi-${OPENSBI_VERSION}.tar.gz \
  --strip-components=1 --one-top-level=${BUILD_BASE}/work/opensbi && \
  rm ${BUILD_BASE}/dep/opensbi-${OPENSBI_VERSION}.tar.gz

# build
# ------------------------------------------------------------------------------
ARG IMAGE_KERNEL_VERSION=0.0.0
COPY build.mk build.mk
RUN make -f build.mk \
  KERNEL_TIMESTAMP="${KERNEL_TIMESTAMP}" \
  IMAGE_KERNEL_VERSION="${IMAGE_KERNEL_VERSION}" \
  TOOLCHAIN_PREFIX=riscv64-linux-gnu

# deb headers
# ------------------------------------------------------------------------------
COPY tools tools
RUN \
  make -f build.mk KERNEL_TIMESTAMP="${KERNEL_TIMESTAMP}" IMAGE_KERNEL_VERSION="${IMAGE_KERNEL_VERSION}" \
    DESTDIR=${BUILD_BASE}/work/_install cross-deb && \
  rm -rf ${BUILD_BASE}/work/_install
RUN \
  make -f build.mk KERNEL_TIMESTAMP="${KERNEL_TIMESTAMP}" IMAGE_KERNEL_VERSION="${IMAGE_KERNEL_VERSION}" \
    DESTDIR=${BUILD_BASE}/work/_install native-deb && \
  rm -rf ${BUILD_BASE}/work/_install

USER root

WORKDIR $BASE

CMD ["/bin/bash", "-l"]

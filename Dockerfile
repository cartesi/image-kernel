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

FROM debian:bookworm

LABEL maintainer="Diego Nehab <diego@cartesi.io>"

ARG KERNEL_VERSION=0.0.0-ctsi-y
ARG KERNEL_TIMESTAMP="Thu, 01 Jan 1970 00:00:00 +0000"
ARG RISCV_PK_VERSION=0.0.0-ctsi-y

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

ENV BASE=/opt/riscv
ENV BUILD_BASE=$BASE/kernel

# setup dirs
# ------------------------------------------------------------------------------
RUN \
  useradd developer && \
  mkdir -p ${BUILD_BASE}/artifacts && \
  chown -R developer:developer ${BUILD_BASE} && \
  chmod go+w ${BUILD_BASE}

RUN \
  apt-get update && \
  DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    bc \
    bison \
    build-essential \
    flex \
    gcc-riscv64-linux-gnu \
    genext2fs \
    libc6-dev-riscv64-cross \
    rsync \
  && \
  rm -rf /var/lib/apt/lists/*

WORKDIR ${BUILD_BASE}
USER developer

# copy kernel
# ------------------------------------------------------------------------------
COPY --chown=developer:developer linux-${KERNEL_VERSION}.tar.gz ${BUILD_BASE}/dep/
RUN tar xzf ${BUILD_BASE}/dep/linux-${KERNEL_VERSION}.tar.gz \
  --strip-components=1 --one-top-level=${BUILD_BASE}/work/linux && \
  rm ${BUILD_BASE}/dep/linux-${KERNEL_VERSION}.tar.gz

# copy riscv-pk
# ------------------------------------------------------------------------------
COPY --chown=developer:developer riscv-pk-${RISCV_PK_VERSION}.tar.gz ${BUILD_BASE}/dep/
RUN tar xzf ${BUILD_BASE}/dep/riscv-pk-${RISCV_PK_VERSION}.tar.gz \
  --strip-components=1 --one-top-level=${BUILD_BASE}/work/riscv-pk && \
  rm ${BUILD_BASE}/dep/riscv-pk-${RISCV_PK_VERSION}.tar.gz

COPY cartesi-linux-config ${BUILD_BASE}/work/linux/.config

# build
# ------------------------------------------------------------------------------
ARG IMAGE_KERNEL_VERSION=0.0.0
COPY build.mk build.mk
RUN make -f build.mk KERNEL_TIMESTAMP="${KERNEL_TIMESTAMP}" IMAGE_KERNEL_VERSION="${IMAGE_KERNEL_VERSION}"

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

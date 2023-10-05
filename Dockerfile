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

ARG TOOLCHAIN_REPOSITORY=cartesi/toolchain
ARG TOOLCHAIN_VERSION=latest
FROM ${TOOLCHAIN_REPOSITORY}:${TOOLCHAIN_VERSION}

ARG KERNEL_VERSION=0.0.0-ctsi-y
ARG KERNEL_TIMESTAMP="Thu, 01 Jan 1970 00:00:00 +0000"
ARG OPENSBI_VERSION=0.0.0-ctsi-y

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

ENV BUILD_BASE=$BASE/kernel

# setup dirs
# ------------------------------------------------------------------------------
RUN \
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

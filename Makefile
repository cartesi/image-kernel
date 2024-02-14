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

.PHONY: all build download push run pull share copy clean checksum

MAJOR := 0
MINOR := 20
PATCH := 0
LABEL :=
IMAGE_KERNEL_VERSION?= $(MAJOR).$(MINOR).$(PATCH)$(LABEL)

UNAME:=$(shell uname)

TAG ?= devel
TOOLCHAIN_REPOSITORY ?= cartesi/toolchain
TOOLCHAIN_TAG ?= 0.17.0

DEP_DIR := dep

KERNEL_VERSION ?= 6.5.13-ctsi-1
KERNEL_SRCPATH := $(DEP_DIR)/linux-${KERNEL_VERSION}.tar.gz

OPENSBI_VERSION ?= 1.3.1-ctsi-2
OPENSBI_SRCPATH := $(DEP_DIR)/opensbi-${OPENSBI_VERSION}.tar.gz

CONTAINER_BASE := /opt/cartesi/kernel

IMG ?= cartesi/linux-kernel:$(TAG)
BASE:=/opt/riscv

ifeq ($(UNAME),Darwin)
KERNEL_TIMESTAMP ?= $(shell date -r $(shell git log -1 --format=%ct 2> /dev/null || date +%s) +"%a, %d %b %Y %H:%M:%S +0000")
else
KERNEL_TIMESTAMP ?= $(shell date -Rud @$(shell git log -1 --format=%ct 2> /dev/null || date +%s))
endif

BUILD_ARGS :=

ifneq ($(IMAGE_KERNEL_VERSION),)
BUILD_ARGS += --build-arg IMAGE_KERNEL_VERSION=$(IMAGE_KERNEL_VERSION)
endif

ifneq ($(TOOLCHAIN_REPOSITORY),)
BUILD_ARGS += --build-arg TOOLCHAIN_REPOSITORY=$(TOOLCHAIN_REPOSITORY)
endif

ifneq ($(TOOLCHAIN_TAG),)
BUILD_ARGS += --build-arg TOOLCHAIN_VERSION=$(TOOLCHAIN_TAG)
endif

ifneq ($(KERNEL_VERSION),)
BUILD_ARGS += --build-arg KERNEL_VERSION=$(KERNEL_VERSION)
endif

ifneq ($(KERNEL_TIMESTAMP),)
BUILD_ARGS += --build-arg KERNEL_TIMESTAMP="$(KERNEL_TIMESTAMP)"
endif

ifneq ($(OPENSBI_VERSION),)
BUILD_ARGS += --build-arg OPENSBI_VERSION=$(OPENSBI_VERSION)
endif

.NOTPARALLEL: all
all: build copy

build: download
	docker build -t $(IMG) $(BUILD_ARGS) .

push:
	docker push $(IMG)

pull:
	docker pull $(IMG)

run:
	docker run --hostname toolchain-env -it --rm \
		-e USER=$$(id -u -n) \
		-e GROUP=$$(id -g -n) \
		-e UID=$$(id -u) \
		-e GID=$$(id -g) \
		-v `pwd`:$(CONTAINER_BASE) \
		-w $(CONTAINER_BASE) \
		$(IMG) $(CONTAINER_COMMAND)

run-as-root:
	docker run --hostname toolchain-env -it --rm \
		-v `pwd`:$(CONTAINER_BASE) \
		$(IMG) $(CONTAINER_COMMAND)

env:
	@echo KERNEL_VERSION="$(KERNEL_VERSION)"
	@echo KERNEL_TIMESTAMP="$(KERNEL_TIMESTAMP)"
	@echo IMAGE_KERNEL_VERSION="$(IMAGE_KERNEL_VERSION)"
	@echo OPENSBI_VERSION="$(OPENSBI_VERSION)"
	@echo TOOLCHAIN_REPOSITORY="$(TOOLCHAIN_REPOSITORY)"
	@echo TOOLCHAIN_VERSION="$(TOOLCHAIN_TAG)"
	@make -srf build.mk \
		KERNEL_VERSION=$(KERNEL_VERSION) \
		KERNEL_TIMESTAMP="$(KERNEL_TIMESTAMP)" \
		IMAGE_KERNEL_VERSION=$(IMAGE_KERNEL_VERSION) env
copy:
	ID=`docker create $(IMG)` && \
	   docker cp $$ID:$(BASE)/kernel/artifacts/ . && \
	   docker rm -v $$ID

$(DEP_DIR):
	mkdir dep

$(KERNEL_SRCPATH): | $(DEP_DIR)
	wget -O $@ https://github.com/cartesi/linux/archive/refs/tags/v$(KERNEL_VERSION).tar.gz

$(OPENSBI_SRCPATH): | $(DEP_DIR)
	wget -O $@ https://github.com/cartesi/opensbi/archive/refs/tags/v$(OPENSBI_VERSION).tar.gz

clean:
	@rm -rf ./artifacts

distclean depclean: clean
	@rm -f $(KERNEL_SRCPATH) $(OPENSBI_SRCPATH)

checksum: $(KERNEL_SRCPATH) $(OPENSBI_SRCPATH)
	shasum -ca 256 shasumfile

shasumfile: $(KERNEL_SRCPATH) $(OPENSBI_SRCPATH)
	@shasum -a 256 $^ > $@

download: checksum

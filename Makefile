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

.PHONY: all build download push run pull share copy clean clean-config checksum

MAJOR := 0
MINOR := 17
PATCH := 0
LABEL :=
IMAGE_KERNEL_VERSION?= $(MAJOR).$(MINOR).$(PATCH)$(LABEL)

UNAME:=$(shell uname)

TAG ?= devel
TOOLCHAIN_REPOSITORY ?= cartesi/toolchain
TOOLCHAIN_TAG ?= 0.15.0
KERNEL_VERSION ?= 5.15.63-ctsi-2
KERNEL_SRCPATH := dep/linux-${KERNEL_VERSION}.tar.gz
OPENSBI_VERSION ?= opensbi-1.2-ctsi-y
OPENSBI_SRCPATH := dep/opensbi-${OPENSBI_VERSION}.tar.gz
KERNEL_CONFIG ?= configs/default-linux-config

CONTAINER_BASE := /opt/cartesi/kernel

IMG ?= cartesi/linux-kernel:$(TAG)
BASE:=/opt/riscv

ifeq ($(UNAME),Darwin)
KERNEL_TIMESTAMP ?= $(shell date -r $(shell git log -1 --format=%ct 2> /dev/null || date +%s) +"%a, %d %b %Y %H:%M:%S +0000")
else
KERNEL_TIMESTAMP ?= $(shell date -Rud @$(shell git log -1 --format=%ct 2> /dev/null || date +%s))
endif

HEADERS  := linux-headers-$(KERNEL_VERSION).tar.xz
IMAGE    := linux-nobl-$(KERNEL_VERSION).bin
LINUX    := linux-$(KERNEL_VERSION).bin
LINUX_ELF:= linux-$(KERNEL_VERSION).elf
SELFTEST := linux-selftest-$(KERNEL_VERSION).ext2

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

build: cartesi-linux-config download
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

config: CONTAINER_COMMAND := $(CONTAINER_BASE)/scripts/update-linux-config
config: cartesi-linux-config run-as-root

env:
	@echo KERNEL_VERSION="$(KERNEL_VERSION)"
	@echo IMAGE_KERNEL_VERSION="$(IMAGE_KERNEL_VERSION)"
	@echo RISCV_PK_VERSION="$(RISCV_PK_VERSION)"
	@echo TOOLCHAIN_REPOSITORY="$(TOOLCHAIN_REPOSITORY)"
	@echo TOOLCHAIN_VERSION="$(TOOLCHAIN_TAG)"
	@make -srf build.mk KERNEL_VERSION=$(KERNEL_VERSION) IMAGE_KERNEL_VERSION=$(IMAGE_KERNEL_VERSION) env
copy:
	ID=`docker create $(IMG)` && \
	   docker cp $$ID:$(BASE)/kernel/artifacts/ . && \
	   docker rm -v $$ID

cartesi-linux-config:
	cp $(KERNEL_CONFIG) ./cartesi-linux-config

$(KERNEL_SRCPATH):
	wget -O $@ https://github.com/cartesi/linux/archive/v$(KERNEL_VERSION).tar.gz

clean-config:
	rm -f ./cartesi-linux-config

clean: clean-config
	rm -f $(HEADERS) $(IMAGE) $(LINUX) $(SELFTEST)

depclean: clean
	rm -f \
		$(KERNEL_SRCPATH) $(OPENSBI_SRCPATH)

checksum: $(KERNEL_SRCPATH) $(OPENSBI_SRCPATH)
	shasum -ca 256 shasumfile

shasumfile: $(KERNEL_SRCPATH) $(OPENSBI_SRCPATH)
	@shasum -a 256 $^ > $@

download: checksum

$(OPENSBI_SRCPATH): URL=https://github.com/cartesi/opensbi/archive/${OPENSBI_VERSION}.tar.gz
$(OPENSBI_SRCPATH): | dep
	T=`mktemp` && wget "$(URL)" -O $$T && mv $$T $@ || rm $$T

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

.PHONY: all build push run pull share copy clean clean-config

TAG ?= devel
TOOLCHAIN_DOCKER_REPOSITORY ?= cartesi/toolchain
TOOLCHAIN_TAG ?= 0.10.0
KERNEL_VERSION ?= 5.5.19-ctsi-6
KERNEL_SRCPATH := dep/linux-${KERNEL_VERSION}.tar.gz
RISCV_PK_VERSION ?= 1.0.0-ctsi-1
RISCV_PK_SRCPATH := dep/riscv-pk-${RISCV_PK_VERSION}.tar.gz
KERNEL_CONFIG ?= configs/default-linux-config

ifeq ($(fd_emulation),yes)
KERNEL_CONFIG = configs/lp64d-linux-config
endif

CONTAINER_BASE := /opt/cartesi/kernel

IMG ?= cartesi/linux-kernel:$(TAG)
BASE:=/opt/riscv

HEADERS  := linux-headers-$(KERNEL_VERSION).tar.xz
IMAGE    := linux-nobbl-$(KERNEL_VERSION).bin
LINUX    := linux-$(KERNEL_VERSION).bin
SELFTEST := linux-selftest-$(KERNEL_VERSION).ext2

BUILD_ARGS :=

ifneq ($(TOOLCHAIN_DOCKER_REPOSITORY),)
BUILD_ARGS += --build-arg TOOLCHAIN_REPOSITORY=$(TOOLCHAIN_DOCKER_REPOSITORY)
endif

ifneq ($(TOOLCHAIN_TAG),)
BUILD_ARGS += --build-arg TOOLCHAIN_VERSION=$(TOOLCHAIN_TAG)
endif

ifneq ($(KERNEL_VERSION),)
BUILD_ARGS += --build-arg KERNEL_VERSION=$(KERNEL_VERSION)
endif

ifneq ($(RISCV_PK_VERSION),)
BUILD_ARGS += --build-arg RISCV_PK_VERSION=$(RISCV_PK_VERSION)
endif

.NOTPARALLEL: all
all: build copy

build: cartesi-linux-config $(KERNEL_SRCPATH) $(RISCV_PK_SRCPATH)
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

copy:
	ID=`docker create $(IMG)` && \
	   docker cp $$ID:$(BASE)/kernel/artifacts/$(HEADERS)  . && \
	   docker cp $$ID:$(BASE)/kernel/artifacts/$(IMAGE)    . && \
	   docker cp $$ID:$(BASE)/kernel/artifacts/$(LINUX)    . && \
	   docker cp $$ID:$(BASE)/kernel/artifacts/$(SELFTEST) . && \
	   docker rm -v $$ID

cartesi-linux-config:
	cp $(KERNEL_CONFIG) ./cartesi-linux-config

clean-config:
	rm -f ./cartesi-linux-config

clean: clean-config
	rm -f $(HEADERS) $(IMAGE) $(LINUX) $(SELFTEST)

depclean: clean
	rm -f \
		$(KERNEL_SRCPATH) $(RISCV_PK_SRCPATH)

dep:
	mkdir dep

$(KERNEL_SRCPATH): dep
	wget -O $@ https://github.com/cartesi/linux/archive/v${KERNEL_VERSION}.tar.gz
	echo "c665a5eb0ac12ad457fc7cab74cb98570f0ce158942baad8923d4d3e36beda5b  $@" | shasum -ca 256 || exit 1

$(RISCV_PK_SRCPATH): dep
	wget -O $@ https://github.com/cartesi/riscv-pk/archive/v${RISCV_PK_VERSION}.tar.gz
	echo "9a873345b9914940e7bf03a167da823910c8a2acadd818b780ffbd1a3edcc4c5  $@" | shasum -ca 256 || exit 1

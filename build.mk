TOOLCHAIN_PREFIX    := riscv64-cartesi-linux-gnu

RISCV_PK_DIR        := work/riscv-pk
RISCV_PK_BUILD_DIR  := $(RISCV_PK_DIR)/build

LINUX_DIR           := work/linux
LINUX_TEST_DIR      := $(LINUX_DIR)/tools/testing/selftests

JOBS                := -j$(shell nproc)

KERNEL_VERSION      ?= $(shell make -sC $(LINUX_DIR) kernelversion)
HEADERS             := artifacts/linux-headers-$(KERNEL_VERSION).tar.xz
IMAGE               := artifacts/linux-nobbl-$(KERNEL_VERSION).bin
LINUX               := artifacts/linux-$(KERNEL_VERSION).bin
LINUX_ELF           := artifacts/linux-$(KERNEL_VERSION).elf
SELFTEST            := artifacts/linux-selftest-$(KERNEL_VERSION).ext2
ARTIFACTS           := $(HEADERS) $(IMAGE) $(LINUX) $(SELFTEST)

all: $(ARTIFACTS)

# build linux
# ------------------------------------------------------------------------------
LINUX_OPTS=$(JOBS) ARCH=riscv CROSS_COMPILE=$(TOOLCHAIN_PREFIX)-
$(LINUX_DIR)/vmlinux $(IMAGE) $(HEADERS) &: $(LINUX_DIR)/.config
	mkdir -p artifacts
	$(MAKE) -rC $(LINUX_DIR) $(LINUX_OPTS) olddefconfig
	$(MAKE) -rC $(LINUX_DIR) $(LINUX_OPTS) vmlinux Image
	$(MAKE) -rC $(LINUX_DIR) $(LINUX_OPTS) headers_install \
		INSTALL_HDR_PATH=$(abspath work/linux-headers)
	tar cJf $(HEADERS) $(abspath work/linux-headers)
	cp work/linux/arch/riscv/boot/Image $(IMAGE)
	cp $(LINUX_DIR)/vmlinux $(LINUX_ELF)

env:
	@echo export ARCH=riscv
	@echo export CROSS_COMPILE=$(TOOLCHAIN_PREFIX)-

# configure riscv-pk
# ------------------------------------------------------------------------------
$(RISCV_PK_BUILD_DIR)/Makefile: $(LINUX_DIR)/vmlinux $(LINUX_DIR)/.config
	@mkdir -p $(RISCV_PK_BUILD_DIR)
	cd $(RISCV_PK_BUILD_DIR) && ../configure \
		--with-payload=$(abspath $<) \
		--disable-fp-emulation \
		--host=$(TOOLCHAIN_PREFIX)

# build linux w/ bbl
# ------------------------------------------------------------------------------
$(LINUX): $(RISCV_PK_DIR)/build/Makefile $(LINUX_DIR)/vmlinux
	mkdir -p artifacts
	$(MAKE) $(JOBS) -rC $(RISCV_PK_BUILD_DIR) bbl
	$(TOOLCHAIN_PREFIX)-objcopy \
		-O binary $(RISCV_PK_BUILD_DIR)/bbl $@
	truncate -s %4096 $@

# build linux tests
# ------------------------------------------------------------------------------
TAR := $(shell mktemp)

$(SELFTEST):
	mkdir -p artifacts
	$(MAKE) $(JOBS) -rC $(LINUX_TEST_DIR) $(LINUX_OPTS) \
		TARGETS=drivers/cartesi install
	tar --sort=name --mtime="2022-01-01" --owner=1000 --group=1000 --numeric-owner -cf $(TAR) --directory=$(LINUX_TEST_DIR)/kselftest_install .
	genext2fs -i 4096 -b 1024 -a $(TAR) $@
	rm $(TAR)

clean:
	$(MAKE) -rC $(LINUX_DIR) $(LINUX_OPTS) clean
	$(MAKE) $(JOBS) -rC $(RISCV_PK_BUILD_DIR) clean

run-selftest:
	cartesi-machine.lua --rollup \
		--append-rom-bootargs=debug \
		--remote-address=localhost:5001 \
		--checkin-address=localhost:5002 \
		--ram-image=`realpath $(LINUX)` \
		--flash-drive=label:selftest,filename:`realpath $(SELFTEST)` \
		-- $(CMD)

# clone (for non CI environment)
# ------------------------------------------------------------------------------
clone: LINUX_BRANCH ?= linux-5.5.19-ctsi-y
clone: RISCV_PK_BRANCH ?= v1.0.0-ctsi-1
clone:
	git clone --depth 1 --branch $(LINUX_BRANCH) \
		git@github.com:cartesi-corp/linux.git $(LINUX_DIR) || \
		cd $(LINUX_DIR) && git pull
	git clone --depth 1 --branch $(RISCV_PK_BRANCH) \
		git@github.com:cartesi-corp/riscv-pk.git $(RISCV_PK_DIR) || \
		cd $(RISCV_PK_DIR) && git pull

run: IMG=cartesi/toolchain:devel
run:
	$(MAKE) run IMG=$(IMG)

.PHONY: $(RISCV_PK_BUILD_DIR)/Makefile $(LINUX_DIR)/vmlinux $(ARTIFACTS)

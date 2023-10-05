TOOLCHAIN_PREFIX    := riscv64-cartesi-linux-gnu

OPENSBI_DIR        := work/opensbi
OPENSBI_BUILD_DIR  := $(OPENSBI_DIR)/build

LINUX_DIR           := work/linux
LINUX_TEST_DIR      := $(LINUX_DIR)/tools/testing/selftests

JOBS                := -j$(shell nproc)

KERNEL_VERSION      ?= $(shell make -sC $(LINUX_DIR) kernelversion)
KERNEL_TIMESTAMP    ?= $(shell date -Ru)
IMAGE_KERNEL_VERSION?= 0.0.0
HEADERS             := artifacts/linux-headers-$(KERNEL_VERSION)-v$(IMAGE_KERNEL_VERSION).tar.xz
IMAGE               := artifacts/linux-nobbl-$(KERNEL_VERSION)-v$(IMAGE_KERNEL_VERSION).bin
LINUX               := artifacts/linux-$(KERNEL_VERSION)-v$(IMAGE_KERNEL_VERSION).bin
LINUX_ELF           := artifacts/linux-$(KERNEL_VERSION)-v$(IMAGE_KERNEL_VERSION).elf
SELFTEST            := artifacts/linux-selftest-$(KERNEL_VERSION)-v$(IMAGE_KERNEL_VERSION).ext2
CROSS_DEB_FILENAME  := artifacts/linux-libc-dev-riscv64-cross-$(KERNEL_VERSION)-v$(IMAGE_KERNEL_VERSION).deb
NATIVE_DEB_FILENAME := artifacts/linux-libc-dev-$(KERNEL_VERSION)-v$(IMAGE_KERNEL_VERSION).deb
ARTIFACTS           := $(HEADERS) $(IMAGE) $(LINUX) $(SELFTEST)


all: $(ARTIFACTS)

env:
	@echo KBUILD_BUILD_TIMESTAMP=\""$(KERNEL_TIMESTAMP)"\"
	@echo KBUILD_BUILD_USER=dapp
	@echo KBUILD_BUILD_HOST=cartesi

	@echo HEADERS="$(HEADERS)"
	@echo IMAGE="$(IMAGE)"
	@echo LINUX="$(LINUX)"
	@echo LINUX_ELF="$(LINUX_ELF)"
	@echo SELFTEST="$(SELFTEST)"
	@echo CROSS_DEB_FILENAME="$(CROSS_DEB_FILENAME)"
	@echo NATIVE_DEB_FILENAME="$(NATIVE_DEB_FILENAME)"

# build linux
# ------------------------------------------------------------------------------
LINUX_OPTS=$(JOBS) ARCH=riscv CROSS_COMPILE=$(TOOLCHAIN_PREFIX)- KBUILD_BUILD_TIMESTAMP="$(KERNEL_TIMESTAMP)" KBUILD_BUILD_USER=dapp KBUILD_BUILD_HOST=cartesi
$(LINUX_DIR)/vmlinux $(IMAGE) $(HEADERS) &: $(LINUX_DIR)/.config
	mkdir -p artifacts
	$(MAKE) -rC $(LINUX_DIR) $(LINUX_OPTS) olddefconfig
	$(MAKE) -rC $(LINUX_DIR) $(LINUX_OPTS) vmlinux Image
	$(MAKE) -rC $(LINUX_DIR) $(LINUX_OPTS) headers_install \
		INSTALL_HDR_PATH=$(abspath work/linux-headers)
	tar --sort=name --mtime="$(KERNEL_TIMESTAMP)" --owner=1000 --group=1000 --numeric-owner -cJf $(HEADERS) $(abspath work/linux-headers)
	cp work/linux/arch/riscv/boot/Image $(IMAGE)
	cp $(LINUX_DIR)/vmlinux $(LINUX_ELF)

cross-deb:  # TARGET == riscv64
	mkdir -p $(DESTDIR)/DEBIAN
	cat tools/template/cross-control.template | sed 's|ARG_KERNEL_VERSION|$(KERNEL_VERSION)|g' > $(DESTDIR)/DEBIAN/control
	$(MAKE) -rC $(LINUX_DIR) $(LINUX_OPTS) headers_install \
		INSTALL_HDR_PATH=$(abspath $(DESTDIR))/usr/riscv64-linux-gnu
	find $(DESTDIR) -exec touch -d "$(KERNEL_TIMESTAMP)" {} \;
	SOURCE_DATE_EPOCH="1" dpkg-deb -Zxz --root-owner-group --build $(DESTDIR) $(CROSS_DEB_FILENAME)

native-deb: # HOST   == riscv64
	mkdir -p $(DESTDIR)/DEBIAN
	cat tools/template/native-control.template | sed 's|ARG_KERNEL_VERSION|$(KERNEL_VERSION)|g' > $(DESTDIR)/DEBIAN/control
	$(MAKE) -rC $(LINUX_DIR) $(LINUX_OPTS) headers_install \
		INSTALL_HDR_PATH=$(abspath $(DESTDIR))/usr
	find $(DESTDIR) -exec touch -d "$(KERNEL_TIMESTAMP)" {} \;
	SOURCE_DATE_EPOCH="1" dpkg-deb -Zxz --root-owner-group --build $(DESTDIR) $(NATIVE_DEB_FILENAME)

# build linux w/ opensbi
# ------------------------------------------------------------------------------
OPENSBI_OPTS=$(JOBS) FW_PAYLOAD_PATH=$(abspath $(IMAGE)) PLATFORM=cartesi CROSS_COMPILE=$(TOOLCHAIN_PREFIX)-
$(LINUX): $(IMAGE)
	@mkdir -p artifacts
	$(MAKE) -rC $(OPENSBI_DIR) $(OPENSBI_OPTS)
	@cp $(OPENSBI_BUILD_DIR)/platform/cartesi/firmware/fw_payload.bin $@

# build linux tests
# ------------------------------------------------------------------------------
TAR := $(shell mktemp)

$(SELFTEST):
	mkdir -p artifacts
	$(MAKE) $(JOBS) -rC $(LINUX_TEST_DIR) $(LINUX_OPTS) \
		TARGETS=drivers/cartesi install
	tar --sort=name --mtime="$(KERNEL_TIMESTAMP)" --owner=1000 --group=1000 --numeric-owner -cf $(TAR) --directory=$(LINUX_TEST_DIR)/kselftest_install .
	genext2fs -f -i 4096 -b 1024 -a $(TAR) $@
	rm $(TAR)

clean:
	$(MAKE) -rC $(LINUX_DIR) $(LINUX_OPTS) clean
	$(MAKE) $(JOBS) -rC $(OPENSBI_DIR) clean
	@rm -rf $(OPENSBI_BUILD_DIR)

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
clone: LINUX_BRANCH ?= linux-5.15.63-ctsi-y
clone: OPENSBI_BRANCH ?= opensbi-1.2-ctsi-y
clone:
	git clone --depth 1 --branch $(LINUX_BRANCH) \
		git@github.com:cartesi/linux.git $(LINUX_DIR) || \
		cd $(LINUX_DIR) && git pull
	git clone --depth 1 --branch $(OPENSBI_BRANCH) \
		git@github.com:cartesi/opensbi.git $(OPENSBI_DIR) || \
		cd $(OPENSBI_DIR) && git pull

run: IMG=cartesi/toolchain:devel
run:
	$(MAKE) run IMG=$(IMG)

.PHONY: $(OPENSBI_BUILD_DIR)/Makefile $(LINUX_DIR)/vmlinux $(ARTIFACTS)

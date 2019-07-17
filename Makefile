.PHONY: all build push run pull share copy

TAG ?= latest
TOOLCHAIN_TAG ?=

IMG:=cartesi/image-kernel:$(TAG)
BASE:=/opt/riscv
ART:=$(BASE)/kernel.bin

ifneq ($(TOOLCHAIN_TAG),)
BUILD_ARGS := --build-arg TOOLCHAIN_VERSION=$(TOOLCHAIN_TAG)
endif

all: copy

build:
	docker build -t $(IMG) $(BUILD_ARGS) .

push:
	docker push $(IMG)

pull:
	docker pull $(IMG)

run:
	docker run -it --rm $(IMG)

share:
	docker run -it --rm -v `pwd`:$(BASE)/host $(IMG)

copy: build
	ID=`docker create $(IMG)` && docker cp $$ID:$(ART) . && docker rm -v $$ID

.PHONY: build push run share

IMG:=cartesi/image-kernel
BASE:=/opt/riscv
ART:=$(BASE)/kernel.bin

build:
	docker build -t $(IMG) .

push: build
	docker push $(IMG)

run: build
	docker run -it --rm $(IMG)

share:
	docker run -it --rm -v `pwd`:$(BASE)/host $(IMG)

copy: build
	ID=`docker create $(IMG)` && docker cp $$ID:$(ART) . && docker rm -v $$ID

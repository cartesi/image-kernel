.PHONY: build push run share

IMG:=cartesi/image-kernel
BASE:=/opt/riscv
ART:=$(BASE)/kernel.bin

build:
	docker build -t $(IMG) .

push: build
	docker push $(IMG)

pull:
	docker pull $(IMG)

run:
	docker run -it --rm $(IMG)

share:
	docker run -it --rm -v `pwd`:$(BASE)/host $(IMG)

copy: build
	ID=`docker create $(IMG)` && docker cp $$ID:$(ART) . && docker rm -v $$ID

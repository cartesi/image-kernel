.PHONY: build push run share

build:
	docker build -t cartesi/image-kernel:latest .

push:
	docker push cartesi/image-kernel:latest

run:
	docker run -it --rm cartesi/image-kernel:latest

share:
	docker run -it --rm -v `pwd`:/opt/riscv/host cartesi/image-kernel:latest

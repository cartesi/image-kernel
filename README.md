> :warning: The Cartesi team keeps working internally on the next version of this repository, following its regular development roadmap. Whenever there's a new version ready or important fix, these are published to the public source tree as new releases.

# Cartesi Machine Image Kernel 

The Cartesi Image Kernel is the repository that provides the Docker configuration files to build the `kernel.bin` testing Linux kernel. This is used to run a Linux environment on the Cartesi Machine Emulator reference implementation. The current image is based on the `cartesi/toolchain` that uses Ubuntu 18.04 and GNU GCC 8.3.0. The `kernel.bin` is built from the Linux 4.20.x source, targeting the RISC-V RV64IMA with ABI LP64 architecture.

## Getting Started

### Requirements

- Docker 18.x
- GNU Make >= 3.81

### Build

```bash
$ make build
```

If you want to tag the image with custom name you can do the following:

```bash
$ make build TAG=mytag
```

To remove the generated images from your system, please refer to the Docker documentation.

#### Makefile targets

The following options are available as `make` targets:

- **build**: builds the docker image-kernel image
- **copy**: builds the imgae-kernel image and copy it's artifact to the host 
- **run**: runs the generated image with current user UID and GID
- **run-as-root**: runs the generated image as root
- **push**: pushes the image to the registry repository

#### Makefile container options

You can pass the following variables to the make target if you wish to use different docker image tags.

- TAG: image-roofs image tag
- TOOLCHAIN\_TAG: toolchain image tag

```
$ make build TAG=mytag
$ make build TOOLCHAIN_TAG=mytag
```

It's also useful if you want to use pre-built images:

```
$ make run TAG=latest
```

## Usage

The purpose of this image is to build the `kernel.bin` artifact so it can be used with the emulator. For instructions on how to do that, please see the emulator documentation.

If you want to play around on the environment you can also do:

```
$ make run
```

## Contributing

Thank you for your interest in Cartesi! Head over to our [Contributing Guidelines](CONTRIBUTING.md) for instructions on how to sign our Contributors Agreement and get started with Cartesi!

Please note we have a [Code of Conduct](CODE_OF_CONDUCT.md), please follow it in all your interactions with the project.

## Authors

* *Diego Nehab*
* *Victor Fusco*

## License

The image-kernel repository and all contributions are licensed under
[APACHE 2.0](https://www.apache.org/licenses/LICENSE-2.0). Please review our [LICENSE](LICENSE) file.



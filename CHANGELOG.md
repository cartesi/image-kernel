# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.17.0] - 2023-08-14
### Added
- Added support for building ARM64 images with depot.dev

### Changed
- Make kernel build timestamp deterministic
- Updated license/copyright notice in all source code
- Updated CI downloads to public infrastructure
- Updated CI actions versions
- Added deb generation and upload to CI as artifact
- Updated toolchain to v0.15.0

## [0.16.0] - 2023-03-30
### Changed
- Updated Linux Kernel to v5.15.63-ctsi-2
- Updated toolchain to v0.14.0

## [0.15.0] - 2023-02-10
### Changed
- Tuned default kernel config for faster boot time
- Updated toolchain to v0.13.0
- Enabled compressed instructions (RISC-V C extension)

## [0.14.0] - 2022-11-17
### Changed
- Enabled floating-point unit by default
- Updated Linux Kernel to v5.15.63-ctsi-1
- Updated toolchain to v0.12.0

## [0.13.0] - 2022-08-29
### Changed
- Added cache to docker build and push on CI
- Updated Linux Kernel to v5.5.19-ctsi-6
- Updated toolchain version to v0.11.0

## [0.12.0] - 2022-07-04
### Changed
- Updated toolchain version to v0.10.0
- Use sources from the same organization on CI
- Publish nobbl, selftests, headers
- Remove cartesi-logo.txt from bbl

## [0.11.0] - 2022-04-20
### Changed
- Updated Linux Kernel to v5.5.19-ctsi-5
- Updated toolchain version to v0.9.0

## [0.10.0] - 2022-03-04
### Added
- Added support to boot on QEMU and Tinyemu
- Make new kernel artifact without BBL
- Enabled PLIC on debug config

### Changed
- Updated toolchain version to v0.8.0
- Updated Linux Kernel to v5.5.19-ctsi-4

## [0.9.0] - 2021-12-17
### Changed
- Updated toolchain version to v0.7.0
- Updated Linux Kernel to v5.5.19-ctsi-3

## [Previous Versions]
- [0.8.0]
- [0.7.0]
- [0.6.0]
- [0.5.0]
- [0.4.0]
- [0.3.0]
- [0.2.0]
- [0.1.0]

[Unreleased]: https://github.com/cartesi/image-kernel/compare/v0.17.0...HEAD
[0.17.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.17.0
[0.16.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.16.0
[0.15.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.15.0
[0.14.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.14.0
[0.13.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.13.0
[0.12.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.12.0
[0.11.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.11.0
[0.10.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.10.0
[0.9.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.9.0
[0.8.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.8.0
[0.7.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.7.0
[0.6.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.6.0
[0.5.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.5.0
[0.4.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.4.0
[0.3.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.3.0
[0.2.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.2.0
[0.1.0]: https://github.com/cartesi/image-kernel/releases/tag/v0.1.0

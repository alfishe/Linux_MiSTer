# Linux_MiSTer
Helper package to build Linux kernel easily on Mac OS X (El Capitan and Sierra tested)

__/kernel__ - subfolder is a submodule, pointing to repository https://github.com/MiSTer-devel/Linux-Kernel_4.5.0_MiSTer

## Usage

1. Ensure [Homebrew](https://brew.sh/) is installed.
2. ```brew install gnu-sed gawk binutils gperf grep gettext ncurses pkgconfig lz4```
3. ./build.sh

Resulting artifacts will appear in __/deploy__ folder

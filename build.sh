#!/bin/bash

# Increase system resources limit
sudo sysctl -w kern.maxproc=2048
sudo sysctl -w kern.maxprocperuid=1024
sudo launchctl limit maxfiles 2048 unlimited
sudo ulimit -u 1024 # User processes
sudo ulimit -n 4096 # Opened files

export PATH="/Volumes/SLData/ARM/arm-cortex_a9-linux-gnueabihf/bin:$PATH"
export CROSS_COMPILE=arm-cortex_a9-linux-gnueabihf-
export CCPREFIX=arm-cortex_a9-linux-gnueabihf-
export ARCH=arm
export SUBARCH=arm
export LOCALVERSION=-socfpga-r1

# Mac OS X specifics
# brew install gnu-sed gawk binutils gperf grep gettext ncurses pkgconfig lz4
#export LIBRARY_PATH="/usr/local/opt/ncurses/lib:/usr/local/opt/gettext/lib:/usr/local/opt/libelf/lib:$LIBRARY_PATH";
#export LD_LIBRARY_PATH="/usr/local/opt/ncurses/lib:/usr/local/opt/gettext/lib:/usr/local/opt/libelf/lib:$LD_LIBRARY_PATH";
#export PKG_CONFIG_PATH="/usr/local/opt/ncurses/lib/pkgconfig:$PKG_CONFIG_PATH";
#export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:/usr/local/opt/ncurses/bin:$PATH";
export CPATH="/usr/local/opt/ncurses/lib:/usr/local/opt/gettext/include:/usr/local/opt/libelf/include/libelf:$CPATH";

cp include/* /usr/local/include/
cp -R patches/* kernel/


# Assuming that following folder structure is created on disk
# /kernel - subfolder with Linux source package
# .build.sh - this script

DIR=$PWD

mkdir -p "${DIR}/deploy"


make_pkg ()
{
	cd "${DIR}/kernel" || exit

	deployfile="${pkg}.tar.gz"
	tar_options="--create --gzip --file"

	if [ -f "${DIR}/deploy/${deployfile}" ] ; then
		rm -rf "${DIR}/deploy/${deployfile}" || true
	fi

	if [ -d "${DIR}/deploy/tmp" ] ; then
		rm -rf "${DIR}/deploy/tmp" || true
	fi
	mkdir -p "${DIR}/deploy/tmp"

	echo "-----------------------------"
	echo "Building ${pkg} archive..."

	case "${pkg}" in
	modules)
		make ARCH=${ARCH} -s modules_install INSTALL_MOD_PATH="${DIR}/deploy/tmp"
		unlink ${DIR}/deploy/tmp/lib/modules/*/build
		unlink ${DIR}/deploy/tmp/lib/modules/*/source
		;;
	firmware)
		make ARCH=${ARCH} -s firmware_install INSTALL_FW_PATH="${DIR}/deploy/tmp"
		;;
	esac

	echo "Compressing ${deployfile}..."
	cd "${DIR}/deploy/tmp" || true
	tar ${tar_options} "../${deployfile}" ./*

	cd "${DIR}/" || exit
	rm -rf "${DIR}/deploy/tmp" || true

	if [ ! -f "${DIR}/deploy/${deployfile}" ] ; then
		echo "File Generation Failure: [${deployfile}]"
		exit 1
	else
		ls -lh "${DIR}/deploy/${deployfile}"
	fi
}

make_modules_pkg ()
{
	pkg="modules"
	make_pkg
}

make_firmware_pkg ()
{
	pkg="firmware"
	make_pkg
}

if [ ! -f "${DIR}/kernel/.config" ]; then
	make ARCH=${ARCH} -C "${DIR}/kernel" distclean
	make ARCH=${ARCH} -C "${DIR}/kernel" de10-nano_minimal_defconfig || exit 0
fi

make ARCH=${ARCH} -C "${DIR}/kernel" menuconfig || exit 0
make ARCH=${ARCH} -C "${DIR}/kernel" -j4 zImage modules dtbs || exit 0
cp -f "${DIR}/kernel/arch/${ARCH}/boot/zImage" "${DIR}/deploy/zImage" || exit 0
chmod a-x "${DIR}/deploy/zImage" || exit 0
cp -f "${DIR}/kernel/arch/${ARCH}/boot/dts/socfpga_cyclone5_de10_sockit.dtb" "${DIR}/deploy/socfpga.dtb" || exit 0

make_modules_pkg
make_firmware_pkg
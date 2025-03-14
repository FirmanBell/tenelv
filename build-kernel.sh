#!/usr/bin/env bash
# Copyright (C) 2020-2021 IceCreamGang
# Configured for MI 8 Lite a.k.a platina
# Simple Local Kernel Build Script

# Clone Clang
if ! [ -d "$PWD/clang" ]; then
    git clone https://github.com/kdrag0n/proton-clang.git -b master --depth=1 clang
else
    echo "clang folder is exist, not cloning"
fi

# Clone GCC64
if ! [ -d "$PWD/gcc64" ]; then
    git clone https://github.com/mvaisakh/gcc-arm64.git -b gcc-master --depth=1 gcc64
else
    echo "gcc64 folder is exist, not cloning"
fi

# Clone GCC32
if ! [ -d "$PWD/gcc32" ]; then
    git clone https://github.com/mvaisakh/gcc-arm.git -b gcc-master --depth=1 gcc32
else
    echo "gcc32 folder is exist, not cloning"
fi

# Clone AnyKernel3
if ! [ -d "$PWD/AnyKernel3" ]; then
    git clone https://github.com/1cecreamm/AnyKernel3.git -b master --depth=1 AnyKernel3
else
    echo "AnyKernel3 folder is exist, not cloning"
fi

# Main Environment
date=`date +"%Y%m%d-%H%M"`
BUILD_START=$(date +"%s")
KERNEL_DIR=$PWD
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
ZIP_DIR=$KERNEL_DIR/AnyKernel3
CONFIG_DIR=$KERNEL_DIR/arch/arm64/configs
CONFIG=platina_defconfig
CORES=$(grep -c ^processor /proc/cpuinfo)
THREAD="-j$CORES"

# Export
export FILENAME="Morph-Aurora-LTO-$(date "+%Y%m%d-%H%M").zip"
export KERNEL_USE_CCACHE=1
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE
export CROSS_COMPILE="$KERNEL_DIR/gcc64/bin/aarch64-elf-"
export CROSS_COMPILE_ARM32="$KERNEL_DIR/gcc32/bin/arm-eabi-"
export KBUILD_BUILD_USER="morph"
export KBUILD_BUILD_HOST="icecreamgang"

# Mkdir
if ! [ -d "$KERNEL_DIR/out" ]; then
    mkdir -p $KERNEL_DIR/out
else
    echo "Out folder is exist, not Make"
fi

# Start building the kernel
make  O=out $CONFIG $THREAD &>/dev/null
make  O=out $THREAD & pid=$!
spin[0]="-"
spin[1]="\\"
spin[2]="|"
spin[3]="/"
while kill -0 $pid &>/dev/null
do
	for i in "${spin[@]}"
	do
		echo -ne "\b$i"
		sleep 0.1
	done
done

if ! [ -a $KERN_IMG ]; then
	echo -e "\n(!)Build error, please fix the issue"
	exit 1
fi

[[ -z ${ZIP_DIR} ]] && { exit; }

# Compress to zip file
cp out/arch/arm64/boot/Image.gz-dtb $PWD/AnyKernel3
    cd $PWD/AnyKernel3
    zip -r9 $FILENAME *
    cd $KERNEL_DIR/
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
curl -s -X POST "https://api.telegram.org/bot1652915112:AAEkFfIHUYgaC9n1KORuVVwCcuJo99j-_uM/sendMessage" \
            -d chat_id="-1001304512334" \
            -d "disable_web_page_preview=true" \
            -d "parse_mode=markdown" \
            -d text="=================================
⚙️ Build kernel for Platina started . . .

MM   MM     MM    MM      MMM  M   M
M M M M   M    M  M    M  M    M MMM
M   M    M   M    M  MMM  MMM  MMM
M          M     MM    M     M M         M   M

=================================
Android: 10/11
Compiler: GCC 12.x with LTO
Version: Universal
Device: Platina (MI 8 Lite)
Kernel: 4.4.x
Status: Stable"
curl -F caption="✅Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds" -F document=@"$ZIP_DIR/$FILENAME" https://api.telegram.org/bot1652915112:AAEkFfIHUYgaC9n1KORuVVwCcuJo99j-_uM/sendDocument?chat_id=-1001304512334
    rm -rf $PWD/AnyKernel3/Image.gz-dtb
    rm -rf $PWD/AnyKernel3/$FILENAME
    rm -rf $PWD/out

# Build Complete
echo -e "Kernel build complete"

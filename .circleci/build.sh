#!/usr/bin/env bash
# Copyright (C) 2020 Saalim Quadri (iamsaalim)
# SPDX-License-Identifier: GPL-3.0-or-later

cd $HOME
echo -e "machine github.com\n  login $GITHUB_TOKEN" > ~/.netrc
echo "Cloning dependencies"
git clone --depth=1 https://github.com/stormbreaker-project/violet -b ten kernel
cd kernel
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 clang
git clone --depth=1 https://github.com/stormbreaker-project/aarch64-linux-android-4.9 gcc
git clone --depth=1 https://github.com/stormbreaker-project/arm-linux-androideabi-4.9 gcc32
echo "Done"
export kernelzip="$HOME/AnyKernel3"
git clone --depth=1 https://github.com/stormbreaker-project/AnyKernel3 -b violet $kernelzip
export IMAGE="$HOME/kernel/out/arch/arm64/boot/Image.gz-dtb"
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
export CONFIG_PATH=$PWD/arch/arm64/configs/vendor/lineage_violet_defconfig
PATH="${PWD}/clang/bin:${PWD}/gcc/bin:${PWD}/gcc32/bin:${PATH}"
export ARCH=arm64
export KBUILD_BUILD_HOST="circleci"
export KBUILD_BUILD_USER="saalim"

# Send info to channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="Kernel build for violet started"
}

# Push kernel to channel
function push() {
    cd $kernelzip
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)"
}

# spam Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}

# Compile
function compile() {
    make O=out ARCH=arm64 vendor/lineage_violet_defconfig
    make -j$(nproc --all) O=out \
                             ARCH=arm64 \
			     CC=clang \
			     CLANG_TRIPLE=aarch64-linux-gnu- \
			     CROSS_COMPILE=aarch64-linux-android- \
			     CROSS_COMPILE_ARM32=arm-linux-androideabi-
}

# Zipping
function zip() {
    cd $kernelzip
    cp $IMAGE $kernelzip/
    make normal
    cd ..
}

# Generate dtbo
function dtbo() {

KERNEL_DIR="$HOME/kernel"
    cd $KERNEL_DIR
    git clone https://android.googlesource.com/platform/system/libufdt "$KERNEL_DIR"/scripts/ufdt/libufdt
    python scripts/ufdt/libufdt/utils/src/mkdtboimg.py create $kernelzip/dtbo.img --page_size=4096 out/arch/arm64/boot/dts/xiaomi/violet-sm6150-overlay.dtbo
}

sendinfo
compile
dtbo
zip
finerr
END=$(date +"%s")
DIFF=$(($END - $START))
push

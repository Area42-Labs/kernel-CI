#!/usr/bin/env bash
# Copyright (C) 2020 Saalim Quadri (iamsaalim)
# SPDX-License-Identifier: GPL-3.0-or-later

cd $HOME
echo "Cloning dependencies"
git clone --depth=1 https://github.com/asusdevices/android_kernel_asus_msm8937 -b lineage-17.1 kernel
cd kernel
git clone --depth=1 https://github.com/stormbreaker-project/aarch64-linux-android-4.9 gcc
echo "Done"
export kernelzip="$HOME/AnyKernel3"
git clone --depth=1 https://github.com/stormbreaker-project/AnyKernel3 -b X00P $kernelzip
export IMAGE="$HOME/kernel/out/arch/arm64/boot/Image.gz-dtb"
GCC="$HOME/kernel/gcc/bin/aarch64-linux-android-"
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
export CONFIG_PATH=$PWD/arch/arm64/configs/X00P_defconfig
PATH="${PWD}/gcc/bin:${PATH}"
export ARCH=arm64
export KBUILD_BUILD_HOST=hetzner
export KBUILD_BUILD_USER="saalim"

# Send info to channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• Kernel •</b>%0ABuild started on <code>Circle CI/CD</code>%0AFor device <b>Zenfone Max M1</b> (X00P)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b> #Test"
}

# Push kernel to channel
function push() {
    cd $kernelzip
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Zenfone Max M1 (X00P)</b> | <b>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</b>"
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
    make O=out ARCH=arm64 X00P_defconfig
    make -j$(nproc --all) O=out \
                             ARCH=arm64 \
			     CROSS_COMPILE=aarch64-linux-android-
}

# Zipping
function zip() {
    cd $kernelzip
    cp $IMAGE $kernelzip/
    make normal
    cd ..
}

sendinfo
compile
zip
END=$(date +"%s")
DIFF=$(($END - $START))
push

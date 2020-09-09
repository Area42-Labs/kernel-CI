#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/sreekfreak995/kranul.git -b eas-old-cam  kernel
cd kernel
git clone https://github.com/arter97/arm64-gcc --depth=1
git clone https://github.com/arter97/arm32-gcc --depth=1
git clone --depth=1 https://github.com/sreekfreak995/AnyKernel3.git AnyKernel
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
export CONFIG_PATH=$PWD/arch/arm64/configs/whyred-perf_defconfig
PATH="$(pwd)/arm64-gcc/bin:$(pwd)/arm32-gcc/bin:${PATH}" \
export ARCH=arm64
export USE_CCACHE=1
export KBUILD_BUILD_HOST=circleci
export KBUILD_BUILD_USER="Sreekanth"
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgUAAxkBAAJi017AAw5j25_B3m8IP-iy98ffcGHZAAJAAgACeV4XIusNfRHZD3hnGQQ" \
        -d chat_id=$chat_id
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• Stormbreaker Kernel •</b>%0ABuild started on <code>Circle CI</code>%0AFor device <b>Xiaomi Redmi Note5/5Pro</b> (whyred)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b>#Stable"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Xiaomi Redmi Note 5/5Pro (whyred)</b> | <b>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {
   make O=out ARCH=arm64 whyred-perf_defconfig
     PATH="$(pwd)/arm64-gcc/bin:$(pwd)/arm32-gcc/bin:${PATH}" \
       make -j$(nproc --all) O=out \
                             ARCH=arm64 \
                             CROSS_COMPILE=aarch64-elf- \
                             CROSS_COMPILE_ARM32=arm-eabi-
   cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 Stormbreaker-whyred-${TANGGAL}.zip *
    curl https://bashupload.com/Stormbreaker-whyred-${TANGGAL}.zip --data-binary @Stormbreaker-whyred-${TANGGAL}.zip
    cd ..
}
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
sticker

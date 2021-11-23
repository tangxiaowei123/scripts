#!/bin/bash

set -e

source $(dirname "$0")/helper

cmdline="$(basename "$0")"

if [ $# -lt 1 ]; then
    info "使用方法: bash ./$(dirname "$0")/$cmdline <版本号>" 1>&2
    info "检测到未输入ROM<版本号>，将以默认版本构建..." 1>&2
else
    export CUSTOM_ROM_VERSION=${1}
    info "检测到自定义ROM版本号为 $CUSTOM_ROM_VERSION " 1>&2
fi

export LC_ALL=C

# Initialize local repository
function init_local_repo() {
    info "正在拷贝local_manifest.xml到.repo目录... "
    mkdir -p .repo/local_manifests
    cp "$(dirname "$0")/local_manifest.xml" .repo/local_manifests/manifest.xml
}

# Initialize cuzPixel repository
function init_main_repo() {
    info "正在初始化主仓库源... "
    repo init -u https://github.com/aosp-davinci/android_manifest.git -b 12.0 --depth=1
}

function sync_repo() {
    info "正在同步仓库源码中... "
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
}

function envsetup() {
    . build/envsetup.sh
    lunch aosp_davinci-userdebug
    mka installclean
	#rm -rf $OUT/obj/KERNEL_OBJ/arch/arm64/boot/dts/xiaomi/
}

function buildbacon() {
    mka bacon -j16
	#mka vintf -j16
}

## handle sync command line arguments
read -p "是否同步仓库源码? (y/N) " choice_sync

if [[ $choice_sync == *"y"* ]]; then
    init_local_repo
    init_main_repo
    sync_repo
    success "最新源码同步完成！" 1>&2
    success "开始构建系统... " 1>&2
else
    success "开始构建系统... " 1>&2
fi

envsetup

buildbacon

info ">>> 系统构建完成 <<< "

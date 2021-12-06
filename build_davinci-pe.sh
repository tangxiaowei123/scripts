#!/bin/bash

set -e

source $(dirname "$0")/helper

export LC_ALL=C

# Initialize local repository
function init_local_repo() {
    info "正在拷贝local_manifest-pe.xml到.repo目录... "
    mkdir -p .repo/local_manifests
    cp "$(dirname "$0")/local_manifest-pe.xml" .repo/local_manifests/manifest.xml
}

# Initialize cuzPixel repository
function init_main_repo() {
    info "正在初始化主仓库源... "
    repo init -u https://github.com/PixelExperience/manifest -b twelve --depth=1
}

function sync_repo() {
    info "正在同步仓库源码中... "
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
}

function apply_patches() {
    info "正在进行额外修补..."
    bash "$(dirname "$0")/apply-patches.sh" patches
}

function envsetup() {
    info "正在配置构建环境..."
    . build/envsetup.sh
    
    info "正在调用编译设备..."
    lunch aosp_davinci-userdebug
    
    info "正在清理前期编译..."
    mka installclean
    
    #info "正在清理内核DTS..."
    #rm -rf $OUT/obj/KERNEL_OBJ/arch/arm64/boot/dts/xiaomi/
}

function buildbacon() {
    info "开始构建系统... "
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
    apply_patches
fi

envsetup

buildbacon

info ">>> 系统构建完成 <<< "

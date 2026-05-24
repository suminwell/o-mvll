#!/usr/bin/env bash

#
# This file is distributed under the Apache License v2.0. See LICENSE for details.
#

# This script is used to compile the Android NDK r29 LLVM toolchain.

set -euo pipefail

host=$(uname)

NDK_VERSION=29.0.13113456

if [ "$host" = "Darwin" ]; then
    ndk_platform="darwin-x86_64"
else
    ndk_platform="linux-x86_64"
fi

ndk_prebuilt_dir="$ANDROID_HOME/ndk/$NDK_VERSION/toolchains/llvm/prebuilt/$ndk_platform"
manifest_path=$(ls "$ndk_prebuilt_dir"/manifest_*.xml 2>/dev/null | head -n 1 || true)
if [ -z "$manifest_path" ]; then
    echo "Unable to find NDK LLVM manifest in $ndk_prebuilt_dir"
    find "$ndk_prebuilt_dir" -maxdepth 1 -type f -print || true
    exit 1
fi
manifest=$(basename "$manifest_path")

mkdir -p omvll-deps
rm -rf android-llvm-toolchain-r29-tmp android-llvm-toolchain-r29
mkdir android-llvm-toolchain-r29-tmp
cd android-llvm-toolchain-r29-tmp

repo init -u https://android.googlesource.com/platform/manifest -b llvm-toolchain
cp "$manifest_path" .repo/manifests/
repo init -m "$manifest"
repo sync -c

python3 toolchain/llvm_android/build.py --skip-tests

export NDK_STAGE1=$(pwd)/out/stage1-install
export NDK_STAGE2=$(pwd)/out/stage2-install

zero_out() {
    local BIN_DIR="$1"

    local KEEP_BINARIES=("clang-21" "clang" "clang++" "clang-cpp" "clang-cl" "clang-extdef-mapping" "clang-format"
                         "clang-nvlink-wrapper" "clang-offload-bundler" "clang-offload-wrapper"
                         "git-clang-format" "hmaptool" "llvm-config" "llvm-link" "llvm-lit"
                         "llvm-tblgen" "FileCheck" "count" "not"
                         "amdgpu-arch" "clangd" "find-all-symbols" "ld.lld" "ld64.lld" "llc" "lld"
                         "lld-link" "lldb" "lldb-argdumper" "lldb-instr" "lldb-server" "lldb-vscode"
                         "lli" "modularize" "nvptx-arch" "opt" "pp-trace" "run-clang-tidy" "sancov"
                         "sanstats" "verify-uselistorder" "wasm-ld")

    for file in "$BIN_DIR"/*; do
        if [[ ! " ${KEEP_BINARIES[*]} " =~ " $(basename "$file") " ]]; then
            echo "Zeroing out $file"
            : > "$file"
        fi
    done
}

zero_out "$NDK_STAGE1/bin"
zero_out "$NDK_STAGE2/bin"

cd ..
mkdir -p android-llvm-toolchain-r29/out
cd android-llvm-toolchain-r29/out
cp -r "$NDK_STAGE1" .
cp -r "$NDK_STAGE2" .
mv ./stage2-install stage2

tar czf stage1-install.tar.gz stage1-install && rm -rf stage1-install
tar czf stage2.tar.gz stage2 && rm -rf stage2
cd .. && tar czf out.tar.gz out && rm -rf out
cd .. && tar czf android-llvm-toolchain-r29.tar.gz android-llvm-toolchain-r29

rm -rf android-llvm-toolchain-r29 android-llvm-toolchain-r29-tmp
mv android-llvm-toolchain-r29.tar.gz ./omvll-deps/

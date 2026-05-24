#!/usr/bin/env bash

#
# This file is distributed under the Apache License v2.0. See LICENSE for details.
#

set -ex

DATA_DIR=${DATA_DIR:-/data}
if ! mkdir -p "$DATA_DIR" 2>/dev/null; then
  DATA_DIR=$(mktemp -d)
fi
cd "$DATA_DIR"

THIRD_PARTY_DIR=${THIRD_PARTY_DIR:-/third-party}
O_MVLL_ROOT=${O_MVLL_ROOT:-/o-mvll}
if [ ! -d "$O_MVLL_ROOT/src" ]; then
  O_MVLL_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
fi

cp "$THIRD_PARTY_DIR"/omvll-deps-ndk-*/Python-slim.tar.gz .
cp "$THIRD_PARTY_DIR"/omvll-deps-ndk-*/pybind11.tar.gz .
cp "$THIRD_PARTY_DIR"/omvll-deps-ndk-*/spdlog-1.10.0-Linux.tar.gz .
tar xzvf Python-slim.tar.gz
tar xzvf pybind11.tar.gz
tar xzvf spdlog-1.10.0-Linux.tar.gz

export NDK_STAGE1=/usr/lib/llvm-21
export NDK_STAGE2=/usr/lib/llvm-21

mkdir -p /test-deps/bin
cp ${NDK_STAGE2}/bin/clang /test-deps/bin
cp ${NDK_STAGE2}/bin/clang++ /test-deps/bin
if [ -f ${NDK_STAGE2}/bin/llvm-lit ]; then
  cp ${NDK_STAGE2}/bin/llvm-lit /test-deps/bin
fi

cd "$O_MVLL_ROOT/src"
mkdir -p o-mvll-build_ndk_r29
cd o-mvll-build_ndk_r29

cmake -GNinja .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_COMPILER=${NDK_STAGE1}/bin/clang++ \
      -DCMAKE_C_COMPILER=${NDK_STAGE1}/bin/clang \
      -DCMAKE_CXX_FLAGS="-stdlib=libc++" \
      -DPython3_ROOT_DIR=/data/Python-slim \
      -DPython3_LIBRARY=/data/Python-slim/lib/libpython3.10.a \
      -DPython3_INCLUDE_DIR=/data/Python-slim/include/python3.10 \
      -Dpybind11_DIR=/data/pybind11/share/cmake/pybind11 \
      -Dspdlog_DIR=/data/spdlog-1.10.0-Linux/lib/cmake/spdlog \
      -DLLVM_DIR=${NDK_STAGE2}/lib/cmake/llvm \
      -DLLVM_TOOLS_DIR=/test-deps \
      -DLLVM_REQUIRED_VERSION=21 \
      -DOMVLL_ABI=CustomAndroid

ninja

mkdir -p "$O_MVLL_ROOT/dist"
cp "$O_MVLL_ROOT/src/o-mvll-build_ndk_r29/libOMVLL.so" "$O_MVLL_ROOT/dist/omvll-ndk-r29.so"

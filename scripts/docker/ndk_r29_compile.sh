#!/usr/bin/env bash

#
# This file is distributed under the Apache License v2.0. See LICENSE for details.
#

set -ex

if [ -z "${ANDROID_NDK_ROOT:-}" ]; then
  echo "ANDROID_NDK_ROOT is required"
  exit 1
fi

mkdir -p /data
cd /data

cp /third-party/omvll-deps-ndk-*/Python-slim.tar.gz .
cp /third-party/omvll-deps-ndk-*/pybind11.tar.gz .
cp /third-party/omvll-deps-ndk-*/spdlog-1.10.0-Linux.tar.gz .

tar xzvf Python-slim.tar.gz
tar xzvf pybind11.tar.gz
tar xzvf spdlog-1.10.0-Linux.tar.gz

export NDK_TOOLCHAIN=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64

mkdir -p /test-deps/bin
cp ${NDK_TOOLCHAIN}/bin/clang /test-deps/bin
cp ${NDK_TOOLCHAIN}/bin/clang++ /test-deps/bin
if [ -f ${NDK_TOOLCHAIN}/bin/llvm-lit ]; then
  cp ${NDK_TOOLCHAIN}/bin/llvm-lit /test-deps/bin
fi

cd /o-mvll/src
mkdir -p o-mvll-build_ndk_r29
cd o-mvll-build_ndk_r29

cmake -GNinja .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_COMPILER=${NDK_TOOLCHAIN}/bin/clang++ \
      -DCMAKE_C_COMPILER=${NDK_TOOLCHAIN}/bin/clang \
      -DCMAKE_CXX_FLAGS="-stdlib=libc++" \
      -DPython3_ROOT_DIR=/data/Python-slim \
      -DPython3_LIBRARY=/data/Python-slim/lib/libpython3.10.a \
      -DPython3_INCLUDE_DIR=/data/Python-slim/include/python3.10 \
      -Dpybind11_DIR=/data/pybind11/share/cmake/pybind11 \
      -Dspdlog_DIR=/data/spdlog-1.10.0-Linux/lib/cmake/spdlog \
      -DLLVM_DIR=${NDK_TOOLCHAIN}/lib/cmake/llvm \
      -DLLVM_TOOLS_DIR=/test-deps \
      -DLLVM_REQUIRED_VERSION=21 \
      -DOMVLL_ABI=CustomAndroid

ninja

mkdir -p /o-mvll/dist
cp /o-mvll/src/o-mvll-build_ndk_r29/libOMVLL.so /o-mvll/dist/omvll-ndk-r29.so

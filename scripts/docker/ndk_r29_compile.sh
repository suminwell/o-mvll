#!/usr/bin/env bash

#
# This file is distributed under the Apache License v2.0. See LICENSE for details.
#

set -ex

mkdir -p /data
cd /data

cp /third-party/omvll-deps-ndk-*/Python-slim.tar.gz .
cp /third-party/omvll-deps-ndk-*/pybind11.tar.gz .
cp /third-party/omvll-deps-ndk-*/spdlog-1.10.0-Linux.tar.gz .
tar xzvf Python-slim.tar.gz
tar xzvf pybind11.tar.gz
tar xzvf spdlog-1.10.0-Linux.tar.gz

export NDK_STAGE1=/usr/lib/llvm-21
export NDK_STAGE2=/usr/lib/llvm-21
export LD_LIBRARY_PATH=/llvm21-lib:${LD_LIBRARY_PATH:-}

mkdir -p /test-deps/bin
cp ${NDK_STAGE2}/bin/clang /test-deps/bin
cp ${NDK_STAGE2}/bin/clang++ /test-deps/bin
if [ -f ${NDK_STAGE2}/bin/llvm-lit ]; then
  cp ${NDK_STAGE2}/bin/llvm-lit /test-deps/bin
fi

cd /o-mvll/src
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

mkdir -p /o-mvll/dist
cp /o-mvll/src/o-mvll-build_ndk_r29/libOMVLL.so /o-mvll/dist/omvll-ndk-r29.so

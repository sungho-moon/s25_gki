#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
out=${OUT_DIR:-"$root/out/r21"}
jobs=${JOBS:-$(nproc)}

mkdir -p "$out"
cp "$root/configs/r7-6.6.152-r21.config" "$out/.config"
make -C "$root" O="$out" ARCH=arm64 LLVM=1 LLVM_IAS=1 olddefconfig
make -C "$root" O="$out" ARCH=arm64 LLVM=1 LLVM_IAS=1 -j"$jobs" Image

sha256sum "$out/arch/arm64/boot/Image" "$out/.config"
test -s "$out/arch/arm64/boot/Image"
test -s "$out/vmlinux"
test -s "$out/vmlinux.symvers"

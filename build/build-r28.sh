#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source_root=${1:-}

if [[ -z "$source_root" && -f "$script_dir/Makefile" ]]; then
  source_root=$script_dir
fi

if [[ -z "$source_root" || ! -f "$source_root/Makefile" ]]; then
  echo "usage: $0 /path/to/s25-gki-6.6.152-r28-source" >&2
  exit 2
fi

source_root=$(cd "$source_root" && pwd)
out=${OUT_DIR:-"$(dirname "$source_root")/out-r28"}
jobs=${JOBS:-$(nproc)}
llvm_dir=${LLVM_DIR:-/usr/lib/llvm-18/bin}

if [[ -f "$script_dir/../configs/r28-6.6.152.config" ]]; then
  config="$script_dir/../configs/r28-6.6.152.config"
elif [[ -f "$script_dir/s25-r28.config" ]]; then
  config="$script_dir/s25-r28.config"
else
  echo "R28 configuration not found" >&2
  exit 2
fi

test -f "$config"
test -x "$llvm_dir/clang"
command -v make >/dev/null
command -v bison >/dev/null
command -v flex >/dev/null
command -v pahole >/dev/null

mkdir -p "$out"
cp "$config" "$out/.config"

export KBUILD_BUILD_USER=${KBUILD_BUILD_USER:-vantshi}
export KBUILD_BUILD_HOST=${KBUILD_BUILD_HOST:-DESKTOP-BQ35J7R}
export KBUILD_BUILD_TIMESTAMP=${KBUILD_BUILD_TIMESTAMP:-Mon Sep 7 17:09:03 CST 2026}

make -C "$source_root" O="$out" ARCH=arm64 \
  LLVM="$llvm_dir/" LLVM_IAS=1 olddefconfig
make -C "$source_root" O="$out" ARCH=arm64 \
  LLVM="$llvm_dir/" LLVM_IAS=1 -j"$jobs"

test -s "$out/arch/arm64/boot/Image"
test -s "$out/vmlinux"
test -s "$out/vmlinux.symvers"

grep -E '^(CONFIG_KSU|CONFIG_KSU_SUSFS|CONFIG_NETFILTER_XT_TARGET_TCPMSS)=' "$out/.config"
sha256sum "$out/arch/arm64/boot/Image" "$out/.config" \
  "$out/vmlinux" "$out/vmlinux.symvers" "$out/System.map"

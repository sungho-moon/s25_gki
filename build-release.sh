#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "$script_dir/Makefile" ]; then
  source_root=$script_dir
else
  source_root=$(cd "$script_dir/.." && pwd)
fi
variant=${1:-builtin}
jobs=${JOBS:-$(nproc)}

case "$variant" in
  builtin)
    defconfig=s25_samsung_resukisu_susfs_common_v2_defconfig
    ;;
  lkm)
    defconfig=s25_samsung_lkm_common_v2_defconfig
    ;;
  *)
    echo "usage: $0 [builtin|lkm]" >&2
    exit 2
    ;;
esac

out=${OUT_DIR:-"$source_root/out/$variant"}
mkdir -p "$out"

make -C "$source_root" O="$out" ARCH=arm64 LLVM=1 LLVM_IAS=1 "$defconfig"
make -C "$source_root" O="$out" ARCH=arm64 LLVM=1 LLVM_IAS=1 \
  -j"$jobs" Image

sha256sum "$out/arch/arm64/boot/Image" "$out/.config"
test -f "$out/vmlinux.symvers" && sha256sum "$out/vmlinux.symvers"
cat "$out/include/config/kernel.release"

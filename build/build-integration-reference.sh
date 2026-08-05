#!/usr/bin/env bash
set -euo pipefail

root=/tmp/codex-gki-6.6.142
source_root=$root/android-common-replay-v2
resukisu=/tmp/test-resukisu
susfs=/tmp/test-susfs
script_dir=/mnt/c/Users/Admin/Documents/Codex/2026-08-04/k-k-3/work/gki-6.6.142-attempt
toolchain=$root/toolchain/kernel_platform/prebuilts
pahole=${PAHOLE_BIN:-/tmp/dwarves-1.30-install/bin/pahole}
jobs=${JOBS:-12}
variant=${VARIANT:-builtin}

case "$variant" in
  builtin)
    out=$root/resukisu-common-v2-6.6.142
    defconfig=s25_samsung_resukisu_susfs_common_v2_defconfig
    ;;
  lkm)
    out=$root/lkm-common-v2-6.6.142
    defconfig=s25_samsung_lkm_common_v2_defconfig
    ;;
  *)
    echo "unsupported VARIANT: $variant" >&2
    exit 2
    ;;
esac

test "$(sed -n 's/^SUBLEVEL = //p' "$source_root/Makefile")" = 142
test "$(git -C "$resukisu" rev-parse HEAD)" = 88dbc78682a3364d27ad34551943e18615abf868
test "$(git -C "$susfs" rev-parse HEAD)" = be7b7ef49a1e1b189c3abf00eacaa7ebdb4168c1

bash "$script_dir/fix-wsl-worktree-symlinks.sh" "$source_root"
cd "$source_root"

for fix in "$script_dir"/common-v2-compile-fix-{1..10}.patch; do
  if git apply --check "$fix" 2>/dev/null; then
    git apply "$fix"
  fi
done

if grep -qF 'scripts/basic/fixdep $(depfile)' scripts/Kbuild.include; then
  patch -p0 < "$script_dir/wsl1-disable-fixdep.patch"
fi
if grep -qF -- '-Wp,-MMD,$(depfile)' scripts/Makefile.host; then
  patch -p0 < "$script_dir/wsl1-kbuild-deps.patch"
fi

if [ ! -L drivers/kernelsu ]; then
  ln -s "$resukisu/kernel" drivers/kernelsu
fi
grep -qF 'obj-$(CONFIG_KSU) += kernelsu/' drivers/Makefile || \
  printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> drivers/Makefile
grep -qF 'source "drivers/kernelsu/Kconfig"' drivers/Kconfig || \
  sed -i '/endmenu/i source "drivers/kernelsu/Kconfig"' drivers/Kconfig

cp -f "$susfs/kernel_patches/fs/susfs.c" fs/susfs.c
cp -f "$susfs/kernel_patches/include/linux/susfs.h" include/linux/susfs.h
cp -f "$susfs/kernel_patches/include/linux/susfs_def.h" include/linux/susfs_def.h
if ! grep -qF 'susfs_is_current_ksu_domain' fs/namespace.c; then
  git apply --reject --whitespace=nowarn \
    "$susfs/kernel_patches/50_add_susfs_in_gki-android15-6.6.patch" || true
fi
if [ -f fs/namespace.c.rej ] && [ -f fs/proc/base.c.rej ] && [ -f fs/proc/task_mmu.c.rej ]; then
  git apply "$script_dir/susfs-common-v2-rejects.patch"
  rm -f fs/namespace.c.rej fs/proc/base.c.rej fs/proc/task_mmu.c.rej
fi
sed -i '/^[[:space:]]*$/s/[[:space:]]//g' mm/memory.c
if find . -name '*.rej' -type f -print -quit | grep -q .; then
  echo 'unresolved patch reject exists' >&2
  find . -name '*.rej' -type f -print >&2
  exit 1
fi

cp -f arch/arm64/configs/stock_gki_defconfig \
  "arch/arm64/configs/$defconfig"
if [ "$variant" = builtin ]; then
  scripts/config --file "arch/arm64/configs/$defconfig" \
    -e KSU \
    -e KSU_MULTI_MANAGER_SUPPORT \
    -e KSU_SUSFS \
    -e KSU_SUSFS_SUS_PATH \
    -e KSU_SUSFS_SUS_MOUNT \
    -e KSU_SUSFS_SUS_KSTAT \
    -e KSU_SUSFS_SPOOF_UNAME \
    -d KSU_SUSFS_ENABLE_LOG \
    -e KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
    -e KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG \
    -e KSU_SUSFS_OPEN_REDIRECT \
    -e KSU_SUSFS_SUS_MAP \
    -d KSU_DEBUG
else
  scripts/config --file "arch/arm64/configs/$defconfig" \
    -d KSU \
    -d KSU_MULTI_MANAGER_SUPPORT \
    -d KSU_SUSFS \
    -d MODULE_SIG_PROTECT \
    -d MODULE_SIG_FORCE
fi

export PATH="$root/wsl1-tools:$toolchain/build-tools/linux-x86/bin:$toolchain/build-tools/path/linux-x86:$toolchain/kernel-build-tools/linux-x86/bin:$PATH"
export LD_LIBRARY_PATH="/tmp/dwarves-1.30-install/lib:$toolchain/kernel-build-tools/linux-x86/lib64"
test -x "$pahole"
args=(ARCH=arm64 LLVM="$root/wsl1-tools/" LLVM_IAS=1 \
  HOSTCC="$root/wsl1-tools/hostcc" HOSTCXX="$root/wsl1-tools/hostcxx" \
  KBUILD_NOCMDDEP=1 PAHOLE="$pahole")

if [ "${CLEAN:-0}" = 1 ]; then
  make -j"$jobs" -C "$source_root" O="$out" "${args[@]}" clean
fi

mkdir -p "$out/scripts/kconfig"
if [ ! -s "$out/scripts/kconfig/parser.tab.h" ]; then
  cp -f "$root/out/scripts/kconfig/parser.tab.c" \
    "$root/out/scripts/kconfig/parser.tab.h" "$out/scripts/kconfig/"
fi
cp -f "$root/out/scripts/kconfig/.parser.tab.h.cmd" "$out/scripts/kconfig/.parser.tab.h.cmd"
touch "$out/scripts/kconfig/parser.tab.c" "$out/scripts/kconfig/parser.tab.h"
mkdir -p "$out/scripts/dtc"
for f in dtc-lexer.lex.c dtc-parser.tab.c dtc-parser.tab.h .dtc-lexer.lex.c.cmd .dtc-parser.tab.h.cmd; do
  test -e "$root/out/scripts/dtc/$f" && cp -f "$root/out/scripts/dtc/$f" "$out/scripts/dtc/$f"
done
touch "$out/scripts/dtc/dtc-lexer.lex.c" "$out/scripts/dtc/dtc-parser.tab.c" "$out/scripts/dtc/dtc-parser.tab.h"
mkdir -p "$out/scripts/genksyms"
for f in lex.lex.c parse.tab.c parse.tab.h .lex.lex.c.cmd .parse.tab.c.cmd; do
  test -e "$root/out/scripts/genksyms/$f" && cp -f "$root/out/scripts/genksyms/$f" "$out/scripts/genksyms/$f"
done
touch "$out/scripts/genksyms/lex.lex.c" "$out/scripts/genksyms/parse.tab.c" "$out/scripts/genksyms/parse.tab.h"

make -j"$jobs" -C "$source_root" O="$out" "${args[@]}" "$defconfig"
scripts/config --file "$out/.config" \
  -d UH -d RKP -d KDP -d SECURITY_DEFEX -d INTEGRITY -d FIVE \
  -d TRIM_UNUSED_KSYMS -d LOCALVERSION_AUTO -d MODULE_SCMVERSION
if [ "$variant" = lkm ]; then
  scripts/config --file "$out/.config" \
    -d KSU \
    -d KSU_MULTI_MANAGER_SUPPORT \
    -d KSU_SUSFS \
    -d MODULE_SIG_PROTECT \
    -d MODULE_SIG_FORCE
fi
make -j"$jobs" -C "$source_root" O="$out" "${args[@]}" olddefconfig
make -j"$jobs" -C "$source_root" O="$out" "${args[@]}" Image

sha256sum "$out/arch/arm64/boot/Image" "$out/.config" "$out/vmlinux.symvers" "$out/vmlinux"
cat "$out/include/config/kernel.release"

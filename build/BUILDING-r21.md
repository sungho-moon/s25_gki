# Building S25 GKI 6.6.152 r21

This is the build record for the exact r21 boot image. The source archive must
be unpacked first; it contains the expanded ReSukiSU tree and the S25 changes.

Environment used for the recorded build:

- Ubuntu 24.04 Multipass VM
- Ubuntu clang 18.1.3
- LLVM_IAS=1
- 6 GiB swap enabled for the BTF/link stage
- ARCH=arm64

The recorded build configuration is configs/r7-6.6.152-r21.config. It is a
complete generated .config, not the older 6.6.98 Samsung defconfig. Copy it
into the output directory before running olddefconfig so the release can be
reproduced from the source snapshot:

~~~bash
#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
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
~~~

The recorded build completed with BUILD_RC=0. It emitted one non-fatal
udp_tunnel_nic_ops MODPOST version-generation warning; recheck this warning
if the toolchain changes. Do not include build outputs, signing keys, original
Samsung boot images, or proprietary vendor modules in the Git repository.

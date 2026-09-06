# S25 GKI 6.6.152 r27 ReSukiSU v35116 boot-only AK3

> **WITHDRAWN / 禁止刷写：** 真机已确认在第一屏发生
> `ksu_handle_faccessat+0x34` kernel panic。使用 r26 回退或 r28 热修复包。

This package updates the built-in ReSukiSU integration from v35089 to the
latest successful CI build, v35116. The source is pinned to commit
`f7829ddf548a18b851d653feb76b4a569b8fd2a4` and reports
`v4.2.0-rc1-f7829ddf@ReSukiSU` at runtime.

The package retains the known-good r26 device changes:

- xHCI teardown keeps the saved device pointer and conditionally clears the
  DCBAA and slot entries.
- The real built-in `xt_TCPMSS` target is present for Android tethering.
- The delayed deep-suspend selection and s2idle guard remain unchanged.
- SUSFS remains v2.2.0, updated to the matching zygote-next/no-SU interface
  required by ReSukiSU v35116.

This is a boot-only AnyKernel3 package for `SM-S938B/pa3q` and `pa3qxxx`.
It contains no LKM/KPM payload, `vendor_dlkm.img`, `system_dlkm`,
`vendor_boot`, or `dtbo`. It does not patch vbmeta.

The kernel was built on native WSL ext4 storage with Ubuntu 26.04,
clang/LLD 18.1.8, `LLVM_IAS=1`, and the r26 configuration carried forward
through `olddefconfig`. The build completed vmlinux, BTF, kallsyms, FIPS
processing, module metadata, and Image generation with exit code 0.

This package has not been flashed or boot-tested by Codex. Keep a verified
backup of the currently bootable boot image and confirm the active slot before
installing. After first boot, verify the kernel version, ReSukiSU version,
hotspot traffic, USB-C detach behavior, and suspend behavior.

# Source Provenance

This desktop source tree is the Samsung S25 GKI compatibility tree merged with
Android Common/Linux Stable through Linux 6.6.152.

- Samsung compatibility base: SM8750/S25 vendor GKI source
- ReSukiSU source: https://github.com/ReSukiSU/ReSukiSU
- ReSukiSU CI tag: `v35116`
- ReSukiSU commit: `f7829ddf548a18b851d653feb76b4a569b8fd2a4`
- ReSukiSU source count: `4416`
- ReSukiSU CI run: `33939268200`
- SUSFS: `v2.2.0`, branch `gki-android15-6.6`, compatibility commit `7767a46`
- Kernel release: `6.6.152-pe17667d-abogkiS938BXXU9CZDP-4k`

`drivers/kernelsu` is expanded into a real source directory. Its Kbuild file
contains an explicit v35116 fallback identity for source copies without the
ReSukiSU parent Git metadata, so a standalone desktop build does not revert to
the old 30700/source-copy identity.

The r28 build started from the same r27 source integration on a native ext4
filesystem under WSL2 and retained the r26 xHCI, TCPMSS and delayed-suspend
fixes. It additionally applies the caller-side `struct filename` conversion
from SUSFS commit `e13f390675ec7915aa51eb1ef727d6ed7a260a90`. This fixes the
ABI mismatch that made r27 panic at `ksu_handle_faccessat+0x34` during boot.
Linux v6.6.152 was used to restore case-distinct netfilter files that cannot
coexist in the Windows source archive.

The source tree contains the suspend deep-selection workaround and the retained
USB-C/DWC3 changes. It does not contain proprietary Samsung vendor modules,
`vendor_dlkm.img`, or a vendor_dlkm packaging step.


# Source Provenance

This desktop source tree is the Samsung S25 GKI compatibility tree merged with
Android Common/Linux Stable through Linux 6.6.152.

- Samsung compatibility base: SM8750/S25 vendor GKI source
- ReSukiSU source: https://github.com/ReSukiSU/ReSukiSU
- ReSukiSU CI tag: `v35089`
- ReSukiSU commit: `b2ac2fc8703ce9f5226e2a38a59f8b72f8a3005c`
- ReSukiSU source count: `4389`
- SUSFS: `v2.2.0`
- Kernel release: `6.6.152-pe17667d-abogkiS938BXXU9CZDP-4k`

`drivers/kernelsu` is expanded into a real source directory. Its Kbuild file
contains an explicit v35089 fallback identity for source copies without the
ReSukiSU parent Git metadata, so a standalone desktop build does not revert to
the old 30700/source-copy identity.

The source tree contains the suspend deep-selection workaround and the retained
USB-C/DWC3 changes. It does not contain proprietary Samsung vendor modules,
`vendor_dlkm.img`, or a vendor_dlkm packaging step.


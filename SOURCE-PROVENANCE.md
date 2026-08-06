# Source Provenance

This release uses the Samsung SM8750 GKI source as the device compatibility
base and merges Android Common/Linux Stable through Linux 6.6.142.

- Samsung source: https://github.com/fei-ke/android_kernel_samsung_sm8750
- Samsung branch: `gki`
- Samsung source commit: `7ddb142e90e2b202b3aa7bb5996fe99c4bc6ecfc`
- Local 6.6.142 merge base: `c32f768993aa0228bb64f5a34d537a025e6a2c28`
- ReSukiSU source: https://github.com/rsuntk/KernelSU
- ReSukiSU commit: `88dbc78682a3364d27ad34551943e18615abf868`
- SUSFS source: https://gitlab.com/simonpunk/susfs4ksu
- SUSFS commit: `be7b7ef49a1e1b189c3abf00eacaa7ebdb4168c1`

The release source archive is a snapshot of the exact modified working tree
used for the final builds. It includes the changes after the merge-base commit,
including ReSukiSU, SUSFS, Samsung KMI fixes, build compatibility fixes, and
both release defconfigs. Git metadata and build output directories are omitted.

`drivers/kernelsu` was a local integration symlink during development. In the
published source archive it is expanded into a real directory so that the
archive is self-contained.

Kernel release:

```text
6.6.142-pe17667d-abogkiS938BXXU9CZDP-4k
```

The Samsung stock boot image and proprietary vendor modules are not included.
They were used only for local compatibility auditing.

For the r2 USB-C hotfix, apply `patches/usb-c-xhci-free-virt-device-fix.patch`
to the source snapshot before rebuilding. The same patch is included as a
separate Release asset for users who download the prepared source tarball.

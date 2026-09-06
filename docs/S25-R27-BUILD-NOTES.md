# S25 GKI 6.6.152 r27 build notes

R27 updates only the built-in ReSukiSU integration and the matching SUSFS
interface while retaining the r26 device fixes and configuration policy.

The Windows-published r21 source archive loses case-distinct Linux files. The
source was therefore unpacked and built on WSL2 ext4. All case-colliding
netfilter files used by this configuration were restored from Linux stable
v6.6.152 before the successful link. The r26 xHCI saved-device ownership fix
was restored from Android Common 6.6.

ReSukiSU is pinned to the latest successful CI build available at build time:
v35116, source commit `f7829ddf548a18b851d653feb76b4a569b8fd2a4`.
The two newer commits then present on `main` did not yet have a published CI
build and were intentionally not used.

The output completed vmlinux, BTF, kallsyms, FIPS processing, module metadata,
and Image generation with `BUILD_RC=0`. R27 has not been flashed or boot-tested.

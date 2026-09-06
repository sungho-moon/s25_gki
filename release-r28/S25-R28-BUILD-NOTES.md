# S25 GKI 6.6.152 r28 build notes

R27 compiled successfully but failed on the first boot screen. After recovery to
the verified R26 package, the latest Samsung persistent last-kmsg was inspected
in place. At 4.134 seconds init started `/data/adb/ksud post-fs-data`; at
4.135440 seconds the kernel faulted at `ksu_handle_faccessat+0x34/0xdc` and
panicked. The R27 vmlinux mapped that instruction to
`drivers/kernelsu/feature/sucompat.c:499`.

ReSukiSU v35116 changed the SUSFS `faccessat` handler to accept
`struct filename **`. The S25 base tree still used the older `fs/open.c`
declaration and passed `const char __user **`. R28 applies the corresponding
caller-side path conversion from SUSFS commit `e13f390`: `getname_flags()`,
`ksu_handle_faccessat(&dfd, &fname, ...)`, `filename_lookup()` and `putname()`.
The matching `vfs_statx()` guard/signature is included as well.

No ReSukiSU, configuration, device workaround or AK3 partition-target changes
were added. A new output directory was used for a full build, which completed
Image, vmlinux, BTF, kallsyms, FIPS processing and module metadata with
`BUILD_RC=0`. The resulting package has not yet been flashed or boot-tested.

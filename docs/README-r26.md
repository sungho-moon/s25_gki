# S25 GKI 6.6.152 r26 hotspot/TCPMSS fix boot-only AK3

This is a boot-only test package for SM-S938B/pa3q. It contains the newly
built kernel `Image` only; it has no `vendor_dlkm.img` and does not modify or
flash `vendor_dlkm`.

The primary r26 change fixes Android hotspot teardown. SoftAP and DHCP were
starting, but netd failed while installing the tethering post-route rule:
`ip6tables-restore` reported that `tetherctrl_counters` did not exist. The
chain is created by netd only after its TCPMSS clamp rule succeeds. The
Windows case-insensitive checkout had silently replaced the target source
`net/netfilter/xt_TCPMSS.c` with the unrelated match source
`net/netfilter/xt_tcpmss.c`, so the runtime `TCPMSS` target was absent even
though Kconfig said it was enabled. r26 is built from a native ext4 checkout,
and the image contains `tcpmss_tg_init` with `CONFIG_NETFILTER_XT_TARGET_TCPMSS=y`.

The package also retains the proven xHCI detach race fix described below.

Samsung's persistent last-kmsg archive confirms the failure in
`xhci_free_virt_device+0x54/0x308`, called from `xhci_free_dev` while
`__dwc3_set_mode` removes the host controller. The faulting address is
`0x12a0`: the old workaround replaced a valid saved `virt_dev` pointer with
an already-cleared `xhci->devs[slot_id]`, then accessed `dev->flags` through
that null pointer.

r26 retains the proven r22 xHCI fix that removes that unsafe bit-flag workaround and restores the stable xHCI
ownership rules: teardown continues with the saved device pointer, DCBAA is
cleared only if it still references that device, and the slot entry is
cleared only if it still owns the same pointer. This fixes the first proven
fault rather than changing MAX77775, DWC3, SCSI/UAS, or filesystem code.

The kernel source keeps the normal boot-time suspend operation ordering. The
built-in parameter `s25_suspend_force_deep=1` changes a first real
`PM_SUSPEND_TO_IDLE` request to `PM_SUSPEND_MEM`, after vendor PM probing has
completed. This is deliberately different from changing `mem_sleep_current`
inside early `suspend_set_ops()`, which caused the withdrawn r14 package to
hang at the first boot screen.

The existing source-level deep-suspend policy and s2idle guard from r21 remain
unchanged. They are independent of the xHCI detach fix and are kept to avoid
changing two previously tested policies in the same validation build.

After boot, verify with:

```sh
su -c 'cat /sys/power/mem_sleep'
su -c 'cat /sys/module/suspend/parameters/s25_suspend_force_deep'
```

The expected result is `deep` selected in `mem_sleep` and `Y` for the module
parameter. Runtime sysfs changes remain available for A/B testing, but keep
the default enabled during the first stability test.

This package has not been flashed by Codex. It does not include the withdrawn
vendor-module experiment and does not patch vbmeta
(`no_vbmeta_partition_patch=1`). It contains no `vendor_dlkm.img`.

The build used the ReSukiSU CI v35089 source snapshot (commit
`b2ac2fc8703ce9f5226e2a38a59f8b72f8a3005c`, calculated code 35089) and
Ubuntu clang 18.1.3 in the `ai-linux` Multipass VM with
`LLVM_IAS=1`, complete r7/r11-style symbol configuration, and no swap for
the BTF pass. `TRIM_UNUSED_KSYMS` and `MODULE_SIG_PROTECT` are disabled, and
the retained vmlinux.symvers contains 16,664 lines. The r26 build started from a new empty output directory with the exact r22 .config; after stopping the initial -j8 run, it resumed with -j16 and compiled all dependencies selected
by Kbuild with the exact original LLVM command prefix, and completed vmlinux,
BTF, kallsyms, FIPS processing, and Image. External module targets were
intentionally skipped because this is a boot-only package. This is not a claim
that Samsung's exact release compiler was used.

After the first successful boot, verify hotspot first: enable Mobile Hotspot,
connect a client, and confirm that the switch remains enabled and traffic
passes. Then repeat both storage and headset detach tests, with the screen on
and off. If another panic occurs, preserve `/data/log/dumpstate_lastkmsg_*`
before further changes.

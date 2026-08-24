# Samsung S25 vendor suspend fix

The source patch in this directory targets the Samsung vendor tree from
`SM-S938B_16_Opensource/Kernel.tar.gz`, under
`kernel_platform/msm-kernel/`. It is intentionally kept separate from the
generic 6.6.152 GKI tree because that tree does not contain the Samsung
Max77775/PDIC implementation.

The patch was checked with `git apply --check` against the unmodified official
6.6.98 source. The following source groups were then compiled against the
current 6.6.152 GKI generated headers:

```text
drivers/mfd/maxim/mfd_max77775.o
drivers/usb/typec/maxim/pdic_max77775.o
drivers/usb/typec/common/pdic_notifier_module.o
drivers/muic/common/common_muic.o
drivers/usb/notify/usb_notify_layer.o
drivers/usb/notify/usb_vendor_hook_receiver.o
```

The generic GKI image itself was built successfully and produced a complete
6.6.152 `Module.symvers`. The official 6.6.98 `mfd_max77775.ko` and
`pdic_max77775.ko` were then rebuilt with a merged GKI/stock-vendor KMI dump;
the resulting `vermagic`, `depends`, exported CRCs and imported CRCs were
audited against the stock modules. The PDIC HMD parser also uses `strscpy`
because `strlcpy` is not present in this S25 KMI.

These are still unsigned candidate `.ko` files, not a ready-to-flash
`vendor_dlkm` image. Do not copy a raw 6.6.98 module over a live partition.
The final package must retain Samsung's module signing and the matching
`vendor_dlkm`/`system_dlkm` module metadata.

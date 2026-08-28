# S25 Type-C detach xHCI race fix

## Confirmed failure

Two Samsung persistent crash records show the same program counter:
`xhci_free_virt_device+0x54/0x308`. The latest trace is:

```text
__dwc3_set_mode
  dwc3_host_exit
    platform_device_unregister
      xhci_plat_remove
        usb_remove_hcd
          usb_disconnect
            xhci_free_dev
              xhci_free_virt_device
```

The panic reports a read from virtual address `0x12a0`. At the fault, the
device pointer is null; `0x12a0` is the access offset used by the custom
`dev->flags` guard.

## Root cause

`xhci_free_dev()` correctly saves `xhci->devs[slot_id]` before disabling the
slot. The previous workaround then discarded that saved pointer inside
`xhci_free_virt_device()` and reloaded the slot array. A concurrent slot
disable/interrupt path can already have cleared the array entry, so the
following `test_and_set_bit()` dereferenced null.

## r22 change

- Keep using the saved `struct xhci_virt_device *dev` through teardown.
- Clear the DCBAA entry only while it still references `dev->out_ctx->dma`.
- Clear `xhci->devs[slot_id]` only while it still equals the saved `dev`.
- Remove the matching unnamed bit-1 early return from setup/free paths.

This follows the ownership model already present in current Android/common
6.6 stable xHCI code and preserves its slot-reuse protection. It does not
modify Samsung vendor modules or any dynamic kernel-module partition.

## Validation boundary

Compilation and binary inspection can prove that the unsafe path is absent
from the new image. Only repeated detach testing on SM-S938B/pa3q can prove
the complete device-level outcome. Do not combine the first r22 test with a
`vendor_dlkm`, vbmeta, DTBO, or monitoring-module change.

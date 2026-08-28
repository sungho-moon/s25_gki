# Historical S25 USB-offline suspend workaround

> Status for r22: retained unchanged from r21, but it is not the fix for the
> newly confirmed Type-C detach panic. See `S25-XHCI-DETACH-FIX.md`.

The S25 vendor USB-C stack can continue Type-C/PD work after the display is
turned off. On the affected 6.6.152 builds, that activity can race the default
`s2idle` path when the cable is disconnected and leave the device unresponsive.

`kernel/power/suspend.c` now applies a reversible policy in the built-in
`suspend` code:

- USB state is cached from the `usb` power-supply notifier and refreshed before
  each suspend attempt.
- The boot-time `suspend_set_ops()` path is left unchanged so vendor PM
  probing and userspace startup keep their normal ordering.
- When the first real `PM_SUSPEND_TO_IDLE` request arrives,
  `s25_suspend_force_deep=1` changes that request to `PM_SUSPEND_MEM`.
- The legacy USB/offline s2idle guard remains available for diagnosis, but it
  is not the mechanism used by this r21 source-deep package.

The policy is enabled by default for this S25 build. Runtime controls are:

```text
/sys/module/suspend/parameters/s25_suspend_guard
/sys/module/suspend/parameters/s25_suspend_guard_usb_only
/sys/module/suspend/parameters/s25_suspend_force_deep
```

For a controlled comparison, disable the policy with:

```sh
su -c 'echo 0 > /sys/module/suspend/parameters/s25_suspend_guard'
```

This remains a source-level power-policy workaround. The later persistent
last-kmsg evidence identifies a separate, deterministic xHCI teardown null
pointer as the Type-C detach panic addressed by r22.

## Vendor-driver fix candidate

Samsung's SM-S938B Android 16 source (`6.6.98`) contains the missing MAX77775,
PDIC and MUIC implementation. Inspection of that tree found a child/parent PM
ordering window: the USB-C child can queue an opcode or notifier after USB
detach while the MAX77775 MFD parent is entering suspend.

`vendor-patches/S25-MAX77775-SUSPEND-RACE.patch` implements the first
source-level fix candidate. It:

- raises a shared suspend gate before IRQ synchronization;
- rejects new MAX77775 opcode and PDIC notifier work while the gate is set;
- cancels and flushes the USB-C/MUIC asynchronous work before suspend; and
- clears the gate and wakes the IRQ waiters on resume.

The changed Samsung modules compile against both the official 6.6.98 vendor
tree and the current 6.6.152 GKI headers. This is not yet a flashable module
set: the two candidate modules were rebuilt from the official 6.6.98 source
with the stock vendor CRCs and the completed 6.6.152 GKI symbol table, and
their `depends`/`__versions` sections were checked against the stock module
set. They are still unsigned standalone artifacts; they have not been
wrapped into a `vendor_dlkm` image and must not be flashed by copying them
over a live partition. The final deployment must preserve Samsung's module
signing and partition metadata.

The official source uses `strlcpy` in one HMD parser path, while the S25 GKI
KMI exports `strscpy` instead. The patch uses `strscpy` (the return value is
ignored) so the candidate PDIC module has no unresolved KMI symbol.

For the eventual A/B test, package the fixed vendor modules and boot with the
GKI guard disabled. Otherwise the existing deep-sleep policy masks whether
the vendor-driver race is actually fixed.

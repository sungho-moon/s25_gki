# S25 hotspot TCPMSS target fix

## Confirmed failure

The phone successfully enabled `swlan0` and started DHCP, but NetworkStack
then asked netd to install tethering rules. netd failed in its post-route
setup because `ip6tables-restore` could not jump to `tetherctrl_counters`.
The preceding TCPMSS clamp rule had failed because the kernel did not expose
the `TCPMSS` target at runtime.

## Root cause

The source tree was edited on a case-insensitive Windows filesystem. Linux has
both `net/netfilter/xt_TCPMSS.c` (the TCPMSS target used by netd) and
`net/netfilter/xt_tcpmss.c` (the unrelated TCPMSS match). Windows collapsed
the two names, leaving only the match implementation while Kconfig still
reported `CONFIG_NETFILTER_XT_TARGET_TCPMSS=y`.

## r26 fix

r26 is checked out on native ext4 with case preservation. The target source is
compiled as built-in, and binary inspection confirms `tcpmss_tg_init` in
`vmlinux` and `net/netfilter/xt_TCPMSS.o`. The match remains disabled, as in
the Android common configuration.

This restores the target that lets netd create `tetherctrl_counters`; it does
not alter netd, tethering policy, or vendor_dlkm.

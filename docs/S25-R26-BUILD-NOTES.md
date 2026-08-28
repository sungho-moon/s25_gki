# r26 build notes

r26 is a full clean rebuild of the known-good r22 Samsung/ReSukiSU/SUSFS boot configuration. The source tree is `/home/ubuntu/s25-gki-overlay`; only the case-collision-corrupted TCPMSS target source and UAPI header were restored before the rebuild.

The r22 `.config` is byte-for-byte retained. The Image contains the real `tcpmss_tg_init` target; `tcpmss_mt_init` is not used for the target. Samsung boot-critical options remain enabled, including `CONFIG_USB_HOST_SAMSUNG_FEATURE=y`, `CONFIG_KNOX_NCM=y`, `CONFIG_BLOCK_SUPPORT_STLOG=y`, `CONFIG_PROC_STLOG=y`, `CONFIG_KSU=y`, and `CONFIG_KSU_SUSFS=y`.

Image SHA256: b221c4ce00c17ca91bc3c5ecf8e3b7fdeb487c919eb5dc870df96ab4ff742b6c
Config SHA256: d7700e89a5f39941c4fa3374b66894f6fbb1ad1bd0490f7e215dc709924027f5

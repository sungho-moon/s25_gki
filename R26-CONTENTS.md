# r26 交付目录

更新时间：2026-08-26

## 已验证

- 设备：Samsung Galaxy S25 Ultra（SM-S938B，pa3q/pa3qxxx）
- 内核：Linux GKI 6.6.152
- 状态：用户确认正常开机
- 类型：boot-only AnyKernel3；不刷写 vendor_dlkm/system_dlkm/vendor_boot/dtbo，不修改 vbmeta

## release-r26

- `S25U-S938B-GKI-6.6.152-r26-FULL-CLEAN-ReSukiSU-SUSFS-AK3.zip`：可刷包
- `README.md`、`BUILD-MANIFEST.txt`：包说明与构建清单
- `S25-R26-BUILD-NOTES.md`：构建过程和验证
- `S25-NETFILTER-HOTSPOT-FIX.md`：热点/netfilter 配置说明
- `S25-XHCI-DETACH-FIX.md`、`S25-SUSPEND-FIX.md`：USB-C/息屏方向说明
- `RESUKISU-CI-METADATA.txt`：ReSukiSU CI 元数据

## build-r26

包含 `Image`、`Image.config`、`Image.symvers`、`System.map`、`r26-build.log`、`SHA256SUMS.txt` 及上述说明文件。Image SHA-256：`b221c4ce00c17ca91bc3c5ecf8e3b7fdeb487c919eb5dc870df96ab4ff742b6c`。

包 SHA-256：`a113d163717d0864182177bc465717e903af12a66079fe3f4beae36547865200`。

旧版 `release-r21` 至 `release-r25` 和 `build-r21` 至 `build-r25` 保留，不覆盖，便于回退和对比。

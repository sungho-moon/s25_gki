# S25 Ultra GKI 6.6.152 R28

R28 已由用户在 Samsung Galaxy S25 Ultra `SM-S938B/pa3q` 上确认成功开机。

## 下载哪个文件

- `S25U-S938B-GKI-6.6.152-r28-ReSukiSU-v35116-SUSFS-FACCESSAT-HOTFIX-AK3.zip`
  是 Recovery/AnyKernel3 刷机包。
- `ReSukiSU_v4.2.0-rc1_35116-universal-release.apk` 是匹配的管理器。
- `s25-gki-6.6.152-r28-source.tar.zst` 是完整可重建源码，供维护者使用。
- 下载后使用 `SHA256SUMS-r28.txt` 校验。

## 重要提醒

- 仅适用于 `SM-S938B/pa3q/pa3qxxx`；其他机型不要刷。
- R27 已因 `ksu_handle_faccessat+0x34` 启动 panic 撤回。
- 刷写前备份当前 boot，并保留 R26 回退包。
- 本包是 boot-only，不刷 vendor/system_dlkm、vendor_boot、dtbo 或 vbmeta。

R28 修复了 ReSukiSU v35116 与旧 SUSFS `faccessat` 调用方之间的
`const char __user **` / `struct filename **` 接口错配。完整故障证据和构建信息
见仓库中的 `release-r28/BUILD-MANIFEST.txt`。

成功开机不代表全部稳定性测试完成。请继续验证热点、USB-C 存储/耳机拔出、
息屏和唤醒。

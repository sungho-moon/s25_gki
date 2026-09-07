# r28 交付目录

更新时间：2026-09-07

## 状态

- 设备：Samsung Galaxy S25 Ultra（SM-S938B，pa3q/pa3qxxx）
- 内核：Linux GKI 6.6.152
- ReSukiSU：v35116，commit `f7829ddf548a18b851d653feb76b4a569b8fd2a4`
- SUSFS：v2.2.0，compat commit `7767a46`
- 修复：补齐 SUSFS commit `e13f390` 的 `faccessat`/`stat` 调用方接口
- 构建：全量 clean build，`BUILD_RC=0`，0 compiler error，0 compiler warning
- 状态：用户已确认成功开机；r26 继续保留为回退基线
- 类型：boot-only AnyKernel3；不写 vendor 分区，不修改 vbmeta

## release-r28

- `S25U-S938B-GKI-6.6.152-r28-ReSukiSU-v35116-SUSFS-FACCESSAT-HOTFIX-AK3.zip`：R27 启动 panic 热修复候选包
  - SHA-256：`df0f89dc146a4fd3ab99d3eb4651cdbf69af1776cda21e9ef74d987df5e554c1`
- `ReSukiSU_v4.2.0-rc1_35116-universal-release.apk`：匹配管理器
- `s25-gki-6.6.152-r28-source.tar.zst`：GitHub Release 中的完整可重建源码快照
- `README.md`、`BUILD-MANIFEST.txt`：版本说明和构建清单
- `S25-R28-BUILD-NOTES.md`：故障证据、根因和修复记录
- `SHA256SUMS.txt`：发布包和管理器校验和

R27 已由真机确认卡第一屏，persistent last-kmsg 显示
`ksu_handle_faccessat+0x34` 在 `ksud post-fs-data` 启动期间 panic，禁止继续刷写。

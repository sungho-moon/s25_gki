# Samsung Galaxy S25 Ultra GKI

适用于 Samsung Galaxy S25 Ultra `SM-S938B`（`pa3q/pa3qxxx`）的
Linux 6.6.152 GKI，内置 ReSukiSU v35116 与 SUSFS v2.2.0。

## 当前版本

**R28 已由用户确认成功开机。** R27 因
`ksu_handle_faccessat+0x34` 启动 panic 已撤回，禁止刷写。

| 项目 | 内容 |
| --- | --- |
| 内核 | `6.6.152-pe17667d-abogkiS938BXXU9CZDP-4k` |
| ReSukiSU | `v4.2.0-rc1-f7829ddf@ReSukiSU` / 35116 |
| SUSFS | v2.2.0 |
| 安装包 | boot-only AnyKernel3 |
| 已验证设备 | SM-S938B / pa3q |
| 回退版本 | R26 FULL-CLEAN |

## 下载

推荐从 [GitHub Releases 的 v6.6.152-r28](https://github.com/sungho-moon/s25_gki/releases/tag/v6.6.152-r28)
下载，不要使用聊天记录中的临时文件：

- `S25U-S938B-GKI-6.6.152-r28-ReSukiSU-v35116-SUSFS-FACCESSAT-HOTFIX-AK3.zip`
  — 可刷入的 AnyKernel3 包。
- `ReSukiSU_v4.2.0-rc1_35116-universal-release.apk`
  — 匹配的管理器。
- `s25-gki-6.6.152-r28-source.tar.zst`
  — 完整、可重新构建的源码快照。
- `SHA256SUMS-r28.txt`
  — 所有发布资产的 SHA-256。

AK3 包 SHA-256：

```text
df0f89dc146a4fd3ab99d3eb4651cdbf69af1776cda21e9ef74d987df5e554c1
```

仓库内也保留一份 [R28 AK3 包](release-r28/S25U-S938B-GKI-6.6.152-r28-ReSukiSU-v35116-SUSFS-FACCESSAT-HOTFIX-AK3.zip)。

## 安装前

1. 确认设备是 `SM-S938B/pa3q`，并保留当前可启动的 `boot.img`。
2. 下载后核对 `SHA256SUMS-r28.txt`。
3. 保留 [R26 回退包](release-r26/S25U-S938B-GKI-6.6.152-r26-FULL-CLEAN-ReSukiSU-SUSFS-AK3.zip)。
4. 首次测试不要同时刷 vendor 模块、DTBO、vbmeta 或其他内核模块。

在设备现有的 Recovery/AnyKernel3 流程中直接刷入 ZIP。这个包只处理活动槽位的
`boot`，不包含 `.ko`、KPM/LKM、`vendor_dlkm`、`system_dlkm`、`vendor_boot`
或 `dtbo`，也不修改 vbmeta。

如果卡第一屏或循环重启，恢复之前备份的 boot，或刷回 R26。不要用 R27。

## 开机后检查

```sh
adb shell su -c 'cat /proc/version'
adb shell su -c 'cat /sys/power/mem_sleep'
adb shell su -c 'cat /sys/module/suspend/parameters/s25_suspend_force_deep'
```

成功开机只证明启动问题已解决。热点、USB-C 存储/耳机拔出、息屏与唤醒仍应
继续测试；异常后优先保存 `/data/log/dumpstate_lastkmsg_*` 和
`/sys/fs/pstore`。

## 本地数据丢失后继续维护

GitHub Release 保存完整源码快照，仓库保存配置、补丁、构建脚本和发布清单。
新电脑只需要 Git、WSL2/Ubuntu、LLVM 18 和足够的磁盘空间：

```sh
git clone https://github.com/sungho-moon/s25_gki.git
cd s25_gki

# 下载并在 WSL 的 Linux 文件系统中解压源码，不能放在 /mnt/c
tar --zstd -xf s25-gki-6.6.152-r28-source.tar.zst -C "$HOME"

JOBS=12 bash build/build-r28.sh "$HOME/s25-gki-6.6.152-r28-source"
```

构建结果默认位于源码同级的 `out-r28/`。完整恢复步骤、依赖、验证和重新打包
方法见 [维护恢复指南](docs/MAINTENANCE-RECOVERY.md)。精确来源与哈希见
[R28 构建清单](release-r28/BUILD-MANIFEST.txt)。

## 目录

- `release-r28/`：当前 AK3、管理器、校验和与发布说明。
- `release-r26/`：已验证回退包。
- `configs/`：完整内核配置。
- `patches/`：S25、SUSFS 专项补丁。
- `build/`：可复用构建脚本。
- `docs/`：故障分析、构建记录和维护文档。

这是针对指定设备和固件基础的实验内核，不保证兼容其他 S25 型号或固件。

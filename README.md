# Samsung Galaxy S25 GKI 6.6.142

面向三星 Galaxy S25 系列的 Linux 6.6.142 GKI 内核实验构建。

本项目以三星 SM8750 `gki` 分支的 6.6.98 内核为设备兼容基线，合并
Android Common/Linux Stable 至 6.6.142，并保留三星 vendor 模块所需的
KMI。它不是直接刷入的纯 Google GKI，也不是适用于所有 6.6 设备的通用
内核。

## 主要特性

- 内核版本：`6.6.142`
- Kernel release：`6.6.142-pe17667d-abogkiS938BXXU9CZDP-4k`
- AnyKernel3 机型验证已关闭：`do.devicecheck=0`
- 刷入当前活动槽位的 `boot` 分区
- 不修改 `vendor_boot`，不包含 KPM/`patch_android`
- 保留三星 vendor 模块所需 KMI
- 保留 BTF、`CONFIG_MODVERSIONS` 与动态模块支持

## 已测试设备

- `SM-S938B/三星S25 Ultra`
- 设备代号：`pa3q`
- 系统版本：`OneUI 8.5`

AK3 的设备检查已按发布需求移除，因此安装器不会阻止其他型号刷入。这只
是取消安装器限制，不是兼容性保证。S25、S25+ 或其他地区/固件版本可能
具有不同的 vendor 模块、DTB、面板、基带及启动镜像布局。

## 刷入要求

- 已解锁 Bootloader
- 能够刷入 AnyKernel3 ZIP 的 内核刷写工具(如Kernel Flasher) 或Twrp
- 必须备份原厂 `boot.img` ！！！

刷入前请确认自己能够进入 Download Mode，并能够通过 Odin 或其他可靠
方式恢复原厂 `boot.img`。

## 下载

AK3刷机包请前往 [Releases](../../releases)。当前提供两个版本：

| 文件 | 说明 |
| --- | --- |
| `S25U-GKI-6.6.142-ReSukiSU-SUSFS-GENERIC-AK3.zip` | 内置 ReSukiSU 与 SUSFS，不含 KPM |
| `S25U-GKI-6.6.142-LKM-READY-GENERIC-AK3.zip` | 不内置 KSU/ReSukiSU/SUSFS，供用户自行加载 LKM |

第二个版本仍然是 GKI 内核。“LKM Ready”表示它没有内置 KernelSU，并且
移除了三星额外的 LKM 签名保护限制，不表示它是不带 GKI 的传统内核。


## 刷入方法

1. 备份当前活动槽位的原厂 `boot` 分区。或通过官方固件包提取
2. 下载所需版本。
3. 使用支持 AnyKernel3 的工具（如Kernel Flasher）刷入 ZIP。
4. 重启设备并检查内核版本、触摸、网络、相机、音频与充电功能。
5. 如果卡第一屏、循环重启，立即通过Odin恢复原厂
   `boot.img`。

## 免责声明

刷写自定义内核可能导致无法开机、数据丢失、保修或安全功能失效。作者和
贡献者不对设备损坏或数据损失负责。请先备份，并自行判断风险。

本项目以及所包含的第三方代码分别遵循各自许可证。Linux 内核源码按照
GPL-2.0 条款提供。

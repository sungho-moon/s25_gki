# Samsung Galaxy S25 GKI 6.6.142

面向三星 Galaxy S25 系列的 Linux 6.6.142 GKI 内核实验构建。

本项目以三星 SM8750 `gki` 分支的 6.6.98 内核为设备兼容基线，合并
Android Common/Linux Stable 至 6.6.142，并保留三星 vendor 模块所需的
KMI。它不是直接刷入的纯 Google GKI，也不是适用于所有 6.6 设备的通用
内核。

## 下载

刷机包请前往 [Releases](../../releases)。当前提供两个版本：

| 文件 | 说明 | 实机状态 |
| --- | --- | --- |
| `S25U-GKI-6.6.142-ReSukiSU-SUSFS-GENERIC-AK3.zip` | 内置 ReSukiSU 与 SUSFS，不含 KPM |
| `S25U-GKI-6.6.142-LKM-READY-GENERIC-AK3.zip` | 不内置 KSU/ReSukiSU/SUSFS，供用户自行加载 LKM |

第二个版本仍然是 GKI 内核。“LKM Ready”表示它没有内置 KernelSU，并且
移除了三星额外的 LKM 签名保护限制，不表示它是不带 GKI 的传统内核。

## 主要特性

- 内核版本：`6.6.142`
- Kernel release：`6.6.142-pe17667d-abogkiS938BXXU9CZDP-4k`
- AnyKernel3 机型验证已关闭：`do.devicecheck=0`
- 刷入当前活动槽位的 `boot` 分区
- 不修改 `vendor_boot`，不包含 KPM/`patch_android`
- 保留三星 vendor 模块所需 KMI
- 保留 BTF、`CONFIG_MODVERSIONS` 与动态模块支持

LKM Ready 版额外配置：

```text
CONFIG_KSU=n
CONFIG_MODULES=y
CONFIG_MODULE_UNLOAD=y
CONFIG_MODVERSIONS=y
CONFIG_MODULE_SIG_PROTECT=n
CONFIG_MODULE_SIG_FORCE=n
CONFIG_DEBUG_INFO_BTF=y
```

包内提供 `Image.config`；LKM Ready 版还提供 `Image.symvers`，方便核对或
编译与当前内核匹配的模块。

## 兼容性验证

使用当前 `SM-S938B` 原厂内核和 vendor 模块进行离线审计：

```text
vendor 模块依赖的三星内核符号：3030
CRC 匹配：3030
CRC 不匹配：0
缺失：0
```

LKM Ready 版 BTF 对比结果：

```text
共同命名结构/联合体：11174
布局差异：75
其中大小差异：46
同大小布局差异：29
```

`3030/3030` 只表示本次提取到的 S25 Ultra vendor 模块所依赖的内核符号
全部匹配，不代表所有导出符号、BTF 布局或其他 S25 固件完全相同。审计中
仍有 119 个共同导出符号的 CRC 与原厂不同，但当前提取的 vendor 模块没有
依赖这些符号。

## 已测试设备

- `SM-S938B`
- 设备代号：`pa3q`
- ReSukiSU + SUSFS 版已成功开机

AK3 的设备检查已按发布需求移除，因此安装器不会阻止其他型号刷入。这只
是取消安装器限制，不是兼容性保证。S25、S25+ 或其他地区/固件版本可能
具有不同的 vendor 模块、DTB、面板、基带及启动镜像布局。

## 刷入要求

- 已解锁 Bootloader
- 能够刷入 AnyKernel3 ZIP 的 Recovery 或内核刷写工具
- 与当前槽位和固件对应的原厂 `boot.img` 备份
- 已关闭会阻止自定义 boot 启动的验证机制

刷入前请确认自己能够进入 Download Mode，并能够通过 Odin 或其他可靠
方式恢复原厂 `boot.img`。

## 刷入方法

1. 备份当前活动槽位的原厂 `boot` 分区。
2. 下载所需版本，并校验 SHA-256。
3. 使用支持 AnyKernel3 的工具刷入 ZIP。
4. 重启设备并检查内核版本、触摸、网络、相机、音频与充电功能。
5. 如果卡第一屏、循环重启或 vendor 模块加载失败，立即恢复原厂
   `boot.img`。

不要同时刷入两个版本。从内置版切换至 LKM Ready 版时，建议先恢复同一
固件的原厂 boot，再刷入目标包。

## LKM 使用说明

LKM Ready 版没有内置 KernelSU。自行使用 KernelSU LKM 时，模块必须与
以下项目匹配：

- 完整 kernel release：
  `6.6.142-pe17667d-abogkiS938BXXU9CZDP-4k`
- ARM64、4 KiB page size
- `CONFIG_MODVERSIONS` 和 `Image.symvers` 中的 CRC
- 当前设备 vendor 模块及固件 KMI

仅仅看到内核主版本同为 `6.6.142` 并不足以保证 `.ko` 能加载。加载前应
检查 `vermagic` 和符号版本；不匹配时重新针对本项目源码、配置和符号表
编译模块。

## 文件校验

```text
3965aee362d55b106f9074df8a259362a963fad4ce70afa781520c6fb984dc27  S25U-GKI-6.6.142-ReSukiSU-SUSFS-GENERIC-AK3.zip
cec342f7dadc8f0729eb41d2367b43a75dd0c80f7322047461f2b4c95e9c316a  S25U-GKI-6.6.142-LKM-READY-GENERIC-AK3.zip
```

## 源码与版本

- 三星 SM8750 基线：
  [`fei-ke/android_kernel_samsung_sm8750`](https://github.com/fei-ke/android_kernel_samsung_sm8750)
- 基线分支：`gki`
- 基线 commit：`7ddb142e90e2b202b3aa7bb5996fe99c4bc6ecfc`
- 6.6.142 合并基点：`c32f768993aa0228bb64f5a34d537a025e6a2c28`
- ReSukiSU commit：`88dbc78682a3364d27ad34551943e18615abf868`
- SUSFS commit：`be7b7ef49a1e1b189c3abf00eacaa7ebdb4168c1`

发布二进制内核时，应同时发布与二进制准确对应的完整源码、配置、补丁和
构建说明。只链接上游仓库不能替代对应源码。

## 免责声明

刷写自定义内核可能导致无法开机、数据丢失、保修或安全功能失效。作者和
贡献者不对设备损坏或数据损失负责。请先备份，并自行判断风险。

本项目以及所包含的第三方代码分别遵循各自许可证。Linux 内核源码按照
GPL-2.0 条款提供。

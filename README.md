# Samsung Galaxy S25 GKI 6.6.152 r21

面向三星 Galaxy S25 Ultra SM-S938B/pa3q 的 Linux 6.6.152 GKI 内核实验构建。

本项目以三星 SM8750/S25 vendor GKI 源码作为设备兼容基线，合并
Android Common/Linux Stable 至 6.6.152，并保留三星 vendor 模块所需的
KMI。它不是直接刷入的纯 Google GKI，也不是适用于所有 6.6 设备的通用内核。

## 下载

刷机包请前往 [Releases](../../releases)。当前 r21 只发布 Resukisu 内置版：

| 文件 | 说明 | 状态 |
| --- | --- | --- |
| S25U-S938B-GKI-6.6.152-r21-SOURCE-DEEP-ReSukiSU-SUSFS-AK3.zip | 内置 ReSukiSU 与 SUSFS；延迟选择 deep suspend；不含 LKM/KPM/vendor_dlkm | SM-S938B/pa3q 已通过维护者真机刷入/启动测试 |
| ReSukiSU_v4.2.0-rc1_35089-universal-release.apk | 对应的 ReSukiSU 管理器 | 与 r21 元数据一致 |
| s25-gki-android15-6.6.152-r21-source.tar.gz | 与 Image 准确对应的完整源码快照 | 用于复现和源码对应 |

r21 不提供 LKM Ready 变体，也不应把旧的 6.6.142 r2 包和本版本混用。

## 主要特性

- 内核版本：6.6.152
- Kernel release：6.6.152-pe17667d-abogkiS938BXXU9CZDP-4k
- ReSukiSU：v4.2.0-rc1，版本码 35089，builtin-only
- SUSFS：v2.2.0
- AnyKernel3 只写当前活动槽位的 boot 分区
- do.devicecheck=1，目标设备为 pa3q/pa3qxxx
- 不包含 LKM 或 KPM payload
- 保留 BTF、CONFIG_MODVERSIONS 和 Image.symvers

## USB-offline suspend workaround

r21 在内置 suspend 代码中保留了可回退的 S25 workaround：

- 第一次真实的 PM_SUSPEND_TO_IDLE 请求到来后，选择 PM_SUSPEND_MEM。
- 启动阶段不改动 suspend operation 注册顺序，避免早期 PM 初始化受影响。
- USB power-supply 状态在 suspend 前刷新，并保留可运行时关闭的 s2idle guard。

该改动是针对 USB 断开后息屏异常的源码级 workaround，不是已经确认的
Samsung MAX77775/PDIC vendor 根因修复。运行时参数和 A/B 测试步骤见
docs/S25-SUSPEND-FIX.md 与 docs/README-S25-HANDOFF.md。

## 兼容性与测试

已测试目标：

- 型号：SM-S938B
- 设备代号：pa3q
- 包类型：boot-only AK3

维护者已确认 r21 AK3 通过真机刷入/启动测试。这个结果不代表所有 S25
型号、地区固件或 vendor 模块都兼容，也不代表长期 USB 断开息屏稳定性已经
完成统计。S25、S25+ 或其他地区版本可能具有不同的 vendor 模块、DTB、面板、
基带及 boot 镜像布局。

## 刷入要求

- 已解锁 Bootloader
- 支持 AnyKernel3 ZIP 的 Recovery 或内核刷写工具(https://github.com/capntrips/KernelFlasher/releases)
- 与当前固件和活动槽位对应的原厂 boot.img 备份
- 已确认能够进入 Download Mode，并能通过 Odin 或其他可靠方式恢复

刷写自定义 boot 前，先保存原厂 boot，并确认目标槽位。

## 刷入方法

1. 备份当前活动槽位的原厂 boot 分区。
2. 下载 r21 文件。
3. 使用支持 AnyKernel3 的工具刷入 AK3 ZIP。
4. 重启后检查内核版本、触摸、网络、相机、音频、充电和 USB 功能。
5. 出现卡第一屏、循环重启或模块加载异常时，立即通过Odin恢复原厂 boot.img。

## 源码与版本

- ReSukiSU 源码：https://github.com/ReSukiSU/ReSukiSU
- ReSukiSU commit：b2ac2fc8703ce9f5226e2a38a59f8b72f8a3005c
- ReSukiSU CI release：https://github.com/cctv18/ReSukiSU_CI/releases/tag/ReSukiSU_32561471902
- SUSFS：v2.2.0
- 设备兼容基线：Samsung SM8750/S25 vendor GKI source

Release 中的 source-kernel.tar.gz 是与 r21 Image 准确对应的完整源码快照，包含
ReSukiSU、SUSFS、配置和 S25 改动；不包含 .git、构建输出、签名私钥、原厂
boot 镜像或 Samsung 专有 vendor 模块。vendor-patches 中的 MAX77775 补丁
是候选方向，不属于 boot-only r21 payload。

构建复现请阅读 build/BUILDING-r21.md，并使用 configs/r7-6.6.152-r21.config。

## 免责声明

刷写自定义内核可能导致无法开机、数据丢失、保修或安全功能失效。作者和
贡献者不对设备损坏或数据损失负责。请先备份，并自行判断风险。

本项目以及所包含的第三方代码分别遵循各自许可证。Linux 内核源码按照
GPL-2.0 条款提供。

# S25 GKI 6.6.152 项目接管说明

> 更新时间：2026-09-07
> 目标设备：Samsung Galaxy S25 Ultra，SM-S938B，pa3q/pa3qxxx
> 当前已验证版本：Linux GKI 6.6.152，r28 ReSukiSU v35116 faccessat hotfix（用户确认成功开机）
> 回退基线：r26 FULL-CLEAN boot-only AK3

这份文档是给下一位维护者的“从哪里开始、哪些东西能刷、怎样复现和回退”的入口。源码根目录原有的 README.md 是 Android Common 上游补丁提交规范，不能代替本文件；先读本文件，再按需要阅读源码目录中的专项文档。

## 1. 项目目标与当前结论

项目是在 S25 的 Android Common/GKI 6.6 内核上集成 ReSukiSU + SUSFS，并处理一个与 USB-C 断开、息屏进入低功耗状态相关的偶发黑屏死机。

2026-08-25 的 Samsung persistent last-kmsg 已确认 Type-C 拔出死机的首次故障点：`xhci_free_virt_device+0x54/0x308` 在 `__dwc3_set_mode` 拆除主机控制器时访问空指针，fault VA 为 `0x12a0`。此前定制的“double-free workaround”丢弃了 `xhci_free_dev()` 保存的有效 `virt_dev`，重新读取已经被并发路径清空的 `xhci->devs[slot_id]`，随后访问 `dev->flags`。更早的一次 persistent crash 具有相同 PC，证明这是重复发生的同一问题。r22 在 xHCI 权威释放路径修复该竞态；MAX77775、DWC3、SCSI/UAS 和文件系统只是触发/传播链，不再作为本次已确认根因。

已经放弃的方向：

- 不再走 LKM/KPM/vendor_dlkm 方案；r22 是 builtin ReSukiSU、boot-only 包。
- 不修改或刷写 vendor_dlkm、system_dlkm、vendor_boot、dtbo，也不自动修改 vbmeta。
- 不把旧的 30700/source-copy ReSukiSU 构建当作当前版本。

## 2. 当前有效版本和可交付物

| 项目 | 当前值 |
| --- | --- |
| Kernel release | 6.6.152-pe17667d-abogkiS938BXXU9CZDP-4k |
| 当前已验证版本 | r28，builtin-only，R27 panic hotfix（用户确认成功开机） |
| 已验证回退基线 | r26 FULL-CLEAN |
| ReSukiSU | v4.2.0-rc1，版本码 35116 |
| ReSukiSU commit | f7829ddf548a18b851d653feb76b4a569b8fd2a4 |
| ReSukiSU source count | 4416（用于计算 35116） |
| SUSFS | v2.2.0，兼容 commit 7767a46 |
| 发布包 | release-r28/S25U-S938B-GKI-6.6.152-r28-ReSukiSU-v35116-SUSFS-FACCESSAT-HOTFIX-AK3.zip |
| 发布包 SHA256 | df0f89dc146a4fd3ab99d3eb4651cdbf69af1776cda21e9ef74d987df5e554c1 |
| 管理器 APK | release-r28/ReSukiSU_v4.2.0-rc1_35116-universal-release.apk |
| 管理器 APK SHA256 | 104fff78340e7d41b1d016ae3de029c3974a0e494ba1671b3b8e4b0c722241d5 |

R27 虽然构建成功，但真机在第一屏 panic。恢复到 r26 后读取 Samsung persistent
last-kmsg，确认 `/data/adb/ksud post-fs-data` 触发
`ksu_handle_faccessat+0x34`：旧调用方传入 `const char __user **`，v35116
handler 却按 `struct filename **` 解引用。R28 补齐 SUSFS commit `e13f390` 的
调用方路径转换，并完成新的全量 clean build，`BUILD_RC=0`。

注意：R27 已撤回，禁止刷写；用户已于 2026-09-07 确认 R28 成功开机。
后续仍需完成热点、USB-C 拔出和息屏稳定性测试；r26 继续作为已知可启动回退版本。

## 3. 目录结构

~~~text
s25_gki/
├─ configs/                        可复用构建配置
├─ docs/                           历史和当前版本文档
├─ patches/                        S25 专项补丁
├─ release-r26/                    已验证可启动的回退基线
├─ release-r27/                    已撤回的失败构建，仅保留故障记录
├─ release-r28/                    ReSukiSU v35116 faccessat 热修复候选
├─ S25-GKI-README.md               当前版本简述
├─ S25-SUSPEND-FIX.md              suspend workaround 与候选 vendor 方向
├─ S25-XHCI-DETACH-FIX.md          已确认的 Type-C 拔出 panic 根因与修复
├─ SOURCE-PROVENANCE.md            源码来源和版本溯源
├─ R28-CONTENTS.md                 r28 目录和安全边界速查
└─ README-S25-HANDOFF.md           本接管文档
~~~

本 Git 仓库保存发布件、配置、补丁和复现文档，不直接提交完整内核源码树。r28 沿用 r27 的 ext4 源码树并应用 `patches/susfs/S25-R28-FACCESSAT-ABI-FIX.patch`；来源和哈希见 `release-r28/BUILD-MANIFEST.txt`。

## 4. 源码改动说明

### 4.1 kernel/power/suspend.c

核心 workaround 是延迟选择 deep suspend：

~~~c
if (s25_suspend_force_deep && state == PM_SUSPEND_TO_IDLE &&
    valid_state(PM_SUSPEND_MEM)) {
        mem_sleep_current = PM_SUSPEND_MEM;
        state = PM_SUSPEND_MEM;
}
~~~

这段逻辑位于第一次真实的 suspend_devices_and_enter() 请求中，而不是早期 suspend_set_ops() 注册阶段。这样保留 vendor PM 初始化顺序，避免此前“开机第一屏卡住”的版本。USB power_supply notifier/cache 和原有 guard 仍保留，用于记录 USB 状态并在需要时保护 s2idle 路径。

内置参数（均可运行时通过 sysfs 修改）：

~~~text
/sys/module/suspend/parameters/s25_suspend_force_deep
/sys/module/suspend/parameters/s25_suspend_guard
/sys/module/suspend/parameters/s25_suspend_guard_usb_only
~~~

默认值为启用 deep 选择和 guard。开机后立即看到 /sys/power/mem_sleep 仍为 [s2idle] deep 不一定是失败；deep 选择刻意延迟到第一次真正休眠请求，成功走过一次后再观察选中项。

### 4.2 r22 xHCI Type-C 拔出竞态修复

- `drivers/usb/host/xhci-mem.c`：始终使用 `xhci_free_dev()` 保存的 `virt_dev`，不再被可能已清空的槽数组覆盖；DCBAA 和槽数组只在仍属于同一设备时清理。
- `drivers/usb/host/xhci.c`：删除与错误 workaround 配套的 unnamed bit-1 提前返回，恢复正常的 `WARN_ON(!virt_dev)` 失败路径。
- 新 Image 中不存在 `Device slot ... already being freed` 或 `being freed, aborting setup`。
- 反汇编显示故障偏移 `+0x54` 现在是条件匹配后的 DCBAA 清零，不再访问空 `dev->flags`。

### 4.3 保留的其他 USB 相关改动

- drivers/usb/dwc3/core.c：保留此前的 USB-C detach/susphy hotfix（dwc3_enable_susphy(dwc, false) 相关改动）。
- drivers/usb/core/hub.c：保留此前用于收集异常现场的日志级别改动（dev_dbg 调整为 dev_err）。

这些改动不能单独证明根因。后续若拿到完整 Samsung 6.6.98 vendor 源码，应先在独立分支逐项 A/B，而不是直接叠加更多 suspend 阻断逻辑。

### 4.4 ReSukiSU/SUSFS

drivers/kernelsu/ 已同步到最新成功发布的 ReSukiSU CI v35116 对应源码。源码拷贝没有父级 Git 元数据时，drivers/kernelsu/Kbuild 使用明确的 v35116 fallback，避免回退为旧的 30700/source-copy 身份；drivers/kernelsu/include/uapi/ 已 materialize 所需 UAPI 头文件。SUSFS 仍为 v2.2.0，并同步到 ReSukiSU 新接口所需的兼容 commit `7767a46`。R28 进一步补齐 SUSFS commit `e13f390` 的 `struct filename` 调用方改动，修复 R27 的启动 panic。

## 5. 可复现构建

以下 5.1/5.2 保留 r21/r22 的历史 Multipass 流程。r28 使用 WSL2 Ubuntu 26.04 的 native ext4 全量构建，精确输入、工具链、修复 commit 和产物哈希见 `release-r28/BUILD-MANIFEST.txt`；不要把两套输出目录混用。

### 5.1 构建环境

- Multipass 虚拟机：ai-linux，Ubuntu 24.04，4 CPU，约 3.8 GiB RAM。
- VM 内已启用 6 GiB /swapfile，用于 BTF/链接阶段降低 OOM 风险。
- 编译器：Ubuntu clang 18.1.3，LLVM_IAS=1。
- Windows 源码挂载到 VM：/home/ubuntu/s25-gki-android15-6.6-latest。
- 本地 overlay：/home/ubuntu/s25-gki-overlay。
- 输出目录：/tmp/s25-out-native-r21。
- ReSukiSU Git checkout：/home/ubuntu/ReSukiSU-main，必须核对上面的完整 commit。

build-r21/multipass-overlay.sh 会把 Windows 挂载树中需要执行的脚本和小型目录物化到 overlay，并将 drivers/kernelsu 指向 VM 内带 Git 元数据的 ReSukiSU checkout。不要在 Windows PowerShell 中直接假设 shell 可执行位和符号链接行为与 Linux 相同。

### 5.2 构建命令

在 ai-linux 中执行：

~~~sh
export PATH=/usr/lib/llvm-18/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib/llvm-18/lib:$LD_LIBRARY_PATH
export BISON_PKGDATADIR=/usr/share/bison
export M4=/usr/bin/m4
export BISON=/usr/bin/bison
export FLEX=/usr/bin/flex

make -C /home/ubuntu/s25-gki-overlay \
  O=/tmp/s25-out-native-r21 ARCH=arm64 \
  LLVM=/usr/lib/llvm-18/bin/ LLVM_IAS=1 -j8
~~~

构建前确认配置来自 build-r21/r7.config（或等价的 r7/r11-style 配置），并确认至少包含：CONFIG_KSU=y、CONFIG_KSU_SUSFS=y、CONFIG_DEBUG_INFO_BTF=y、CONFIG_DEBUG_INFO_BTF_MODULES=y、CONFIG_LTO_NONE=y；构建专用输出中关闭 CONFIG_LOCALVERSION_AUTO，不要把这个临时输出配置误写回正式 defconfig。

最少验证：

~~~sh
test -s /tmp/s25-out-native-r21/arch/arm64/boot/Image
test -s /tmp/s25-out-native-r21/vmlinux
grep -E '^CONFIG_(KSU|KSU_SUSFS|DEBUG_INFO_BTF)=' /tmp/s25-out-native-r21/.config
~~~

完整日志和最终文件已经复制到 build-r21/；日志中应能看到 ReSukiSU version code: 35089 和 BUILD_RC=0。重新构建后要更新 BUILD-MANIFEST.txt、SHA256SUMS.txt 和发布说明，不要复用旧哈希。

## 6. AK3 安全边界

r28 是 boot-only、单独活动槽位写入的 AnyKernel3 包。anykernel.sh 的关键约束：

~~~text
block=boot
is_slot_device=1
patch_vbmeta_flag=0
no_vbmeta_partition_patch=1
do.modules=0
device.name1=pa3q
device.name2=pa3qxxx
~~~

包内只应有内核 Image/配置/符号及 AK3 脚本和说明文件。发布前必须确认：

- 没有 vendor_dlkm.img、system_dlkm、vendor_boot、dtbo、.ko、KPM 或 LKM payload；
- anykernel.sh 和 tools/ak3-core.sh 通过 bash -n；
- 没有 flash_generic 或其他 vendor 分区写入调用；
- 未设置 vbmeta patch。

tools/ak3-core.sh 中仍可看到通用函数定义，但 r28 的 write_boot() 只执行 repack_ramdisk; flash_boot；不要根据未调用的通用函数误判包会写 vendor 分区。

## 7. 设备测试流程

先在手机上保存当前可启动 boot 镜像，再进行 A/B 测试。首次只安装 r28，不要同时恢复旧的 vendor_dlkm、启用监测模块或叠加其他内核模块。

开机后先记录：

~~~sh
adb shell su -c 'cat /proc/version; getprop ro.boot.slot_suffix'
adb shell su -c 'cat /sys/module/suspend/parameters/s25_suspend_force_deep'
adb shell su -c 'cat /sys/module/suspend/parameters/s25_suspend_guard'
adb shell su -c 'cat /sys/power/mem_sleep'
adb shell su -c 'cat /sys/class/power_supply/usb/online 2>/dev/null || true'
~~~

预期 s25_suspend_force_deep 为 Y。刚开机时 mem_sleep 仍显示 [s2idle] deep 可以是正常的延迟行为；第一次真实息屏休眠后再读取。测试矩阵至少包括：

1. 屏幕亮起时连接并正常识别移动硬盘，直接拔出，重复多次；
2. 屏幕亮起时连接有线耳机，直接拔出，重复多次；
3. 息屏前后分别重复存储和耳机拔出，保留 USB 连接作为对照；
4. 若再次死机，强制重启后先保存 `/data/log/dumpstate_lastkmsg_*` 和 `/sys/fs/pstore`，不要先改内核或清日志。

发生死机后重启，优先保存 pstore/ramoops 和内核日志：

~~~sh
adb shell su -c 'ls -l /sys/fs/pstore; dmesg -T > /data/local/tmp/dmesg-after-reboot.txt'
adb pull /sys/fs/pstore ./pstore-after-reboot
adb pull /data/local/tmp/dmesg-after-reboot.txt .
~~~

如果继续使用 ksu-suspend-watch，把模块输出与上述 pstore 一起提供；单独的 Android logcat 通常不足以判断 suspend/PMIC/USB-C 根因。

## 8. 卡一屏、卡开机或无法启动时的恢复

1. 不要反复刷写，也不要先动 vendor_dlkm。
2. 使用事先备份的原 boot 镜像，按设备已有的安全恢复流程恢复活动槽位。
3. 若只能进入 Download/Odin，优先恢复已验证能开机的 boot/相关官方镜像；恢复后再读取 getprop ro.boot.slot_suffix 和内核版本。
4. r28 不包含 vendor_dlkm，因此“还原 vendor_dlkm”不能替代还原 boot。

任何恢复动作都应由操作者确认目标槽位和镜像来源；本项目文档不执行自动刷机、重启或分区擦除。

## 9. 已知限制与下一步

- r28 保留的是 last-kmsg 已证明的 xHCI 空指针修复；只有重复真机拔出测试后才能确认设备层结果。
- 当前 deep-suspend 选择仍是独立 workaround，r28 为控制变量而保留，不能把它与 xHCI 根因修复混为一谈。
- r28 使用 Ubuntu clang 18.1.8，不是 Samsung 官方 release compiler；跨工具链重建需重新做启动和稳定性验证。
- 之前有“在早期 PM 注册阶段直接切 deep”导致卡第一屏的 r14 类失败方案，不能恢复该写法。
- 设备稳定性尚未替代长期真实用户测试；一次长时间不复现不等于根因消失。
- 若要做真正 vendor 层修复，需要取得匹配 SM-S938B/Android 16 的 Samsung 6.6.98（或对应版本）完整公开源码及模块 ABI，再针对 PDIC/USB-C suspend/resume 路径做最小补丁和独立 A/B。

建议接管顺序：

1. 先校验 `release-r28/SHA256SUMS.txt`，保存已知可启动 boot 和 r26 回退包；
2. 安装 r28 并完成首次启动、热点、移动硬盘/有线耳机拔出矩阵；
3. 复现时优先收集 Samsung persistent last-kmsg 和 pstore；
4. 只有在 r28 拔出基线稳定后，才逐项关闭 s25_suspend_force_deep、guard 或其他 USB hotfix 做 A/B；
5. 修改源码后重新构建、更新清单/校验和，并保留可回退的 boot。

## 10. 相关文件和来源

- [当前版本简述](S25-GKI-README.md)
- [suspend workaround 说明](S25-SUSPEND-FIX.md)
- [xHCI Type-C 拔出修复](S25-XHCI-DETACH-FIX.md)
- [源码来源与版本溯源](SOURCE-PROVENANCE.md)
- [r21 目录与安全边界](R21-CONTENTS.md)
- [r28 目录与安全边界](R28-CONTENTS.md)
- [r28 发布包说明](release-r28/README.md)
- [r28 构建清单](release-r28/BUILD-MANIFEST.txt)
- ReSukiSU 源码：[github.com/ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)
- 本次 ReSukiSU CI：[run 33939268200](https://github.com/ReSukiSU/ReSukiSU/actions/runs/33939268200)
- 对应 CI release：[ReSukiSU_33939268200](https://github.com/cctv18/ReSukiSU_CI/releases/tag/ReSukiSU_33939268200)

接管时如发现工作区与本文件不一致，以源码实际内容、BUILD-MANIFEST.txt 和 SHA256SUMS.txt 为准，并在本文件顶部更新日期和当前版本号。

## 11. r26 FULL-CLEAN 当前基线（2026-08-26）

r26 使用与已知可启动 r22 完全一致的 `.config`，在 Multipass `ai-linux`（8 CPU、约 5.8 GiB RAM）中以 LLVM 18 原生工具链完成全量 clean build；首次 `-j8` 被人工中止后以 `-j16` 续编，最终 `BUILD_RC=0`。用户已确认该版本正常开机。

交付包：

- `release-r26/S25U-S938B-GKI-6.6.152-r26-FULL-CLEAN-ReSukiSU-SUSFS-AK3.zip`
- 包 SHA-256：`a113d163717d0864182177bc465717e903af12a66079fe3f4beae36547865200`
- Image SHA-256：`b221c4ce00c17ca91bc3c5ecf8e3b7fdeb487c919eb5dc870df96ab4ff742b6c`
- `.config` SHA-256：`d7700e89a5f39941c4fa3374b66894f6fbb1ad1bd0490f7e215dc709924027f5`
- vmlinux SHA-256：`9278095d67f1df57b94d2c2002df47869a3834d0f929fd399fb96a3bdd76eb4e`

r26 仍是 boot-only：不含 `vendor_dlkm.img`、`system_dlkm`、LKM/KPM payload，不写 vendor 分区，不 patch vbmeta。Netfilter hotspot 相关 builtin 符号和 ReSukiSU/SUSFS 配置已在构建日志中复核。完整文件、日志、符号、配置和清单位于 `build-r26/`；包内说明位于 `release-r26/`。

注意：r26 的“正常开机”不等于 USB-C 拔出/息屏死机根因已彻底消失，后续仍需按既定测试矩阵和 pstore/last-kmsg 流程验证。

## 12. r27 失败记录与 r28 热修复（2026-09-07）

r27 把 builtin ReSukiSU 从 v35089 同步到 CI 构建 v35116（commit `f7829ddf548a18b851d653feb76b4a569b8fd2a4`），但遗漏了 SUSFS 新 handler 所需的调用方路径转换，真机已确认启动 panic，因此撤回。r28 仅补齐 commit `e13f390` 对应的 `faccessat`/`stat` 调用方接口并重新全量构建。

- R27：已撤回，禁止刷写
- R28 包：`release-r28/S25U-S938B-GKI-6.6.152-r28-ReSukiSU-v35116-SUSFS-FACCESSAT-HOTFIX-AK3.zip`
- R28 Image SHA-256：`e59c51f7973917604f0340638a5f55719baa399d14670cf1c1c6d759bab6accc`
- 管理器 SHA-256：`104fff78340e7d41b1d016ae3de029c3974a0e494ba1671b3b8e4b0c722241d5`
- R28 完整构建结果：`BUILD_RC=0`，构建日志未发现 compiler warning/error 行。

r28 保持 boot-only：不包含 `.ko`、KPM/LKM、`vendor_dlkm.img`、`system_dlkm`、`vendor_boot` 或 `dtbo` payload，不修改 vbmeta。用户已确认成功开机；热点、USB-C 拔出和息屏稳定性仍需继续验证，异常时回退 r26。

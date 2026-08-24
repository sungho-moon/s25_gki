# S25 GKI 6.6.152 项目接管说明

> 更新时间：2026-08-24  
> 目标设备：Samsung Galaxy S25 Ultra，SM-S938B，pa3q/pa3qxxx  
> 当前有效基线：Linux GKI 6.6.152，r21 boot-only AK3

> 测试状态：维护者已确认 r21 AK3 通过真机刷入/启动测试；这不等同于已经证明
> Samsung vendor 层的 MAX77775/PDIC 根因被修复，长期稳定性仍应保留 A/B 记录。

这份文档是给下一位维护者的“从哪里开始、哪些东西能刷、怎样复现和回退”的入口。源码根目录原有的 README.md 是 Android Common 上游补丁提交规范，不能代替本文件；先读本文件，再按需要阅读源码目录中的专项文档。

## 1. 项目目标与当前结论

项目是在 S25 的 Android Common/GKI 6.6 内核上集成 ReSukiSU + SUSFS，并处理一个与 USB-C 断开、息屏进入低功耗状态相关的偶发黑屏死机。

目前没有确认 Samsung vendor 层的真正根因。现象集中在 USB 断开后按电源键息屏，USB 保持连接时通常不能复现；日志曾出现 pdic_max77775、max77775_muic_stuck_check、USB-C IRQ 和 cnss runtime PM 相关活动。公共源码中缺少完整的 Samsung max77775/pdic_max77775 实现，因此 r21 的 suspend 改动应被视为可回退的源码 workaround，而不是 vendor 根因修复。

已经放弃的方向：

- 不再走 LKM/KPM/vendor_dlkm 方案；r21 是 builtin ReSukiSU、boot-only 包。
- 不修改或刷写 vendor_dlkm、system_dlkm、vendor_boot、dtbo，也不自动修改 vbmeta。
- 不把旧的 30700/source-copy ReSukiSU 构建当作当前版本。

## 2. 当前有效版本和可交付物

| 项目 | 当前值 |
| --- | --- |
| Kernel release | 6.6.152-pe17667d-abogkiS938BXXU9CZDP-4k |
| ReSukiSU | v4.2.0-rc1，版本码 35089，builtin-only |
| ReSukiSU commit | b2ac2fc8703ce9f5226e2a38a59f8b72f8a3005c |
| ReSukiSU source count | 4389（用于计算 35089） |
| SUSFS | v2.2.0 |
| 发布包 | release-r21/S25U-S938B-GKI-6.6.152-r21-SOURCE-DEEP-ReSukiSU-SUSFS-AK3.zip |
| 发布包 SHA256 | c93bd5326f93bf0b815b0207f949d12097969ff6a997237c097f3535306312d2 |
| 管理器 APK | release-r21/ReSukiSU_v4.2.0-rc1_35089-universal-release.apk |
| 管理器 APK SHA256 | 9e5e9157bb8b543d27e68646127eb957c89360f6fb37bf54d2a4906512857c46 |

源码构建已经完成，BUILD_RC=0；Image、BTF、MODPOST、Module.symvers 和配置的模块 BTF 目标均已生成。构建日志中有一个非致命的 udp_tunnel_nic_ops 版本生成警告，当前不影响产物，但后续若升级工具链应重新检查。

注意：Codex 没有自动刷入手机或重启设备；维护者已另行确认 r21 AK3 通过真机
刷入/启动测试。刷写前仍必须由接管者自行确认当前 boot 备份、活动槽位和恢复路径。

## 3. 目录结构

~~~text
s25-gki-android15-6.6-latest/
├─ kernel/                         内核源码（当前修改在 kernel/power/suspend.c）
├─ drivers/                        USB、ReSukiSU 等驱动源码
├─ vendor-patches/                 未打包进 boot-only AK3 的 vendor 候选补丁
├─ release-r21/                    可交付 AK3、管理器、清单、校验和
├─ build-r21/                      Image、vmlinux、.config、日志和构建脚本
├─ S25-GKI-README.md               当前版本简述
├─ S25-SUSPEND-FIX.md              suspend workaround 与候选 vendor 方向
├─ SOURCE-PROVENANCE.md            源码来源和版本溯源
├─ R21-CONTENTS.md                 目录和安全边界速查
└─ README-S25-HANDOFF.md           本接管文档
~~~

历史 out-r9 目录保留在源码树外的工作区中，只用于回溯，不能拿来冒充 r21 构建输入。旧的 30700 source-copy 备份也已移到工作区 backups/ 下。

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

### 4.2 保留的 USB 相关改动

- drivers/usb/dwc3/core.c：保留此前的 USB-C detach/susphy hotfix（dwc3_enable_susphy(dwc, false) 相关改动）。
- drivers/usb/core/hub.c：保留此前用于收集异常现场的日志级别改动（dev_dbg 调整为 dev_err）。

这些改动不能单独证明根因。后续若拿到完整 Samsung 6.6.98 vendor 源码，应先在独立分支逐项 A/B，而不是直接叠加更多 suspend 阻断逻辑。

### 4.3 ReSukiSU/SUSFS

drivers/kernelsu/ 已同步到 ReSukiSU CI v35089 对应源码。源码拷贝没有父级 Git 元数据时，drivers/kernelsu/Kbuild 使用明确的 v35089 fallback，避免回退为旧的 30700/source-copy 身份；drivers/kernelsu/include/uapi/ 已 materialize 六个 UAPI 头文件。

## 5. 可复现构建

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

r21 是 boot-only、单独活动槽位写入的 AnyKernel3 包。anykernel.sh 的关键约束：

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

tools/ak3-core.sh 中仍可看到通用函数定义，但 r21 的 write_boot() 只执行 repack_ramdisk; flash_boot；不要根据未调用的通用函数误判包会写 vendor 分区。

## 7. 设备测试流程

先在手机上保存当前可启动 boot 镜像，再进行 A/B 测试。首次只安装 r21，不要同时恢复旧的 vendor_dlkm 或叠加其他内核模块。

开机后先记录：

~~~sh
adb shell su -c 'cat /proc/version; getprop ro.boot.slot_suffix'
adb shell su -c 'cat /sys/module/suspend/parameters/s25_suspend_force_deep'
adb shell su -c 'cat /sys/module/suspend/parameters/s25_suspend_guard'
adb shell su -c 'cat /sys/power/mem_sleep'
adb shell su -c 'cat /sys/class/power_supply/usb/online 2>/dev/null || true'
~~~

预期 s25_suspend_force_deep 为 Y。刚开机时 mem_sleep 仍显示 [s2idle] deep 可以是正常的延迟行为；第一次真实息屏休眠后再读取。测试矩阵至少包括：

1. USB 断开，正常使用后按电源键息屏，观察 30 秒、5 分钟和长时间待机；
2. USB 连接时重复同样步骤作为对照；
3. 若能复现，记录“按键到黑屏”的时间、是否能被 USB 唤醒、最后一次 adb/dmesg 时间戳。

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
4. r21 不包含 vendor_dlkm，因此“还原 vendor_dlkm”不能替代还原 boot。

任何恢复动作都应由操作者确认目标槽位和镜像来源；本项目文档不执行自动刷机、重启或分区擦除。

## 9. 已知限制与下一步

- 当前 deep-suspend 选择是 workaround；不能宣称已经修复 max77775/pdic_max77775 vendor 根因。
- r21 使用 Ubuntu clang 18.1.3，不是 Samsung 官方 release compiler；跨工具链重建需重新做启动和稳定性验证。
- 之前有“在早期 PM 注册阶段直接切 deep”导致卡第一屏的 r14 类失败方案，不能恢复该写法。
- 设备稳定性尚未替代长期真实用户测试；一次长时间不复现不等于根因消失。
- 若要做真正 vendor 层修复，需要取得匹配 SM-S938B/Android 16 的 Samsung 6.6.98（或对应版本）完整公开源码及模块 ABI，再针对 PDIC/USB-C suspend/resume 路径做最小补丁和独立 A/B。

建议接管顺序：

1. 先校验 release-r21/SHA256SUMS.txt，保存已知可启动 boot；
2. 安装 r21 并完成 USB 断开/连接对照测试；
3. 复现时收集 pstore、dmesg、watchdog 输出；
4. 只有在 r21 基线稳定后，才逐项关闭 s25_suspend_force_deep、guard 或 USB hotfix 做 A/B；
5. 修改源码后重新构建、更新清单/校验和，并保留可回退的 boot。

## 10. 相关文件和来源

- [当前版本简述](S25-GKI-README.md)
- [suspend workaround 说明](S25-SUSPEND-FIX.md)
- [源码来源与版本溯源](../SOURCE-PROVENANCE.md)
- [r21 目录与安全边界](R21-CONTENTS.md)
- r21 发布包说明见对应 GitHub Release 的说明和校验清单
- [构建清单](BUILD-MANIFEST-r21.txt)
- ReSukiSU 源码：[github.com/ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)
- 本次 ReSukiSU CI：[run 32561471902](https://github.com/ReSukiSU/ReSukiSU/actions/runs/32561471902)
- 对应 CI release：[ReSukiSU_32561471902](https://github.com/cctv18/ReSukiSU_CI/releases/tag/ReSukiSU_32561471902)

接管时如发现工作区与本文件不一致，以源码实际内容、BUILD-MANIFEST.txt 和 SHA256SUMS.txt 为准，并在本文件顶部更新日期和当前版本号。

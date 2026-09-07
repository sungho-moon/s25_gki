# Samsung Galaxy S25 GKI 6.6.152

面向 Samsung Galaxy S25 Ultra `SM-S938B/pa3q` 的 Linux 6.6.152 GKI
实验构建。以 Samsung SM8750 vendor 兼容性代码为基础，保留 GKI KMI、BTF
和 SUSFS 集成。

当前同步版本：

- ReSukiSU v35116，源码 commit `f7829ddf548a18b851d653feb76b4a569b8fd2a4`
- ReSukiSU tag `v4.2.0-rc1`，SUSFS v2.2.0
- 内置 builtin-only，不包含 LKM、KPM 或 `kernelsu.ko`
- R27 已确认在 `ksu_handle_faccessat+0x34` 启动 panic，禁止刷写
- 当前已验证包为 `r28-ReSukiSU-v35116-SUSFS-FACCESSAT-HOTFIX`，用户确认成功开机
- r26 继续保留为已验证回退基线
- 不包含或写入 `vendor_dlkm`、`system_dlkm`、`vendor_boot`、`dtbo`
- `patch_vbmeta_flag=0`、`no_vbmeta_partition_patch=1`

## 息屏死机 workaround

`kernel/power/suspend.c` 在第一次真实 suspend 请求时，将默认 s2idle 请求
转换为 deep suspend；启动阶段不提前修改 PM operation 注册顺序。USB-offline
guard 仍保留为可切换诊断参数。

运行时检查：

```sh
su -c 'cat /sys/module/suspend/parameters/s25_suspend_force_deep'
su -c 'cat /sys/module/suspend/parameters/s25_suspend_guard'
su -c 'cat /sys/power/mem_sleep'
```

刚开机时 `mem_sleep` 仍可能显示 `[s2idle] deep`，因为 deep 选择被延迟到
第一次真实休眠请求；`s25_suspend_force_deep` 默认应为 `Y`。

## 编译与测试

- Ubuntu clang 18.1.8，LLVM_IAS=1
- WSL2 Ubuntu 26.04，native ext4 源码和输出目录
- 已完成 vmlinux、BTF、MODPOST、Image 和配置模块 BTF 构建
- 编译使用的 `vmlinux.symvers` 为 16,664 行

本源码树仅作 S25/pa3q 实验用途，不保证适配其他型号或固件。刷写前备份
当前活动槽位的原厂 `boot.img`，卡第一屏或循环重启时立即恢复原厂 boot。

LKM 版已舍弃；本树和 r28 AK3 均不包含 vendor_dlkm 模块实验内容。


# S25 GKI 6.6.152 r28 ReSukiSU v35116 faccessat hotfix

R28 修复 R27 在 `ksud post-fs-data` 启动期间发生的内核 panic。Samsung
persistent last-kmsg 将故障精确定位到 `ksu_handle_faccessat+0x34`：R27 的
`fs/open.c` 仍传递 `const char __user **`，而 ReSukiSU v35116 的 handler 已
改为接收 `struct filename **`，导致把用户态路径指针误当成内核结构解引用。

本构建补齐 SUSFS `gki-android15-6.6` commit `e13f390` 的匹配调用方改动：

- `do_faccessat()` 先调用 `getname_flags()` 取得内核态 `struct filename`；
- 将 `&fname` 传给 `ksu_handle_faccessat()`；
- 继续通过 `filename_lookup()` 查找并用 `putname()` 释放；
- `vfs_statx()` 使用相同的 `struct filename **` 接口和 no-SU guard。

其余配置、ReSukiSU v35116、SUSFS v2.2.0、r26 xHCI/TCPMSS/suspend 改动和
boot-only AnyKernel3 刷写路径均保持不变。包内不含 LKM/KPM、`.ko`、
`vendor_dlkm.img`、`system_dlkm`、`vendor_boot` 或 `dtbo`，也不修改 vbmeta。

全量 clean build 已完成，`BUILD_RC=0`，构建日志中 compiler error/warning
计数均为 0。反汇编确认调用前 `getname_flags()` 的返回值写入栈上 `fname`，
并以该栈地址作为第二参数传给 handler。

R28 尚未实机启动验证。首次测试只刷本 boot 包，不同时改 vendor 分区；刷写前
保留当前 boot 和 r26 回退包。R27 已确认不可启动，禁止继续刷写。

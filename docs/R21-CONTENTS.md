# S25 GKI 6.6.152 r21 目录说明

接管项目请先阅读 [README-S25-HANDOFF.md](README-S25-HANDOFF.md)；本文件用于快速查看 r21 文件布局和刷写安全边界。

本目录是当前有效的源码与构建归档。

维护者已确认 r21 boot-only AK3 通过真机刷入/启动测试；长期 USB 断开息屏
稳定性仍应按接管文档中的对照矩阵记录。

## 源码

- 根目录：Linux 6.6.152 S25 GKI 源码
- `kernel/power/suspend.c`：USB 断开息屏死机的 deep-suspend workaround
- `drivers/kernelsu/`：ReSukiSU v35089 源码
- `drivers/kernelsu/include/uapi/`：ReSukiSU UAPI 头文件
- `vendor-patches/`：未打包进 boot-only AK3 的 vendor 候选补丁

## 发布文件

`release-r21/` 包含：

- boot-only AnyKernel3 ZIP
- ReSukiSU v4.2.0-rc1/35089 管理器 APK
- 构建清单、CI 元数据和测试说明
- `SHA256SUMS.txt`

## 构建归档

`build-r21/` 包含最终 `Image`、`Image.gz`、`.config`、`Module.symvers`、
`System.map`、`vmlinux`、r7 配置、overlay 脚本和完整构建日志。构建使用
Ubuntu clang 18.1.3，LLVM_IAS=1，Multipass `ai-linux`，6 GiB swap。

## 安全边界

- AK3 只写活动槽位 `boot`
- 不含 `vendor_dlkm.img`、`.ko`、KPM 或 LKM
- 不调用 vendor_dlkm/system_dlkm/vendor_boot/dtbo 写入路径
- 不修改 vbmeta
- 旧 30700 source-copy 已移到工作区备份，不在本目录有效源码路径中
- 根目录现有的 `out-r9` 是历史构建目录，未作为 r21 构建输入，保持原样以便回溯

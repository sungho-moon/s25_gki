# S25 GKI 6.6.152 r28 上传包

Samsung Galaxy S25 Ultra SM-S938B/pa3q GKI 6.6.152 发布目录。r26 是已实机确认可正常开机的回退基线；r27 因 `ksu_handle_faccessat` 启动 panic 已撤回；r28 是修正该接口错配后的待测版本。

## 内容
- 根目录：发布索引、配置、补丁和复现文档（完整源码通过发布资产获取）
- `release-r28/`：最新待测 boot-only AnyKernel3 热修复包、匹配管理器及说明
- `README-S25-HANDOFF.md`：接管、测试和恢复说明
- `R28-CONTENTS.md`：当前版本索引

## 排除内容
构建中间物、`out-r9` 和完整源码树未提交到本仓库；r26 发布目录作为已验证回退基线保留。

## 发布包 SHA-256

见 `release-r28/SHA256SUMS.txt`。

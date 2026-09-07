# S25 GKI 6.6.152 r28 上传包

Samsung Galaxy S25 Ultra SM-S938B/pa3q GKI 6.6.152 发布目录。r27 因 `ksu_handle_faccessat` 启动 panic 已撤回；r28 修正该接口错配后已由用户确认成功开机，r26 继续保留为回退基线。

## 内容
- 根目录：发布索引、配置、补丁和复现文档（完整源码通过发布资产获取）
- `release-r28/`：最新已验证 boot-only AnyKernel3 热修复包、匹配管理器及说明
- `README-S25-HANDOFF.md`：接管、测试和恢复说明
- `R28-CONTENTS.md`：当前版本索引

## 排除内容
构建中间物、`out-r9` 和完整源码树未提交到本仓库；r26 发布目录作为已验证回退基线保留。

## 发布包 SHA-256

见 `release-r28/SHA256SUMS.txt`。

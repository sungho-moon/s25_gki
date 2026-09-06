# r27 交付目录

更新时间：2026-09-06

## 状态

> **已撤回，禁止刷写。** 真机启动 panic 位于
> `ksu_handle_faccessat+0x34`；使用 r26 回退或 r28 热修复候选。

- 设备：Samsung Galaxy S25 Ultra（SM-S938B，pa3q/pa3qxxx）
- 内核：Linux GKI 6.6.152
- ReSukiSU：v35116，commit `f7829ddf548a18b851d653feb76b4a569b8fd2a4`
- SUSFS：v2.2.0，匹配接口 commit `7767a46`
- 构建：`BUILD_RC=0`，尚未实机刷写/启动验证
- 类型：boot-only AnyKernel3；不写 vendor 分区，不修改 vbmeta

## release-r27

- `S25U-S938B-GKI-6.6.152-r27-ReSukiSU-v35116-SUSFS-AK3.zip`：待实机验证刷机包
  - SHA-256：`340d0cc46ab02a52cad95fa32637b2e2c2a916fbaea36afe96186499d440cd44`
- `ReSukiSU_v4.2.0-rc1_35116-universal-release.apk`：匹配管理器
  - SHA-256：`104fff78340e7d41b1d016ae3de029c3974a0e494ba1671b3b8e4b0c722241d5`
- `README.md`、`BUILD-MANIFEST.txt`：版本说明和构建清单
- `RESUKISU-CI-METADATA.txt`：ReSukiSU CI 来源
- `S25-R27-BUILD-NOTES.md`：同步、兼容和构建记录
- `SHA256SUMS.txt`：发布包和管理器校验和

R26 是已确认可正常开机的回退基线；R27 在完成首次启动、热点、USB-C 拔出
和息屏测试前不得替代该基线。

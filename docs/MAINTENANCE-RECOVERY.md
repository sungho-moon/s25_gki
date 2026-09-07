# 在新电脑上恢复 S25 GKI 维护环境

这份说明的目标是：即使原电脑、WSL 和本地构建目录全部丢失，也能仅凭
GitHub 仓库与 Release 资产恢复 R28 源码、重新构建并继续开发。

## GitHub 中保存了什么

- `main`：配置、补丁、构建脚本、AK3、管理器和故障记录。
- Release `v6.6.152-r28`：完整 ext4 源码快照、AK3、管理器和统一校验和。
- tag `v6.6.152-r28`：与 Release 对应的不可变 Git 提交。
- `release-r26/`：R28 发生新问题时的已验证回退包。

不要只备份 Windows 上解压后的源码。Linux 同时存在 `xt_TCPMSS.c` 和
`xt_tcpmss.c` 等大小写不同的文件，放到 NTFS/默认 Windows 目录可能丢失其中
一个。源码必须在 WSL2 的 Linux 文件系统（例如 `/home/<user>/`）中解压和构建。

## 1. 准备环境

推荐 WSL2 Ubuntu 26.04、至少 20 GiB 可用空间和 8 GiB RAM/Swap。安装依赖：

```sh
sudo apt update
sudo apt install -y \
  build-essential bc bison flex cpio rsync git curl zstd \
  clang-18 lld-18 llvm-18 libssl-dev libelf-dev dwarves python3
```

## 2. 获取仓库和源码

```sh
cd "$HOME"
git clone https://github.com/sungho-moon/s25_gki.git
cd s25_gki
git checkout v6.6.152-r28

curl -fL -O \
  https://github.com/sungho-moon/s25_gki/releases/download/v6.6.152-r28/s25-gki-6.6.152-r28-source.tar.zst
curl -fL -O \
  https://github.com/sungho-moon/s25_gki/releases/download/v6.6.152-r28/SHA256SUMS-r28.txt

sha256sum -c SHA256SUMS-r28.txt --ignore-missing
tar --zstd -xf s25-gki-6.6.152-r28-source.tar.zst -C "$HOME"
```

解压后应得到：

```text
$HOME/s25-gki-6.6.152-r28-source/
```

## 3. 重新构建 R28

```sh
cd "$HOME/s25_gki"
JOBS=12 bash build/build-r28.sh "$HOME/s25-gki-6.6.152-r28-source"
```

默认输出目录是 `$HOME/out-r28`。也可以指定：

```sh
OUT_DIR="$HOME/builds/r28" JOBS=8 \
  bash build/build-r28.sh "$HOME/s25-gki-6.6.152-r28-source"
```

脚本会复用 `configs/r28-6.6.152.config`，执行 `olddefconfig` 和完整内核构建，
然后检查 `Image`、`vmlinux`、`vmlinux.symvers` 并输出 SHA-256。

## 4. 继续开发

1. 从 `main` 创建新分支，不要直接覆盖 R28 tag。
2. 先搜索并复用现有实现；S25 补丁位于 `patches/`，ReSukiSU 在
   `drivers/kernelsu/`。
3. 每个版本使用新的输出目录，避免旧对象污染。
4. 全量构建后检查 ReSukiSU 身份、KSU/SUSFS 配置、TCPMSS target 和关键符号。
5. 复制 `release-r28/` 为新发布目录，以现有 AK3 为模板，只替换经过验证的
   `Image`，同步更新 `anykernel.sh` 版本字符串、清单和 SHA-256。
6. `bash -n anykernel.sh tools/ak3-core.sh`、`unzip -t`，并确认包中不存在
   `.ko`、KPM/LKM、vendor/system_dlkm、vendor_boot、dtbo 或 vbmeta 修改。
7. 真机首次只测试 boot；成功后再更新 README 状态并发布新 tag/Release。

## 5. R28 必须保留的修复

- `patches/susfs/S25-R28-FACCESSAT-ABI-FIX.patch`：修复 R27 的
  `ksu_handle_faccessat` 用户指针/`struct filename` 接口错配。
- `patches/vendor/S25-MAX77775-SUSPEND-RACE.patch`：仅为历史/实验记录，不要
  未经重新验证直接启用。
- R26/R28 文档中的 xHCI saved-device、TCPMSS 和延迟 deep-suspend 改动。

完整源码快照已经包含 R28 最终状态，不需要再次套用 R28 faccessat 补丁；该
补丁用于审计或从 R27 源码升级。重复应用会失败，这是预期行为。

## 6. 发布前最低验证

```sh
test -s "$OUT_DIR/arch/arm64/boot/Image"
grep -E '^(CONFIG_KSU|CONFIG_KSU_SUSFS|CONFIG_NETFILTER_XT_TARGET_TCPMSS)=' \
  "$OUT_DIR/.config"
strings "$OUT_DIR/arch/arm64/boot/Image" | grep -m1 ReSukiSU
llvm-nm-18 "$OUT_DIR/vmlinux" | grep -E 'ksu_handle_faccessat|tcpmss_tg_init'
```

构建成功不等于真机稳定。必须分别记录“能编译”“能启动”“热点通过”以及
“USB-C/息屏压力测试通过”，不要把它们合并成一个结论。

# S25 Type-C 拔出 xHCI 竞态修复

## 已确认故障

Samsung persistent last-kmsg 中两次崩溃具有相同 PC：
`xhci_free_virt_device+0x54/0x308`。最新调用链为：

```text
__dwc3_set_mode
  dwc3_host_exit
    platform_device_unregister
      xhci_plat_remove
        usb_remove_hcd
          usb_disconnect
            xhci_free_dev
              xhci_free_virt_device
```

panic 访问虚拟地址 `0x12a0`。故障时设备指针为 NULL；`0x12a0`
正是旧定制 `dev->flags` guard 使用的结构偏移。

## 根因

`xhci_free_dev()` 在禁用 slot 前正确保存了 `xhci->devs[slot_id]`。
旧 workaround 随后却在 `xhci_free_virt_device()` 内丢弃该保存指针，重新读取
slot 数组。并发的 slot disable/IRQ 路径可能已经清空数组项，紧接着的
`test_and_set_bit()` 因而解引用 NULL。

## r22 修改

- 整个 teardown 始终使用保存的 `struct xhci_virt_device *dev`。
- 只有 DCBAA 仍指向 `dev->out_ctx->dma` 时才清零。
- 只有 `xhci->devs[slot_id]` 仍等于保存的 `dev` 时才清零。
- 删除 setup/free 路径中配套的 unnamed bit-1 提前返回。

该实现恢复 Android/common 6.6 stable 已有的 slot-reuse 所有权模型，不修改
Samsung vendor 模块或任何动态内核模块分区。

## 验证边界

新 Image 中旧错误字符串数量为 0；反汇编确认原故障偏移 `+0x54` 现在是
条件 DCBAA 清理。是否完全解决真机问题仍需在 SM-S938B/pa3q 上反复测试
移动硬盘和有线耳机拔出。首次 r22 测试不要同时更改 `vendor_dlkm`、vbmeta、
DTBO 或监测模块。

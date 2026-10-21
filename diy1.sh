#!/bin/bash
set -e

echo "========================================="
echo "ImmortalWrt 25.12 DIY1 - 挂载专用源与基础编译优化"
echo "========================================="

# 使用 O2 级别优化与去掉多余内核编译减负
sed -i 's,Os,O2 -march=x86-64-v2,g' include/target.mk
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-efi.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-iso.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-pc.cfg

# 置顶挂载 217heidai 专为 openwrt-25.12 修复的软件包源（解决新版 apk 依赖断层）
{ echo 'src-git zz_openwrtpackages https://github.com/217heidai/OpenWrt-Packages.git;openwrt-25.12'
  echo 'src-git qmodem https://github.com/FUjr/QModem.git;main'
  cat feeds.conf.default; } > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default

echo "========================================="
echo "DIY1 配置完成"
echo "========================================="
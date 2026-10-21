#!/bin/bash
set -e

echo "========================================="
echo "ImmortalWrt 25.12 DIY2 - 注入配置与精简底座"
echo "========================================="

# 定义高效的配置开关辅助函数
function config_del(){
    yes="CONFIG_$1=y"
    no="# CONFIG_$1 is not set"
    sed -i "s/$yes/$no/" .config
}

function config_add(){
    yes="CONFIG_$1=y"
    no="# CONFIG_$1 is not set"
    sed -i "s/${no}/${yes}/" .config
    if ! grep -q "$yes" .config; then
        echo "$yes" >> .config
    fi
}

function config_package_del(){
    config_package="PACKAGE_$1"
    config_del "$config_package"
}

function config_package_add(){
    config_package="PACKAGE_$1"
    config_add "$config_package"
}

# 1. 基础系统属性修改
# 修改默认 root 密码为 password
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow
# 修改默认 IP 为 192.168.5.1
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate
# 修改主机名
sed -i "s/hostname='OpenWrt'/hostname='ImmortalWrt'/g" package/base-files/files/bin/config_generate
# 默认主题切为 Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 2. 精简不必要的驱动与组件（减小体积、加快编译）
config_package_del kmod-sound-core
config_package_del kmod-acpi-video
config_package_del kmod-drm
config_package_del kmod-drm-i915
config_package_del kmod-drm-kms-helper

# 3. 按需静态拉满你的核心插件与工具
config_package_add luci-theme-argon
config_package_del luci-app-argon-config
config_package_add luci-app-openclash
config_package_add luci-app-dockerman
config_package_add luci-app-partexp
config_package_add luci-app-ttyd
config_package_add kmod-tcp-bbr
config_package_add nano
config_package_add coremark
config_package_add autocore

# 4. 镜像分区与生成策略调优
sed -i "/CONFIG_TARGET_KERNEL_PARTSIZE/d" .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=32" >> .config
sed -i "/CONFIG_TARGET_ROOTFS_PARTSIZE/d" .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=2048" >> .config
sed -i "/CONFIG_GRUB_TIMEOUT/d" .config
echo 'CONFIG_GRUB_TIMEOUT="1"' >> .config

# 关闭不需要的镜像格式，只留 x86 常用 EFI 固件
config_del TARGET_ROOTFS_EXT4FS
config_del GRUB_IMAGES

echo "========================================="
echo "DIY2 优化补丁注入完成"
echo "========================================="

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


# 3.新增必要和应用
# Firmware
config_package_add intel-microcode

# luci
config_package_add luci
config_package_add default-settings-chn

# bbr
config_package_add kmod-tcp-bbr

# coremark cpu 跑分
config_package_add coremark

# autocore + lm-sensors-detect： cpu 频率、温度
config_package_add autocore
config_package_add lm-sensors-detect

# nano 替代 vim
config_package_add nano

# autoreboot
#config_package_add luci-app-autoreboot

# tty 终端
config_package_add luci-app-ttyd

# usb 2.0 3.0 支持
config_package_add kmod-usb2
config_package_add kmod-usb3

# usb 网络支持
config_package_add usbmuxd
config_package_add usbutils
config_package_add usb-modeswitch
config_package_add kmod-usb-serial
config_package_add kmod-usb-serial-option
config_package_add kmod-usb-net-rndis
config_package_add kmod-usb-net-ipheth

# argon主题
config_package_add luci-theme-argon

#  passwall
config_package_add luci-app-passwall
config_package_add luci-app-passwall_INCLUDE_V2ray_Geoview
config_package_del luci-app-passwall_INCLUDE_Haproxy
config_package_del luci-app-passwall_INCLUDE_Hysteria
config_package_del luci-app-passwall_INCLUDE_NaiveProxy
config_package_del luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client
config_package_del luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server
config_package_del luci-app-passwall_INCLUDE_Shadow_TLS
config_package_del luci-app-passwall_INCLUDE_Simple_Obfs
config_package_add luci-app-passwall_INCLUDE_SingBox
config_package_add luci-app-passwall_INCLUDE_V2ray_Geodata
config_package_del luci-app-passwall_INCLUDE_V2ray_Plugin
config_package_add luci-app-passwall_INCLUDE_Xray
config_package_del luci-app-passwall_INCLUDE_Xray_Plugin

# 其他常见应用
config_package_add luci_app-rtp2httpd
config_package_add luci-app-openclash
config_package_add luci-app-dockerman
config_package_add luci-app-partexp


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

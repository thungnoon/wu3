#!/bin/bash
set -e

echo "========================================="
echo "ImmortalWrt 25.12 DIY2 - 严格声明式配置注入脚本"
echo "========================================="

# 1. 定义严密的配置开关辅助函数（带 Fallback 保底，确保 sed 没匹配上时强制写入）
function config_del(){
    yes="CONFIG_$1=y"
    no="# CONFIG_$1 is not set"
    sed -i "s/$yes/$no/" .config
    if ! grep -q "$no" .config; then
        echo "$no" >> .config
    fi
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
    package="PACKAGE_$1"
    config_del $package
}

function config_package_add(){
    package="PACKAGE_$1"
    config_add $package
}

# 2. 基础系统属性修改
# 修改默认 root 密码为 password
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow
# 修改默认 IP 为 192.168.5.1
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate
# 修改主机名
sed -i "s/hostname='OpenWrt'/hostname='ImmortalWrt'/g" package/base-files/files/bin/config_generate
# 默认主题切为 Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 3. 精简不必要的驱动与组件
config_package_del kmod-sound-core
config_package_del kmod-acpi-video
config_package_del kmod-drm
config_package_del kmod-drm-i915
config_package_del kmod-drm-kms-helper

# 4. 新增必要组件与应用
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

# tty 终端
config_package_add luci-app-ttyd

# usb 2.0 3.0 支持
config_package_add kmod-usb2
config_package_add kmod-usb3

# usb 网络支持（显式剔除针对苹果设备的 usbmuxd 与 ipheth 共享驱动）
config_package_add usbutils
config_package_add usb-modeswitch
config_package_add kmod-usb-serial
config_package_add kmod-usb-serial-option
config_package_add kmod-usb-net-rndis
config_package_del usbmuxd
config_package_del kmod-usb-net-ipheth
config_package_del libimobiledevice
config_package_del libplist

# argon主题
config_package_add luci-theme-argon

# passwall
config_package_add luci-app-passwall
config_package_add luci-app-passwall_INCLUDE_SingBox
config_package_add luci-app-passwall_INCLUDE_Xray
config_package_add luci-app-passwall_INCLUDE_V2ray_Geodata
config_package_del luci-app-passwall_INCLUDE_V2ray_Geoview
config_package_del luci-app-passwall_INCLUDE_Haproxy
config_package_del luci-app-passwall_INCLUDE_Hysteria
config_package_del luci-app-passwall_INCLUDE_NaiveProxy
config_package_del luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client
config_package_del luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server
config_package_del luci-app-passwall_INCLUDE_Shadow_TLS
config_package_del luci-app-passwall_INCLUDE_Simple_Obfs
config_package_del luci-app-passwall_INCLUDE_V2ray_Plugin
config_package_del luci-app-passwall_INCLUDE_Xray_Plugin

# 其他常见应用
config_package_add luci-app-rtp2httpd
config_package_add luci-app-openclash
config_package_add luci-app-dockerman
config_package_add luci-app-partexp

# 5. 镜像分区与生成策略调优
sed -i "/CONFIG_TARGET_KERNEL_PARTSIZE/d" .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=32" >> .config
sed -i "/CONFIG_TARGET_ROOTFS_PARTSIZE/d" .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=2048" >> .config
sed -i "/CONFIG_GRUB_TIMEOUT/d" .config
echo 'CONFIG_GRUB_TIMEOUT="1"' >> .config

# 关闭不需要的镜像格式
config_del TARGET_ROOTFS_EXT4FS
config_del GRUB_IMAGES

echo "========================================="
echo "DIY2 严谨注入完成"
echo "========================================="

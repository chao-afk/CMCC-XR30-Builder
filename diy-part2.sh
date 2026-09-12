#!/bin/bash
#
# Thanks for https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

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
    package="PACKAGE_$1"
    config_del $package
}

function config_package_add(){
    package="PACKAGE_$1"
    config_add $package
}

function drop_package(){
    if [ "$1" != "golang" ];then
        # feeds/base -> package
        find package/ -follow -name $1 -not -path "package/custom/*" | xargs -rt rm -rf
        find feeds/ -follow -name $1 -not -path "feeds/base/custom/*" | xargs -rt rm -rf
    fi
}

function clean_packages(){
    path=$1
    dir=$(ls -l ${path} | awk '/^d/ {print $NF}')
    for item in ${dir}
        do
            drop_package ${item}
        done
}

function config_device_del(){
    device="TARGET_DEVICE_$1"
    packages="TARGET_DEVICE_PACKAGES_$1"

    packages_list="CONFIG_TARGET_DEVICE_PACKAGES_$1="""
    deleted_packages_list="# CONFIG_TARGET_DEVICE_PACKAGES_$1 is not set"

    config_del $device
    sed -i "s/$packages_list/$deleted_packages_list/" .config
}

function config_device_list(){
    grep -E 'CONFIG_TARGET_DEVICE_|CONFIG_TARGET_DEVICE_PACKAGES_' .config | while read -r line; do
        if [[ $line =~ CONFIG_TARGET_DEVICE_([^=]+)=y ]]; then
            chipset_device=${BASH_REMATCH[1]}
            chipset=${chipset_device%_DEVICE_*}
            device=${chipset_device#*_DEVICE_}
            echo "Chipset: $chipset, Model: $device"
        fi
    done | sort -u
}

function config_device_keep_only(){
    local keep_devices=("$@")
    grep -E 'CONFIG_TARGET_DEVICE_|CONFIG_TARGET_DEVICE_PACKAGES_' .config | while read -r line; do
        if [[ $line =~ CONFIG_TARGET_DEVICE_([^=]+)=y ]]; then
            chipset_device=${BASH_REMATCH[1]}
            device=${chipset_device#*_DEVICE_}
            if [[ ! " ${keep_devices[@]} " =~ " ${device} " ]]; then
                config_device_del $chipset_device
            fi
        fi
    done
}

config_device_list

# 只保留 CMCC‑XR30 设备
config_device_keep_only "cmcc_xr30"

# Modify default theme Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' $(find ./feeds/luci/collections/ -type f -name "Makefile")
config_package_add luci-theme-argon

# Delete unwanted packages
config_package_del luci-app-ssr-plus_INCLUDE_NONE_V2RAY
config_package_del luci-app-ssr-plus_INCLUDE_Shadowsocks_NONE_Client
config_package_del luci-app-ssr-plus_INCLUDE_ShadowsocksR_NONE_Server
config_package_del luci-theme-bootstrap-mod
config_package_del luci-app-ssr-plus_INCLUDE_ShadowsocksR_Rust_Client
config_package_del luci-app-ssr-plus_INCLUDE_ShadowsocksR_Rust_Server

# ========== 自定义软件包开始 ==========
## QModem 5G模组管理 (USB模组，关闭PCIe MHI依赖消除警告)
config_package_add luci-app-qmodem
config_package_del kmod-mhi-wwan
config_package_del quectel-CM-5G

## Web Terminal
config_package_add luci-app-ttyd
## IP‑Mac Binding
config_package_add luci-app-arpbind
## Wake on Lan
config_package_add luci-app-wol
## QR Code Generator
config_package_add qrencode
## Fish
config_package_add fish
## Temporarily disable USB3.0
config_package_add luci-app-usb3disable

## USB 5G 相关内核模块
config_package_add kmod-usb-net-huawei-cdc-ncm
config_package_add kmod-usb-net-ipheth
config_package_add kmod-usb-net-aqc111
config_package_add kmod-usb-net-rtl8152-vendor
config_package_add kmod-usb-net-sierrawireless
config_package_add kmod-usb-storage
config_package_add kmod-usb-ohci
config_package_add kmod-usb-uhci
config_package_add usb-modeswitch
config_package_add sendat

## bbr 拥塞控制
config_package_add kmod-tcp-bbr
## coremark cpu 跑分
config_package_add coremark
## autocore + lm‑sensors‑detect： cpu 频率、温度
config_package_add autocore
config_package_add lm-sensors-detect
## 定时重启
config_package_add luci-app-autoreboot
## 多拨 负载均衡 mwan3
config_package_add kmod-macvlan
config_package_add mwan3
config_package_add luci-app-mwan3

## frpc (注释，如需启用取消下面注释)
# config_package_add luci-app-frpc
## mosdns (注释)
# config_package_add luci-app-mosdns

## 工具
config_package_add curl
config_package_add socat
## 磁盘工具
config_package_add gdisk
config_package_add sgdisk
## Vim‑Full
config_package_add vim-full
## iperf 测速
config_package_add iperf

# MentoHUST 锐捷认证
git clone https://github.com/sbwml/luci-app-mentohust package/mentohust
config_package_add luci-app-mentohust

# Third‑party custom packages
mkdir -p package/custom
git clone --depth 1  https://github.com/217heidai/OpenWrt-Packages.git package/custom
clean_packages package/custom


## Passwall2 科学上网
config_package_add luci-app-passwall2
config_package_add iptables-mod-socket
config_package_add luci-app-passwall2_Iptables_Transparent_Proxy
config_package_add luci-app-passwall2_INCLUDE_Hysteria

# 关闭不需要的passwall2组件，缩小固件体积
config_package_del luci-app-passwall2_Nftables_Transparent_Proxy
config_package_del luci-app-passwall2_INCLUDE_Shadowsocks_Libev_Client
config_package_del luci-app-passwall2_INCLUDE_Shadowsocks_Libev_Server
config_package_del luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Client
config_package_del luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Server
config_package_del luci-app-passwall2_INCLUDE_ShadowsocksR_Libev_Client
config_package_del luci-app-passwall2_INCLUDE_ShadowsocksR_Libev_Server
config_package_del luci-app-passwall2_INCLUDE_Trojan_Plus
config_package_del luci-app-passwall2_INCLUDE_Simple_Obfs
config_package_del luci-app-passwall2_INCLUDE_tuic_client

config_package_del shadowsocks-libev-config
config_package_del shadowsocks-libev-ss-local
config_package_del shadowsocks-libev-ss-redir
config_package_del shadowsocks-libev-ss-server
config_package_del shadowsocksr-libev-ssr-local
config_package_del shadowsocksr-libev-ssr-redir
config_package_del shadowsocks-libev-ssr-server
config_package_del shadowsocks-rust
config_package_del simple-obfs
rm -rf package/custom/shadowsocks-rust
rm -rf package/custom/simple-obfs

## 定时任务工具
config_package_add luci-app-autotimeset
config_package_add luci-lib-ipkg

## 终端复用
config_package_add byobu
config_package_add tmux

# ## Frp Latest version patch (已注释，需要再打开)
# FRP_MAKEFILE_PATH="feeds/packages/net/frp/Makefile"
# FRP_LATEST_RELEASE=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
# if [ -z "$FRP_LATEST_RELEASE" ]; then
#   echo "无法获取最新的 Release 名称"
#   exit 1
# fi
# FRP_LATEST_VERSION=${FRP_LATEST_RELEASE#v}
# FRP_PKG_NAME="frp"
# FRP_PKG_SOURCE="${FRP_PKG_NAME}-${FRP_LATEST_VERSION}.tar.gz"
# FRP_PKG_SOURCE_URL="https://codeload.github.com/fatedier/frp/tar.gz/v${FRP_LATEST_VERSION}?"
# curl -L -o "$FRP_PKG_SOURCE" "$FRP_PKG_SOURCE_URL"
# FRP_PKG_HASH=$(sha256sum "$FRP_PKG_SOURCE" | awk '{print $1}')
# rm -r "$FRP_PKG_SOURCE"
# sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=${FRP_LATEST_VERSION}/" "$FRP_MAKEFILE_PATH"
# sed -i "s/^PKG_HASH:=.*/PKG_HASH:=${FRP_PKG_HASH}/" "$FRP_MAKEFILE_PATH"
# echo "已更新 Makefile 中的 PKG_VERSION 和 PKG_HASH"

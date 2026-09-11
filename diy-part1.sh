#!/bin/bash
#
# Thanks for https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.

## 1. 添加 QModem 5G模组软件源到 feeds.conf.default
sed -i '$a src-git qmodem https://github.com/FUjr/QModem.git;main' feeds.conf.default

## 2. 编译 Modem‑Manager‑Webui 前端，输出静态文件打包进固件 /www/webui
# 清理旧文件
rm -rf files/www/webui
mkdir -p files/www
# 创建临时编译目录
rm -rf temp_webui_build
mkdir -p temp_webui_build

# 拉取Webui源码到临时目录
git clone --depth 1 https://github.com/panasonic850218/Webui temp_webui_build/src
cd temp_webui_build/src

# 安装 nodejs + pnpm (Github Actions Ubuntu runner环境)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pnpm

# 安装依赖并执行生产构建
pnpm install
pnpm build

# 将编译完成的dist静态产物复制到固件files目录
cp -r dist/* ../../files/www/webui/

# 返回源码根目录，清理临时编译目录
cd ../../
rm -rf temp_webui_build

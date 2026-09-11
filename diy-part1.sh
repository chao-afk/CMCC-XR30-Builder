#!/bin/bash
#
# Thanks for https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (After Update feeds)
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
# 拉取Webui静态前端文件，放到files目录，打包进固件 /www/webui
rm -rf files/www/webui
mkdir -p files/www/webui
git clone https://github.com/panasonic850218/Webui files/www/webui

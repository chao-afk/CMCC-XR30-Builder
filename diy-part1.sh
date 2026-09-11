#!/bin/bash
#
# Thanks for https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# 2. 获取 Modem-Manager-Webui 静态网页，无需编译
# 创建固件files目录，最终固件内路径 /www/webui
rm -rf files/www/webui
mkdir -p files/www
# 临时目录拉取仓库
rm -rf temp_webui
mkdir -p temp_webui
git clone --depth 1 https://github.com/panasonic850218/Webui temp_webui
# 仓库里 web/ 文件才是真正静态网页，复制到固件目录
cp -r temp_webui/web/* files/www/webui/
# 清理临时下载目录
rm -rf temp_webui

#! /usr/bin/zsh

# 以下指令均在Hexo目录下操作，先定位到Hexo目录
# 查看当前版本，判断是否需要升级
# hexo version

# 全局升级hexo-cli
# npm i hexo-cli -g

# 再次查看版本，看hexo-cli是否升级成功
# hexo version

# 安装npm-check，若已安装可以跳过
# npm install -g npm-check

# 检查系统插件是否需要升级
npm-check --skip-unused &&

# 安装npm-upgrade，若已安装可以跳过
# npm install -g npm-upgrade &&

# 更新package.json
npm-upgrade &&

# 更新全局插件
npm update -g &&

# 更新系统插件
npm update --save &&

# 再次查看版本，判断是否升级成功
hexo version

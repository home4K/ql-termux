#!/bin/bash
set -e

echo "==== 安装 Debian 容器 ===="
proot-distro install debian || true

echo "==== 进入 Debian 容器执行安装 ===="
proot-distro login debian -- bash <<'EOF'
set -e

# 更新系统
apt update && apt upgrade -y
apt install curl wget git nano jq -y

# 使用国内 npm 镜像加速
npm_registry="https://registry.npmmirror.com"

# 安装 Node.js 16 和 npm
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt install -y nodejs
mkdir -p /tmp/npm-cache-empty
npm config set cache /tmp/npm-cache-empty
npm config set registry $npm_registry

# 安装 pm2（离线 tgz + 安装依赖）
pm2_version=$(npm view pm2 version --registry=$npm_registry)
wget "$npm_registry/pm2/-/pm2-$pm2_version.tgz" -O pm2.tgz
tar -xvf pm2.tgz && cd package
npm install --registry=$npm_registry
npm install -g . --registry=$npm_registry
pm2 -v

# 安装青龙面板
cd ~
git clone -b master https://github.com/whyour/qinglong.git
cd qinglong
npm install --registry=$npm_registry

# 启动青龙面板
pm2 start ./back/server.js --name qinglong
pm2 save

echo "==== 安装完成 ===="
echo "访问地址: http://127.0.0.1:5700"
EOF

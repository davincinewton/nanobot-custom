#!/bin/bash
# Cloudflared Setup Script for nanobot Web Channel

set -e

echo "🔧 设置 Cloudflare Tunnel..."

# 检查是否已安装
if command -v cloudflared &> /dev/null; then
    echo "✅ cloudflared 已安装"
else
    echo "📦 安装 cloudflared..."
    sudo dpkg -i /tmp/cloudflared.deb
    sudo apt-get install -f -y > /dev/null 2>&1
fi

# 创建配置目录
mkdir -p ~/.cloudflared

# 检查是否已有认证文件
if [ ! -f ~/.cloudflared/*.json ]; then
    echo "📝 创建新的隧道配置..."
    echo "请运行以下命令进行认证："
    echo "  cloudflared tunnel login"
    echo ""
    echo "认证后，配置文件将保存在 ~/.cloudflared/"
    exit 0
fi

# 创建隧道配置
TUNNEL_NAME="nanobot-web-channel"
CONFIG_FILE=~/.cloudflared/${TUNNEL_NAME}.yaml

echo "📝 创建隧道配置：$CONFIG_FILE"

cat > $CONFIG_FILE << EOF
tunnel: $TUNNEL_NAME
credentials-file: /home/yl/.cloudflared/$(ls ~/.cloudflared/*.json | tail -1 | xargs basename)

ingress:
  - hostname: nanobot-web.${CLOUDFLARE_SUBDOMAIN:-nanobot}.trycloudflare.com
    service: http://localhost:5000
  - service: http_status:404
EOF

echo "✅ 隧道配置已创建"
echo ""
echo "🚀 启动隧道..."
cloudflared tunnel run $TUNNEL_NAME &
TUNNEL_PID=$!

echo "隧道已启动 (PID: $TUNNEL_PID)"
echo "访问地址：https://nanobot-web.${CLOUDFLARE_SUBDOMAIN:-nanobot}.trycloudflare.com"
echo ""
echo "要停止隧道，运行："
echo "  pkill cloudflared"

#!/bin/bash
# Cloudflared User Service Setup for nanobot Web Channel

set -e

CLOUDFLARED_PATH="/home/yl/.local/bin/cloudflared"
CONFIG_DIR="/home/yl/.config/cloudflared"
SERVICE_DIR="/home/yl/.config/systemd/user"

echo "🔧 设置 Cloudflare Tunnel (用户模式)..."

# 创建目录
mkdir -p "$CLOUDFLARED_PATH/.."
mkdir -p "$CONFIG_DIR"
mkdir -p "$SERVICE_DIR"

# 安装 cloudflared 到用户目录
echo "📦 安装 cloudflared..."
cp /tmp/cloudflared_extract/usr/bin/cloudflared "$CLOUDFLARED_PATH"
chmod +x "$CLOUDFLARED_PATH"

# 验证安装
"$CLOUDFLARED_PATH" --version

echo ""
echo "✅ cloudflared 已安装到：$CLOUDFLARED_PATH"
echo ""
echo "下一步："
echo "1. 运行认证：$CLOUDFLARED_PATH tunnel login"
echo "2. 创建隧道配置"
echo "3. 启动隧道"
echo ""
echo "详细步骤请查看：SETUP_CLOUDFLARE.md"

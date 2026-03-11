#!/bin/bash
# Web Channel Installation Script for nanobot

set -e

echo "🔧 安装 nanobot Web Channel..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create directory
mkdir -p ~/.nanobot/workspace/web-channel/templates

# Install dependencies
echo "📦 安装 Python 依赖..."
pip install -q flask flask-cors requests

# Set permissions
chmod +x ~/.nanobot/workspace/web-channel/app.py

echo ""
echo "✅ 安装完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "启动方式:"
echo "  cd ~/.nanobot/workspace/web-channel"
echo "  python3 app.py"
echo ""
echo "访问地址:"
echo "  http://localhost:5000"
echo ""
echo "或者在后台运行:"
echo "  nohup python3 app.py > web-channel.log 2>&1 &"
echo ""

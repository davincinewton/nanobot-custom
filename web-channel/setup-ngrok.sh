#!/bin/bash
# ngrok Setup Script for nanobot Web Channel

set -e

NGROK_PATH="/home/yl/.nanobot/workspace/web-channel/ngrok"
CONFIG_DIR="/home/yl/.config/ngrok"

echo "🔧 设置 ngrok..."

# 复制 ngrok 到工作目录
cp /tmp/ngrok "$NGROK_PATH"
chmod +x "$NGROK_PATH"

# 创建配置目录
mkdir -p "$CONFIG_DIR"

echo "✅ ngrok 已下载"
echo ""
echo "下一步："
echo ""
echo "1. 注册 ngrok 账户：https://ngrok.com/"
echo "2. 获取认证令牌 (Auth Token)"
echo "3. 运行以下命令："
echo ""
echo "   $NGROK_PATH config add-authtoken YOUR_AUTH_TOKEN"
echo "   $NGROK_PATH http 5000"
echo ""
echo "隧道启动后，你会看到一个类似这样的地址："
echo "   https://abc123.ngrok-free.app"
echo ""
echo "然后在浏览器中打开该地址即可访问 nanobot！"
echo ""
echo "💡 提示：ngrok 免费版会随机生成地址，每次重启都会变化"
echo "   如果需要固定地址，需要付费升级"

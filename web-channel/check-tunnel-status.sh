#!/bin/bash
# 检查 Cloudflare Tunnel 状态

echo "🔍 检查 Cloudflare Tunnel 状态..."
echo ""

# 检查 cloudflared 进程
echo "1. Cloudflared 进程:"
ps aux | grep "cloudflared tunnel" | grep -v grep
echo ""

# 检查 Web Server 状态
echo "2. Web Server 状态:"
curl -s http://localhost:5000/api/health 2>/dev/null || echo "Web Server 未运行"
echo ""

# 检查隧道配置
echo "3. 隧道配置:"
ls -la ~/.cloudflared/ 2>/dev/null || echo "未找到用户级配置"
ls -la /root/.cloudflared/ 2>/dev/null || echo "未找到 root 级配置"
echo ""

# 尝试访问隧道
echo "4. 测试隧道访问:"
echo "   等待隧道完全启动后，访问:"
echo "   https://nanobot-web.trycloudflare.com"
echo ""

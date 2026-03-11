# Cloudflare Tunnel 设置指南

## 🚀 快速开始

### 步骤 1: 下载 cloudflared

```bash
wget -qO /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
```

### 步骤 2: 安装 cloudflared

```bash
sudo dpkg -i /tmp/cloudflared.deb
sudo apt-get install -f -y
```

### 步骤 3: 创建 Cloudflare 隧道

1. 访问 https://one.dash.cloudflare.com/
2. 登录你的 Cloudflare 账户
3. 导航到 **Zero Trust** → **Tunnels**
4. 点击 **Create a tunnel**
5. 选择 **Cloudflared** 作为连接方式
6. 选择 **Direct** 作为区域类型
7. 选择 **Linux** 作为操作系统
8. 复制生成的认证令牌

### 步骤 4: 配置隧道

```bash
# 创建配置目录
mkdir -p ~/.cloudflared

# 创建认证文件（粘贴步骤 3 中的令牌）
echo "你的认证令牌" > ~/.cloudflared/tunnel-credentials.json

# 创建隧道配置
cat > ~/.cloudflared/nanobot.yaml << EOF
tunnel: nanobot-web-channel
credentials-file: /home/yl/.cloudflared/tunnel-credentials.json

ingress:
  - hostname: nanobot-web.yourdomain.com
    service: http://localhost:5000
  - service: http_status:404
EOF
```

### 步骤 5: 启动隧道

```bash
cloudflared tunnel run nanobot-web-channel
```

### 步骤 6: 配置为 systemd 服务（可选）

```bash
sudo cloudflared service install nanobot-web-channel
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

## 🌐 访问地址

隧道启动后，你可以通过以下地址访问：

```
https://nanobot-web.yourdomain.com
```

## 📊 验证

```bash
# 检查隧道状态
cloudflared tunnel list

# 查看日志
cloudflared tunnel logs nanobot-web-channel
```

## 🔧 故障排除

### 问题：认证失败

**解决方案**:
1. 确保认证令牌正确
2. 检查 ~/.cloudflared/tunnel-credentials.json 文件
3. 重新生成令牌

### 问题：服务无法启动

**解决方案**:
1. 确保 Web Channel 正在运行：`curl http://localhost:5000/api/health`
2. 检查防火墙设置
3. 查看 cloudflared 日志

## 💡 最佳实践

1. **使用自定义域名**: 在 Cloudflare 上配置自定义域名
2. **启用 HTTPS**: Cloudflare 自动提供 SSL 证书
3. **设置访问限制**: 在 Cloudflare Zero Trust 中配置访问策略
4. **监控隧道状态**: 定期检查隧道健康状态

## 📝 自动化脚本

已创建自动化安装脚本：
```
~/.nanobot/workspace/web-channel/setup-cloudflared.sh
```

运行方式：
```bash
chmod +x ~/.nanobot/workspace/web-channel/setup-cloudflared.sh
~/.nanobot/workspace/web-channel/setup-cloudflared.sh
```

---

**更新时间**: 2026-03-11 15:30  
**状态**: 等待用户配置 Cloudflare 账户

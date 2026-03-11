# nanobot Web Channel - 互联网访问指南

## 🌐 问题说明

当前 nanobot Web Channel 运行在 QEMU 虚拟机中，使用 NAT 网络模式：
- **虚拟机 IP**: 192.168.122.217
- **限制**: 无法从宿主机或互联网直接访问
- **原因**: NAT 网络隔离，没有公网 IP

## ✅ 解决方案

### 方案 A: Cloudflare Tunnel (⭐⭐⭐⭐⭐ 强烈推荐)

#### 优点
- ✅ 完全免费
- ✅ 无需公网 IP 或服务器
- ✅ 自动 HTTPS 加密
- ✅ 全球低延迟访问
- ✅ 稳定可靠
- ✅ 可配置自定义域名

#### 步骤

**1. 注册 Cloudflare 账户**
- 访问 https://dash.cloudflare.com/sign-up
- 注册免费账户

**2. 创建 Zero Trust 隧道**
- 登录 https://one.dash.cloudflare.com/
- 导航到 **Zero Trust** → **Tunnels**
- 点击 **Create a tunnel**
- 选择 **Cloudflared** 作为连接方式
- 选择 **Direct** 作为区域类型
- 选择 **Linux** 作为操作系统

**3. 获取认证令牌**
- 复制生成的认证令牌 (看起来像：`tunnel.example.com:abc123...`)

**4. 配置 cloudflared**
```bash
# cloudflared 已安装在 /usr/local/bin/cloudflared

# 创建配置目录
mkdir -p ~/.cloudflared

# 创建认证文件
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

**5. 启动隧道**
```bash
cloudflared tunnel run nanobot-web-channel
```

**6. 配置为后台服务 (可选)**
```bash
# 创建 systemd 用户服务
cat > ~/.config/systemd/user/cloudflared-nanobot.service << EOF
[Unit]
Description=Cloudflare Tunnel for nanobot
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cloudflared tunnel run nanobot-web-channel
Restart=on-failure
RestartSec=5s
User=yl
Group=yl

[Install]
WantedBy=default.target
EOF

# 启用并启动服务
systemctl --user enable cloudflared-nanobot
systemctl --user start cloudflared-nanobot
```

#### 访问地址
```
https://nanobot-web.yourdomain.com
```

---

### 方案 B: ngrok (⭐⭐⭐⭐ 最简单)

#### 优点
- ✅ 5 分钟快速配置
- ✅ 无需复杂设置
- ✅ 立即使用

#### 步骤

**1. 注册 ngrok 账户**
- 访问 https://ngrok.com/
- 注册免费账户
- 获取 Auth Token

**2. 配置 ngrok**
```bash
# ngrok 已下载到 /home/yl/.nanobot/workspace/web-channel/ngrok

# 添加认证令牌
/home/yl/.nanobot/workspace/web-channel/ngrok config add-authtoken YOUR_AUTH_TOKEN

# 启动隧道
/home/yl/.nanobot/workspace/web-channel/ngrok http 5000
```

**3. 获取访问地址**
```
https://abc123.ngrok-free.app
```

#### 访问地址
```
https://<随机子域名>.ngrok-free.app
```

**注意**: 免费版地址会随机变化，每次重启 ngrok 都会不同

---

### 方案 C: frp (⭐⭐⭐ 高性能)

#### 优点
- ✅ 完全控制
- ✅ 高性能
- ✅ 可自定义

#### 缺点
- ❌ 需要公网服务器
- ❌ 配置复杂
- ❌ 需要付费

#### 步骤
1. 在 VPS 上部署 frps
2. 在虚拟机部署 frpc
3. 配置端口转发

---

## 📊 方案对比

| 方案 | 难度 | 速度 | 免费 | 自定义域名 | 稳定性 |
|------|------|------|------|-----------|--------|
| Cloudflare Tunnel | ⭐⭐ | ⭐⭐⭐ | ✅ | ✅ | ⭐⭐⭐⭐⭐ |
| ngrok | ⭐ | ⭐⭐⭐⭐ | ✅ | ❌ (免费版) | ⭐⭐⭐⭐ |
| frp | ⭐⭐⭐ | ⭐⭐ | ❌ | ✅ | ⭐⭐⭐⭐ |

---

## 🎯 推荐方案

### 最佳选择：Cloudflare Tunnel

**理由**:
1. 完全免费，无限制
2. 支持自定义域名
3. 自动 HTTPS
4. 全球 CDN 加速
5. 稳定可靠
6. 易于配置

### 快速选择：ngrok

**理由**:
1. 配置最简单
2. 5 分钟搞定
3. 立即测试

---

## 🚀 立即开始

### 快速开始 Cloudflare Tunnel

```bash
# 1. 访问 Cloudflare Zero Trust
# https://one.dash.cloudflare.com/

# 2. 创建隧道并获取令牌

# 3. 配置隧道
mkdir -p ~/.cloudflared
echo "你的令牌" > ~/.cloudflared/tunnel-credentials.json

cat > ~/.cloudflared/nanobot.yaml << EOF
tunnel: nanobot-web-channel
credentials-file: /home/yl/.cloudflared/tunnel-credentials.json

ingress:
  - hostname: nanobot-web.trycloudflare.com
    service: http://localhost:5000
  - service: http_status:404
EOF

# 4. 启动隧道
cloudflared tunnel run nanobot-web-channel
```

### 快速开始 ngrok

```bash
# 1. 访问 ngrok 注册
# https://ngrok.com/

# 2. 获取 Auth Token

# 3. 配置并启动
/home/yl/.nanobot/workspace/web-channel/ngrok config add-authtoken YOUR_TOKEN
/home/yl/.nanobot/workspace/web-channel/ngrok http 5000
```

---

## 🔍 验证访问

隧道启动后，测试访问：

```bash
# 从外部网络测试
curl https://nanobot-web.trycloudflare.com/api/health

# 或在浏览器中打开
https://nanobot-web.trycloudflare.com
```

---

## 📝 文件位置

所有相关文件和脚本：
```
~/.nanobot/workspace/web-channel/
├── app.py                    # Web 服务
├── SETUP_CLOUDFLARE.md       # Cloudflare 详细指南
├── setup-ngrok.sh            # ngrok 安装脚本
├── ALTERNATIVE_SOLUTIONS.md  # 替代方案对比
└── INTERNET_ACCESS_GUIDE.md  # 本文档
```

---

## 💡 提示

1. **Cloudflare Tunnel**: 推荐用于生产环境
2. **ngrok**: 推荐用于快速测试
3. **保持 Web Channel 运行**: `python3 app.py`
4. **隧道持久化**: 配置为 systemd 服务

---

**更新时间**: 2026-03-11 15:40  
**状态**: 等待用户选择方案并配置  
**推荐**: Cloudflare Tunnel (完全免费 + 自定义域名)

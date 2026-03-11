# 替代解决方案

## 方案 1: Cloudflare Tunnel (推荐)

### 优点
- ✅ 免费
- ✅ 无需公网 IP
- ✅ 自动 HTTPS
- ✅ 全球访问

### 步骤
1. 注册 Cloudflare 账户
2. 创建 Zero Trust 隧道
3. 获取认证令牌
4. 配置并启动隧道

**详细指南**: 见 `SETUP_CLOUDFLARE.md`

---

## 方案 2: ngrok (最简单)

### 优点
- ✅ 无需 Cloudflare 账户
- ✅ 快速配置
- ✅ 免费额度

### 步骤
```bash
# 安装 ngrok
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin/

# 认证 (需要 ngrok 账户)
ngrok config add-authtoken YOUR_AUTH_TOKEN

# 启动隧道
ngrok http 5000
```

**访问地址**: `https://xxx-yyy.ngrok-free.app`

---

## 方案 3: frp (内网穿透)

### 优点
- ✅ 完全控制
- ✅ 可自托管
- ✅ 高性能

### 步骤
1. 在公网服务器部署 frps
2. 在虚拟机部署 frpc
3. 配置端口转发

**配置示例**:
```ini
# frpc.ini
[web-channel]
type = tcp
local_ip = 127.0.0.1
local_port = 5000
remote_port = 8080
```

---

## 方案 4: SSH 反向隧道

### 优点
- ✅ 无需额外服务
- ✅ 使用现有 SSH
- ✅ 安全

### 步骤
```bash
# 在宿主机上
ssh -R 80:localhost:5000 user@your-server.com
```

---

## 推荐方案对比

| 方案 | 难度 | 速度 | 免费 | 推荐度 |
|------|------|------|------|--------|
| Cloudflare Tunnel | ⭐⭐ | ⭐⭐⭐ | ✅ | ⭐⭐⭐⭐⭐ |
| ngrok | ⭐ | ⭐⭐ | ✅ (有限) | ⭐⭐⭐⭐ |
| frp | ⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ | ⭐⭐⭐ |
| SSH 隧道 | ⭐⭐ | ⭐⭐ | ✅ | ⭐⭐⭐ |

---

## 我的建议

**最佳方案**: **Cloudflare Tunnel**

理由：
1. 完全免费
2. 无需公网服务器
3. 自动 HTTPS
4. 全球访问
5. 稳定可靠

**最简单方案**: **ngrok**

理由：
1. 5 分钟搞定
2. 无需配置
3. 立即使用

---

## 下一步

1. **选择方案**: 根据你的需求选择合适的方案
2. **配置隧道**: 按照对应指南配置
3. **测试访问**: 从外部网络测试
4. **持久化运行**: 配置为后台服务

---

**更新时间**: 2026-03-11 15:35  
**状态**: 等待用户选择方案

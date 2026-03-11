# nanobot-custom 安装指南

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/davincinewton/nanobot-custom.git
cd nanobot-custom
```

### 2. 安装依赖

```bash
# 安装 Python 依赖
pip install -e .

# 或者使用 requirements.txt
pip install -r requirements.txt
```

### 3. 配置环境变量

```bash
# 复制示例配置文件
cp .env.example .env

# 编辑配置文件
nano .env
```

### 4. 启动 nanobot

```bash
# 使用启动脚本
./start-nanobot.sh

# 或者手动启动
python -m nanobot
```

## 📦 安装选项

### 选项 1: 使用 Systemd 服务（推荐）

```bash
# 复制服务文件
sudo cp nanobot-gateway.service /etc/systemd/system/

# 启用服务
sudo systemctl enable nanobot-gateway

# 启动服务
sudo systemctl start nanobot-gateway

# 查看状态
sudo systemctl status nanobot-gateway
```

### 选项 2: 使用 Docker

```bash
# 构建镜像
docker build -t nanobot-custom .

# 运行容器
docker run -d --name nanobot-custom \
  -v $(pwd)/config:/app/config \
  -p 5000:5000 \
  nanobot-custom
```

### 选项 3: 使用 Docker Compose

```bash
docker-compose up -d
```

## 🧰 安装 Skills

### 安装内置 Skills

```bash
# deep-research-pro
cd custom-skills/deep-research-pro
pip install -e .

# jina-cli
cd custom-skills/jina-cli
pip install -e .

# ddgs
cd custom-skills/ddgs
pip install -e .
```

### 安装 Web Channel

```bash
cd web-channel
./install.sh
./start.sh
```

### 使用 ClawHub 安装更多 Skills

```bash
# 在 nanobot 中调用
clawhub search <技能名称>
clawhub install <技能名称>
```

## 🔧 配置

### 主要配置文件

- `.env`: 环境变量配置
- `config.json`: nanobot 配置
- `docker-compose.yml`: Docker 配置

### 配置选项

```bash
# Telegram 配置
TELEGRAM_BOT_TOKEN=your_token_here
TELEGRAM_CHAT_ID=your_chat_id

# Web 配置
WEB_PORT=5000
WEB_HOST=0.0.0.0

# API 配置
API_KEY=your_api_key
```

## 📝 使用示例

### 启动 nanobot

```bash
# 基本启动
./start-nanobot.sh

# 后台启动
nohup ./start-nanobot.sh > nanobot.log 2>&1 &

# 查看日志
tail -f nanobot.log
```

### 使用 Skills

```bash
# 搜索新闻
ddgs "Australia news"

# 深度研究
deep-research-pro "Three-Body Problem"

# 读取网页
jina-cli "https://en.wikipedia.org/wiki/Bitcoin"
```

## 🔄 更新

### 同步上游更新

```bash
# 添加上游仓库
git remote add upstream https://github.com/HKUDS/nanobot.git

# 获取上游更新
git fetch upstream

# 合并更新
git merge upstream/master

# 解决冲突后提交
git add .
git commit -m "Merge upstream updates"
```

### 更新 Skills

```bash
# 更新内置 Skills
cd custom-skills
git pull

# 使用 ClawHub 更新
clawhub update
```

## 🐛 故障排除

### 常见问题

#### 1. Telegram 重复消息

**问题**: Telegram 消息重复显示

**解决**: 本版本已修复此问题，无需额外配置

#### 2. Web Search 失败

**问题**: Web search 无法工作

**解决**: 确保安装了 ddgs
```bash
pip install ddgs
```

#### 3. Web Fetch 失败

**问题**: Web fetch 无法工作

**解决**: 确保安装了 jina-cli
```bash
pip install jina-cli
```

### 日志位置

- 应用日志：`nanobot.log`
- 错误日志：`error.log`
- Systemd 日志：`journalctl -u nanobot-gateway`

## 📚 文档

- [README.md](README.md): 项目介绍
- [CHANGES.md](CHANGES.md): 变更日志
- [SKILLS.md](SKILLS.md): Skills 文档
- [API.md](API.md): API 文档（待添加）

## 🤝 贡献

欢迎贡献代码！请查看 [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE)

---

**最后更新**: 2026-03-11

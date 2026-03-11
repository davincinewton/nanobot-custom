# nanobot-custom

**一个定制化的 nanobot 版本，包含所有修复和增强功能。**

## 🚀 快速开始

### 安装

```bash
git clone https://github.com/davincinewton/nanobot-custom.git
cd nanobot-custom
pip install -e .
```

### 启动

```bash
./start-nanobot.sh
```

## ✨ 主要改进

### 1. 🐛 修复 Telegram 重复消息问题

**问题**: `send_message_draft` 模拟流式效果导致重复消息

**修复**: 移除 draft 模拟，直接调用 `_send_text` 发送消息

**影响**: Telegram 不再出现重复回复

### 2. 🔍 默认使用 ddgs 作为 Web Search

**问题**: 原始代码使用 Brave Search API，需要 API 密钥

**修复**: 改为使用 ddgs (DuckDuckGo)，无需 API 密钥

**影响**: Web search 功能更稳定，无需配置

### 3. 📄 默认使用 jina-cli 作为 Web Fetch

**问题**: 原始代码使用 Jina AI Reader，需要 API 密钥

**修复**: 改为使用 jina-cli 工具，更可靠

**影响**: Web fetch 功能更稳定，无需配置

### 4. 🧰 新增 Skills

已集成以下额外技能：
- `deep-research-pro`: 多源深度研究代理
- `jina-cli`: Jina 命令行工具
- `web-channel`: Flask 基于 Web 的通道
- 更多技能可通过 ClawHub 安装

## 📦 包含内容

### 修改的核心代码

1. **nanobot/agent/tools/web.py**
   - 默认使用 ddgs 进行 Web search
   - 默认使用 jina-cli 进行 Web fetch

2. **nanobot/channels/telegram.py**
   - 移除 `send_message_draft` 模拟流式效果
   - 直接发送消息，避免重复

### 新增的 Skills

- `deep-research-pro`: 深度研究能力
- `jina-cli`: Jina 命令行工具
- `ddgs`: DuckDuckGo 搜索
- `web-channel`: Web 界面通道
- 更多技能

### 配置文件

- `start-nanobot.sh`: 启动脚本
- `nanobot-gateway.service`: Systemd 服务配置
- `docker-compose.yml`: Docker 配置
- `Dockerfile`: Docker 镜像

## 🔄 与上游同步

这个仓库是 [HKUDS/nanobot](https://github.com/HKUDS/nanobot) 的定制版本。

### 同步上游更新

```bash
# 添加上游仓库
git remote add upstream https://github.com/HKUDS/nanobot.git

# 获取上游更新
git fetch upstream

# 合并更新（需要手动解决冲突）
git merge upstream/master
```

## 📝 补丁历史

### 2026-03-11

- ✅ 修复 Telegram 重复消息问题
- ✅ 默认使用 ddgs 进行 Web search
- ✅ 默认使用 jina-cli 进行 Web fetch
- ✅ 添加 deep-research-pro skill
- ✅ 添加 jina-cli skill
- ✅ 添加 web-channel 功能

## 🛡️ 许可证

MIT License - 自由使用、修改和分发

## 📄 作者

Created by davincinewton

---

**版本**: 1.0.0  
**最后更新**: 2026-03-11  
**状态**: ✅ 生产就绪

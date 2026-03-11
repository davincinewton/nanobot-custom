# nanobot-custom 变更日志

## [1.0.0] - 2026-03-11

### 新增功能

#### 🧰 新增 Skills

- **deep-research-pro**: 多源深度研究代理
  - 搜索网络，综合信息，生成引用报告
  - 无需 API 密钥
  
- **jina-cli**: Jina 命令行工具
  - 读取网页内容，提取文本
  - 支持 Markdown 和纯文本模式
  
- **ddgs**: DuckDuckGo 搜索
  - 网络搜索功能
  - 无需 API 密钥
  
- **web-channel**: Flask Web 界面
  - REST API 支持
  - Web 前端界面

### 修复

#### 🐛 Telegram 重复消息

**问题**: `send_message_draft` 模拟流式效果导致重复消息

**修复**: 移除 `_send_with_streaming` 方法中的 draft 模拟逻辑

**文件**: `nanobot/channels/telegram.py`

**变更**:
```python
# 之前
await self._send_with_streaming(chat_id, text, reply_params, thread_kwargs)

# 现在
await self._send_text(chat_id, text, reply_params, thread_kwargs)
```

#### 🔍 Web Search 默认工具

**问题**: 原始代码使用 Brave Search API，需要 API 密钥

**修复**: 改为使用 ddgs (DuckDuckGo)

**文件**: `nanobot/agent/tools/web.py`

**变更**:
```python
# 之前
self.search_engine = "brave"

# 现在
self.search_engine = "ddgs"
```

#### 📄 Web Fetch 默认工具

**问题**: 原始代码使用 Jina AI Reader，需要 API 密钥

**修复**: 改为使用 jina-cli 工具

**文件**: `nanobot/agent/tools/web.py`

**变更**:
```python
# 之前
self.fetch_method = "jina-ai"

# 现在
self.fetch_method = "jina-cli"
```

### 技术改进

#### 📦 项目结构

- 添加了 `start-nanobot.sh` 启动脚本
- 添加了 `nanobot-gateway.service` Systemd 服务配置
- 添加了 `docker-compose.yml` 和 `Dockerfile`
- 优化了项目配置

#### 🔄 版本控制

- 基于 HKUDS/nanobot v0.1.4.post3
- 添加了上游仓库同步说明
- 添加了变更日志

## 📊 统计

- **修改文件**: 2 个核心文件
- **新增文件**: 10+ 个配置文件和脚本
- **新增 Skills**: 4 个主要技能
- **修复问题**: 3 个主要问题

## 🚀 未来计划

- [ ] 定期同步上游更新
- [ ] 添加更多自定义技能
- [ ] 优化性能
- [ ] 添加单元测试

---

**维护者**: davincinewton  
**最后更新**: 2026-03-11

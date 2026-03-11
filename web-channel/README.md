# nanobot Web Channel 🌐

基于 Web 的 nanobot 对话系统，提供现代化的聊天界面。

## 🚀 快速开始

### 安装

```bash
cd ~/.nanobot/workspace/web-channel
./install.sh
```

### 启动

```bash
# 前台运行
python3 app.py

# 后台运行
nohup python3 app.py > web-channel.log 2>&1 &
```

### 访问

打开浏览器访问：`http://localhost:5000`

## 📁 文件结构

```
web-channel/
├── app.py              # Flask 后端服务
├── requirements.txt    # Python 依赖
├── install.sh          # 安装脚本
├── README.md           # 本文档
└── templates/
    └── index.html      # 前端界面
```

## 🔧 配置

编辑 `app.py` 修改配置：

```python
CONFIG = {
    "host": "0.0.0.0",     # 监听地址
    "port": 5000,          # 端口号
    "debug": True,         # 调试模式
    "max_history": 100,    # 历史记录数量
    "workspace": "/home/yl/.nanobot/workspace"
}
```

## 🌐 API 端点

### `POST /api/chat`
发送消息并获取响应

**请求**:
```json
{
  "message": "你好",
  "user": "user"
}
```

**响应**:
```json
{
  "id": 1,
  "timestamp": "2026-03-11 14:00:00",
  "user": "user",
  "message": "你好",
  "response": "响应内容",
  "status": "success"
}
```

### `GET /api/history`
获取聊天历史

**响应**:
```json
{
  "history": [...],
  "count": 10
}
```

### `GET /api/health`
健康检查

**响应**:
```json
{
  "status": "healthy",
  "timestamp": "2026-03-11T14:00:00",
  "version": "1.0.0"
}
```

## 🔌 集成 nanobot

当前版本为演示版本，需要集成实际的 nanobot agent：

1. **修改 `process_user_message` 函数**
2. **调用 nanobot 的 agent 系统**
3. **处理工具调用和响应**

示例集成代码：

```python
import asyncio
from nanobot.agent.core import Agent

async def process_user_message(message, history=None):
    agent = Agent()
    response = await agent.run(message)
    return response
```

## 🎨 功能特点

- ✅ 现代化响应式设计
- ✅ 实时消息传递
- ✅ 聊天历史保存
- ✅ 打字指示器
- ✅ 错误处理
- ✅ 时间戳显示
- ✅ 支持中文界面

## 🔒 安全建议

生产环境部署时：

1. **启用 HTTPS**
2. **添加认证机制**
3. **限制访问 IP**
4. **设置请求频率限制**
5. **配置 CORS 白名单**

## 🐛 故障排除

### 端口被占用
```bash
# 修改 app.py 中的 port 配置
# 或关闭占用端口的进程
lsof -i :5000
kill -9 <PID>
```

### 依赖安装失败
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 无法访问
```bash
# 检查服务是否运行
ps aux | grep app.py

# 查看日志
tail -f web-channel.log
```

## 📝 开发计划

- [ ] 集成实际 nanobot agent
- [ ] 支持文件上传
- [ ] 语音输入
- [ ] 主题切换
- [ ] 多语言支持
- [ ] WebSocket 实时通信
- [ ] 用户认证系统
- [ ] 消息加密

## 📄 许可证

MIT License

---

**版本**: 1.0.0  
**创建时间**: 2026-03-11  
**维护者**: nanobot team

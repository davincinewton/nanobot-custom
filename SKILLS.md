# 新增 Skills

本仓库包含以下新增的自定义 Skills：

## 🧰 已集成 Skills

### 1. deep-research-pro

**功能**: 多源深度研究代理

**描述**: 搜索网络，综合信息，生成引用报告。无需 API 密钥。

**使用方法**:
```bash
# 在 nanobot 中调用
deep-research-pro <查询主题>
```

**示例**:
```bash
deep-research-pro "Three-Body Problem 恒星运动"
```

**位置**: `custom-skills/deep-research-pro/`

---

### 2. jina-cli

**功能**: Jina 命令行工具

**描述**: 读取网页内容，提取文本。支持 Markdown 和纯文本模式。

**使用方法**:
```bash
# 读取网页内容
jina-cli <URL>
```

**示例**:
```bash
jina-cli "https://en.wikipedia.org/wiki/Bitcoin"
```

**位置**: `custom-skills/jina-cli/`

---

### 3. ddgs

**功能**: DuckDuckGo 搜索

**描述**: 网络搜索功能，无需 API 密钥。

**使用方法**:
```bash
# 搜索网络
ddgs <搜索关键词>
```

**示例**:
```bash
ddgs "Australia news today"
```

**位置**: `custom-skills/ddgs/`

---

## 🌐 Web Channel

**功能**: Flask Web 界面

**描述**: REST API 支持，Web 前端界面。

**使用方法**:
```bash
# 启动 Web 服务
cd web-channel
./install.sh
./start.sh
```

**访问地址**: `http://localhost:5000`

**位置**: `web-channel/`

---

## 📦 安装更多 Skills

可以通过 ClawHub 安装更多技能：

```bash
# 在 nanobot 中调用
clawhub search <技能名称>
clawhub install <技能名称>
```

**示例**:
```bash
clawhub search weather
clawhub install weather
```

---

## 🔄 Skill 目录结构

```
nanobot-custom/
├── custom-skills/
│   ├── deep-research-pro/
│   │   ├── SKILL.md
│   │   └── agent.py
│   ├── jina-cli/
│   │   ├── SKILL.md
│   │   └── agent.py
│   └── ddgs/
│       ├── SKILL.md
│       └── agent.py
└── web-channel/
    ├── app.py
    ├── templates/
    ├── install.sh
    └── README.md
```

---

**最后更新**: 2026-03-11

# Project Deploy Skill 🔒

**一个完整的技能，用于将 nanobot-custom 项目进行安全检查并部署到 GitHub。**

## 🎯 功能

这个 Skill 会：
1. ✅ **自动安全检查**（敏感信息扫描、文件验证）
2. ✅ 创建测试分支
3. ✅ 提交并推送到 GitHub
4. ✅ 创建 Git 标签
5. ✅ 生成部署报告

**⚠️ 不再创建分发包（tar.gz）** - 直接使用 Git 进行版本控制

## 📋 使用流程

### 快速部署

```bash
cd /home/yl/.nanobot/workspace/nanobot-custom
./deploy.sh
```

### 手动部署

#### 步骤 1: 运行安全检查

```bash
./deploy.sh --check-only
```

#### 步骤 2: 查看检查结果

检查以下项目：
- 🔐 敏感信息扫描
- 📁 文件完整性验证
- 📦 依赖配置检查
- 🌿 Git 状态验证

#### 步骤 3: 执行部署

```bash
./deploy.sh
```

#### 步骤 4: 查看部署报告

```bash
cat DEPLOYMENT_REPORT.md
```

## 🔍 安全检查内容

### 1. 敏感信息扫描

自动扫描以下内容：

```bash
# 检查硬编码的 token 和密钥
grep -r "ghp_\|github_pat_\|xoxb_\|discord_bot_token\|sk-[^a-z0-9]" \
  --include="*.sh" --include="*.py" --include="*.json" \
  --include="*.yaml" --include="*.yml" . 2>/dev/null

# 检查 .env 文件
find . -name ".env*" -type f 2>/dev/null

# 检查 config.json
find . -name "config.json" -type f 2>/dev/null
```

**如果发现敏感信息**：
- ❌ 停止部署
- 📝 显示警告
- 🔐 建议立即删除

### 2. 文件完整性验证

确保以下文件存在：

```bash
# 核心文件
✅ install.sh
✅ start-nanobot.sh
✅ README.md
✅ pyproject.toml
✅ .gitignore

# 核心目录
✅ custom-skills/
✅ web-channel/
✅ nanobot/
```

### 3. .gitignore 验证

确保 `.gitignore` 包含：

```
# 虚拟环境
venv/
.venv/
env/

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python

# 配置和密钥
.env
.env.*
config.json
secrets.json

# 日志
*.log

# 打包文件
backups/
*.tar.gz
*.zip

# IDE
.idea/
.vscode/
*.swp
```

### 4. Git 状态验证

```bash
# 检查是否有未提交的更改
git status

# 检查远程仓库
git remote -v

# 检查当前分支
git branch --show-current
```

## 🚀 自动化部署脚本

### deploy.sh 功能

```bash
#!/bin/bash

# 1. 安全检查阶段
   ├─ 敏感信息扫描
   ├─ 文件完整性检查
   ├─ .gitignore 验证
   └─ Git 状态验证

# 2. 部署准备阶段
   ├─ 创建测试分支 (test-YYYYMMDD-HHMMSS)
   ├─ 提交更改
   └─ 推送到远程

# 3. 版本标记阶段
   ├─ 创建 Git 标签 (vX.Y.Z-YYYYMMDD)
   └─ 推送标签

# 4. 报告生成阶段
   └─ 生成 DEPLOYMENT_REPORT.md
```

### 使用选项

```bash
./deploy.sh              # 完整部署流程
./deploy.sh --check      # 仅安全检查
./deploy.sh --dry-run    # 模拟执行（不实际推送）
./deploy.sh --tag v1.0.0 # 创建指定版本的标签
```

## 📊 部署报告示例

```markdown
# 部署报告

## 基本信息
- **部署时间**: 2026-03-12 09:30:15
- **项目**: nanobot-custom
- **仓库**: https://github.com/davincinewton/nanobot-custom
- **分支**: main → test-20260312-093015

## 安全检查结果
✅ 敏感信息扫描: 通过
✅ 文件完整性: 通过
✅ .gitignore: 正确配置
✅ Git 状态: 干净

## Git 操作
- **提交**: abc1234 ("部署：更新文档和依赖")
- **分支**: test-20260312-093015
- **标签**: v1.1.0-20260312

## 部署状态
✅ 成功

## 警告
无

## 下一步
1. 验证测试分支内容
2. 合并到 main（如需要）
3. 更新版本文档
```

## 🔐 安全最佳实践

### 1.  never 提交敏感信息

```bash
# ❌ 错误示例
echo "GITHUB_TOKEN=ghp_xxx" >> config.json
git add config.json  # 不要提交！

# ✅ 正确示例
echo "GITHUB_TOKEN=\${GITHUB_TOKEN}" > .env.example
echo "config.json" >> .gitignore
echo ".env" >> .gitignore
```

### 2. 使用环境变量

```bash
# .env.example (可以提交)
GITHUB_TOKEN=your_token_here
TELEGRAM_BOT_TOKEN=your_bot_token_here

# .env (添加到 .gitignore)
GITHUB_TOKEN=ghp_实际令牌
TELEGRAM_BOT_TOKEN=实际令牌
```

### 3. 定期扫描

```bash
# 每次部署前运行
./deploy.sh --check

# 手动扫描
grep -r "ghp_\|sk-" --include="*.py" --include="*.sh" .
```

### 4. 密钥轮换

如果发现密钥可能泄露：
1. 立即在 GitHub/Telegram 等平台撤销
2. 生成新密钥
3. 更新环境变量
4. 执行 `./deploy.sh` 重新部署

## 🛠️ 故障排除

### 问题：安全检查失败

```
❌ 发现敏感信息: ghp_xxx in config.json
```

**解决方案**：
```bash
# 1. 删除或清理文件
rm config.json
# 或编辑移除敏感信息

# 2. 重新运行检查
./deploy.sh --check

# 3. 如果已提交到 git，需要清理历史
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch config.json" \
  --prune-empty --tag-name-filter cat -- --all
```

### 问题：文件太多无法推送

```
remote: error: GH013: Repository limit exceeded
```

**解决方案**：
- 确保 `.gitignore` 正确配置
- 清理大文件：`git clean -fdx`
- 使用 `git filter-branch` 清理历史

### 问题：权限错误

```
fatal: could not read Username for 'https://github.com'
```

**解决方案**：
```bash
# 使用 SSH 或配置凭证
git remote set-url origin git@github.com:davincinewton/nanobot-custom.git
# 或使用凭证缓存
git config --global credential.helper store
```

## 📚 相关文件

- `deploy.sh` - 自动化部署脚本
- `DEPLOYMENT_REPORT.md` - 部署报告（自动生成）
- `.gitignore` - Git 忽略规则
- `SKILL.md` - 本文档

---

**版本**: 2.0.0  
**创建时间**: 2026-03-12  
**更新**: 移除分发包，集成安全检查  
**维护者**: nanobot team
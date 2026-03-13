# 📦 nanobot-custom 部署实施步骤

> **版本**: 3.0.0  
> **创建时间**: 2026-03-13  
> **目的**: 将代码提交到 GitHub 仓库

---

## 🎯 目标

将 `~/nanobot/nanobot` 目录的修改自动同步到 `~/.nanobot/workspace/nanobot-custom/nanobot`，并提交到 GitHub 仓库。

---

## ✅ 已完成的工作

### 1. 创建自动化部署脚本

**脚本位置**: `~/nanobot/workspace/nanobot-custom/deploy.sh`

**主要功能**:
- ✅ 自动同步源代码（`~/nanobot/nanobot` → `~/.nanobot/workspace/nanobot-custom/nanobot`）
- ✅ 自动备份旧代码到 `backups/sync_YYYYMMDD_HHMMSS/`
- ✅ 安全检查（敏感信息、文件完整性、Git 状态）
- ✅ 自动创建分支和标签
- ✅ 推送到 GitHub
- ✅ 生成部署报告

### 2. 创建辅助同步脚本

**脚本位置**: `~/nanobot/workspace/nanobot-custom/sync_source.sh`

**用途**: 手动执行源代码同步（可选）

---

## 📋 部署步骤

### 步骤 0：准备工作

```bash
# 进入项目目录
cd ~/nanobot/workspace/nanobot-custom

# 确认脚本已就绪
ls -la deploy.sh
# 应该看到：-rwxr-xr-x 1 ... deploy.sh
```

### 步骤 1：执行安全检查（推荐）

```bash
./deploy.sh --check
```

**这会执行**:
1. 🔄 自动同步源代码（从 `~/nanobot/nanobot`）
2. 🔐 扫描敏感信息（GitHub Token、API Key 等）
3. 📁 验证必需文件
4. 🌿 检查 Git 状态
5. ✅ 验证 `.gitignore` 配置

**预期输出示例**:
```
🔧 nanobot-custom 部署工具 v3.0.0 (增强版)

🔄 同步源代码
  ✅ 同步完成!

🔐 安全检查
  ✅ 未发现硬编码密钥
  ✅ .gitignore 配置正确
  ✅ 所有检查通过，可以安全部署！
```

### 步骤 2：干燥运行（可选）

```bash
./deploy.sh --dry-run
```

**作用**: 模拟部署流程，不实际推送代码

### 步骤 3：执行部署

```bash
./deploy.sh
```

**完整流程**:
1. 🔄 同步源代码（自动从 `~/nanobot/nanobot`）
2. 🔐 安全检查
3. 🌿 创建测试分支 `test-YYYYMMDD-HHMMSS`
4. 💾 提交更改
5. 🚀 推送到 GitHub
6. 🏷️ 创建 Git 标签
7. 📊 生成部署报告

### 步骤 4：验证部署

```bash
# 查看 Git 状态
git status

# 查看最近的提交
git log --oneline -3

# 查看标签
git tag -l

# 查看远程分支
git branch -r
```

**或直接在 GitHub 页面查看**:
- 仓库：https://github.com/davincinewton/nanobot-custom
- 检查新分支和标签

---

## 📝 使用选项

### 完整命令参考

```bash
# 仅安全检查（不部署）
./deploy.sh --check

# 干燥运行（模拟部署）
./deploy.sh --dry-run

# 指定标签版本
./deploy.sh --tag v1.2.3

# 跳过源码同步（手动同步后使用）
./deploy.sh --skip-sync

# 完整部署（默认）
./deploy.sh
```

### 常用组合

```bash
# 安全检查 + 手动确认后再部署
./deploy.sh --check
# 检查输出，确认无误后
./deploy.sh

# 跳过同步直接部署（已手动同步）
./deploy.sh --skip-sync

# 指定版本标签部署
./deploy.sh --tag v0.1.5
```

---

## 📂 文件结构

```
~/.nanobot/workspace/nanobot-custom/
├── deploy.sh              # ⭐ 主部署脚本（自动同步）
├── sync_source.sh         # 辅助同步脚本
├── DEPLOY_INSTRUCTIONS.md # 本文件
├── backups/               # 自动备份目录
│   ├── sync_20260313_105743/
│   └── ...
├── nanobot/               # 同步的目标代码
│   ├── agent/
│   ├── channels/
│   ├── config/
│   └── ...
├── custom-skills/         # 自定义技能
├── web-channel/           # Web 通道
└── ...其他配置文件
```

---

## 🔍 当前待提交内容

根据 `git status` 输出：

### 修改的文件
- `nanobot/agent/memory.py` - 内存管理模块
- `nanobot/bus/events.py` - 事件总线
- `nanobot/channels/manager.py` - 通道管理器
- `nanobot/config/schema.py` - 配置 Schema
- `pyproject.toml` - 项目配置（版本信息）

### 新增文件
- `deploy.sh` - 部署脚本（本次新增）
- `nanobot/agent/tools/memory_consolidation.py` - 内存整合工具
- `nanobot/agent/tools/session_info.py` - 会话信息工具
- `nanobot/channels/web.py` - Web 通道
- `nanobot/templates/web/` - Web 模板目录

---

## ⚠️ 注意事项

### 1. 源码同步说明

- 部署脚本会自动将 `~/nanobot/nanobot` 同步到部署目录
- 同步时会排除 `__pycache__` 和 `.pyc` 文件
- 同步前会自动备份旧代码到 `backups/` 目录
- 如果不需要同步，使用 `--skip-sync` 参数

### 2. 安全检查重点

脚本会自动检查：
- ❌ 硬编码的 GitHub Token (`ghp_...`)
- ❌ 硬编码的 API Key (`sk-...`)
- ❌ Discord Bot Token
- ❌ `.env` 文件（敏感配置）
- ❌ `config.json` 文件（可能包含密钥）

**如果发现错误**，请：
1. 检查代码中是否有硬编码密钥
2. 使用环境变量管理敏感信息
3. 确保 `.gitignore` 包含 `.env` 和 `config.json`

### 3. Git 配置

确保 Git 已配置：
```bash
git config --global user.name "davincinewton"
git config --global user.email "davincinewton@126.com"
```

### 4. SSH 配置（推荐）

使用 SSH 替代 HTTPS：
```bash
# 生成 SSH 密钥（如果没有）
ssh-keygen -t ed25519 -C "davincinewton@126.com"

# 添加到 SSH Agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 配置远程仓库使用 SSH
git remote set-url origin git@github.com:davincinewton/nanobot-custom.git
```

---

## 🛠️ 故障排除

### 问题 1：同步失败

**症状**: `rsync: command not found`

**解决**:
```bash
# 安装 rsync
sudo apt-get install rsync  # Ubuntu/Debian
sudo yum install rsync      # CentOS/RHEL
brew install rsync          # macOS
```

### 问题 2：安全检查失败

**症状**: 检测到硬编码密钥

**解决**:
1. 找到相关文件: `grep -rn "ghp_\|sk-" .`
2. 替换为环境变量
3. 确保密钥不在版本控制中

### 问题 3：推送被拒绝

**症状**: `remote: Permission denied` 或 `rejected`

**解决**:
```bash
# 检查 SSH 配置
ssh -T git@github.com

# 检查远程 URL
git remote -v

# 重新配置认证
git config --global credential.helper store
```

### 问题 4：分支冲突

**症状**: `Failed to merge in the changes`

**解决**:
```bash
# 拉取最新代码
git pull --rebase origin main

# 解决冲突后继续
git add .
git rebase --continue

# 或者强制推送（谨慎使用）
git push --force-with-lease
```

---

## 📊 部署后验证清单

执行以下检查确保部署成功：

- [ ] 检查 GitHub 仓库是否收到新提交
- [ ] 验证新分支内容正确
- [ ] 确认标签已创建
- [ ] 检查部署报告 `DEPLOYMENT_REPORT.md`
- [ ] 本地开发环境测试（如需）
- [ ] 清理测试分支（如不再需要）

---

## 🔄 回滚步骤

如果需要回滚到之前的版本：

```bash
# 1. 查看可用备份
ls -la backups/

# 2. 恢复备份的代码
cd ~/nanobot/workspace/nanobot-custom
rm -rf nanobot/
cp -r backups/sync_YYYYMMDD_HHMMSS nanobot/

# 3. 回滚 Git
git reset --hard HEAD~1
git push --force-with-lease origin main
```

---

## 📞 获取帮助

### 相关文档

- [README.md](./README.md) - 项目介绍
- [SKILLS.md](./SKILLS.md) - 技能说明
- [DEPLOYMENT_REPORT.md](./DEPLOYMENT_REPORT.md) - 部署报告（自动生成）

### 技能文件

- `custom-skills/project-deploy/deploy.sh` - 原始部署脚本

---

## 📝 更新日志

### v3.0.0 (2026-03-13)
- ✨ 新增自动源码同步功能
- ✨ 集成安全检查到部署流程
- ✨ 添加部署报告生成
- 🐛 修复参数解析问题
- 📝 完善使用文档

### v2.0.0
- 移除分发包创建
- 集成自动安全检查

---

*文档生成时间: 2026-03-13*
*最后更新: 2026-03-13*
# Project Deploy Skill 📦

**自动化项目部署工具 - 自动创建测试分支、生成分发包、推送到 GitHub**

## 🎯 功能

每次运行时自动完成：
1. ✅ **检查工作区状态** - 自动提交未保存的更改
2. ✅ **创建测试分支** - 格式：`test-YYYYMMDD-HHMM`
3. ✅ **生成分发包** - 排除 `.git/`、`venv/` 等开发文件
4. ✅ **记录分发包位置** - 本地存档（超过 100MB 不推送）
5. ✅ **推送到 GitHub** - 推送到新的测试分支
6. ✅ **创建 Git 标签** - 格式：`vYYYYMMDD-HHMM`
7. ✅ **生成部署报告** - 包含所有部署细节

## 🚀 使用方法

### 快速部署（推荐）

```bash
cd /path/to/nanobot-custom
./custom-skills/project-deploy/deploy.sh
```

**一键完成所有操作**：
- 自动创建测试分支
- 创建分发包到 `backups/` 目录（本地存档）
- 推送到远程测试分支
- 创建 Git 标签
- 生成部署报告

### 仅创建分发包

```bash
./custom-skills/project-deploy/create-backup.sh
```

**仅生成分发包**（不推送）：
- 创建 `backups/nanobot-custom-YYYYMMDD-HHMM.tar.gz`
- 排除敏感文件和开发依赖

### 回滚/管理版本

```bash
./custom-skills/project-deploy/rollback.sh
```

**交互式菜单**：
- 列出所有测试分支
- 列出所有 Git 标签
- 回滚到指定分支/标签
- 删除测试分支

**命令行参数**：
```bash
# 列出测试分支
./rollback.sh --list-branches

# 列出标签
./rollback.sh --list-tags

# 回滚到分支
./rollback.sh --to-branch test-20260312-0830

# 回滚到标签
./rollback.sh --to-tag v20260312-0830

# 删除分支
./rollback.sh --delete test-20260312-0830

# 显示帮助
./rollback.sh --help
```

## 📋 部署流程详解

```
1. check_git_status()
   └── 检查未提交更改，自动提交

2. create_test_branch()
   └── 创建 test-YYYYMMDD-HHMM 分支

3. create_distribution_package()
   └── 调用 create-backup.sh
   └── 生成 backups/nanobot-custom-*.tar.gz

4. note_backup_location()
   └── 记录分发包位置（超过 100MB 不推送）

5. push_to_github()
   └── 推送到远程测试分支

6. create_tag()
   └── 创建 vYYYYMMDD-HHMM 标签

7. generate_report()
   └── 生成 DEPLOYMENT_REPORT_*.md
```

## 📦 分发包内容

### ✅ 包含的文件
- `install.sh` - 完整安装脚本
- `start-nanobot.sh` - 交互式启动脚本
- `README.md` - 项目说明
- `pyproject.toml` - Python 依赖配置
- `nanobot/` - 核心代码（含所有修改）
- `custom-skills/` - 4 个自定义 Skills
- `web-channel/` - Web 界面
- 所有文档和配置文件

### ❌ 排除的文件
- `.git/` - Git 历史
- `venv/`, `env/` - 虚拟环境
- `__pycache__/`, `*.pyc` - 缓存文件
- `*.log` - 日志文件
- `config.json`, `.env` - 敏感配置
- `backups/` - 备份目录

## ⚠️ 重要说明

### 文件大小限制

GitHub 对单个文件有限制（100MB），因此：
- ✅ 分发包作为**本地存档**保存在 `backups/` 目录
- ✅ 测试分支和标签会推送到 GitHub
- ✅ 部署报告会推送到 GitHub
- ❌ 分发包**不会**推送到 GitHub

如需远程备份分发包，请：
- 上传到云存储（Google Drive, Dropbox 等）
- 发布到 GitHub Releases
- 使用 Git LFS（需要配置）

## 📊 部署报告示例

部署完成后会生成 `DEPLOYMENT_REPORT_*.md`：

```markdown
# 部署报告

**部署时间**: 2026-03-12 08:49:35 AEDT
**测试分支**: `test-20260312-084935`
**Git 标签**: `v20260312-084935`

## 基本信息

| 项目 | 值 |
|------|-----|
| 提交哈希 | `a1b2c3d` |
| 测试分支 | [test-20260312-084935](https://github.com/...) |
| 标签 | [v20260312-084935](https://github.com/...) |

## 分发包信息

| 项目 | 值 |
|------|-----|
| 文件名 | nanobot-custom-20260312-084935.tar.gz |
| 文件大小 | 347M |
| 远程存储 | 本地存档（超过 100MB，未推送到 GitHub） |
```

## 🔒 安全特性

- ✅ 自动排除敏感文件（`config.json`, `.env`）
- ✅ 分发包不包含 Git 历史
- ✅ 每个部署创建独立测试分支
- ✅ 完整的部署报告记录

## 📝 典型使用场景

### 场景 1: 每次代码修改后部署

```bash
# 1. 修改代码
# ... 编辑文件 ...

# 2. 运行部署
./custom-skills/project-deploy/deploy.sh

# 3. 自动创建测试分支并推送
# 4. 从 backups/ 目录下载分发包测试
```

### 场景 2: 版本发布

```bash
# 1. 运行部署
./custom-skills/project-deploy/deploy.sh

# 2. 验证测试分支
git checkout test-20260312-084935

# 3. 测试通过后合并到 main
git checkout main
git merge test-20260312-084935
```

### 场景 3: 回滚到历史版本

```bash
# 1. 查看可用版本
./custom-skills/project-deploy/rollback.sh --list-tags

# 2. 回滚到指定标签
./custom-skills/project-deploy/rollback.sh --to-tag v20260312-0830

# 3. 或创建新分支继续开发
git checkout -b recovery-20260312
```

## 🛠️ 脚本位置

```
custom-skills/project-deploy/
├── deploy.sh          # 主部署脚本（推荐）
├── create-backup.sh   # 仅创建分发包
├── rollback.sh        # 回滚/管理工具
└── SKILL.md          # 本文档
```

## ⚠️ 注意事项

1. **确保已配置 Git**:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your@email.com"
   ```

2. **确保已设置远程仓库**:
   ```bash
   git remote -v
   # 应显示你的 GitHub 仓库地址
   ```

3. **分发包用途**:
   - ✅ 发布分享
   - ✅ 离线备份
   - ✅ 测试验证
   - ❌ 不是完整源码（不含 `.git/`）

4. **测试分支管理**:
   - 每次部署都会创建新测试分支
   - 测试后可选择合并或删除
   - 使用 `rollback.sh` 管理分支

---

**快速开始**:
```bash
cd /path/to/nanobot-custom
./custom-skills/project-deploy/deploy.sh
```
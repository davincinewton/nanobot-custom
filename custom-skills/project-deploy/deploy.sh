#!/bin/bash

# 自动化部署脚本
# 功能：创建测试分支 + 创建分发包 + 推送 + 生成报告
# 注意：分发包（>100MB）不会推送到 GitHub，仅作为本地存档

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取当前时间戳
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TIMESTAMP_DATE=$(date +%Y%m%d)
TIMESTAMP_TIME=$(date +%H%M)

# 测试分支名称
TEST_BRANCH="test-${TIMESTAMP}"

# 检查 git 状态
check_git_status() {
    print_info "检查 Git 状态..."
    
    # 检查是否有未提交的更改
    if [[ -n $(git status --porcelain) ]]; then
        print_warning "发现未提交的更改"
        print_info "正在提交更改..."
        
        git add .
        git commit -m "Deploy: Auto commit before deployment ($(date '+%Y-%m-%d %H:%M:%S'))" || {
            print_error "提交失败"
            exit 1
        }
        
        print_success "更改已提交"
    else
        print_info "工作区已干净"
    fi
    
    # 检查当前分支
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    print_info "当前分支：${current_branch}"
}

# 创建测试分支
create_test_branch() {
    print_info "创建测试分支：${TEST_BRANCH}"
    
    git checkout -b "$TEST_BRANCH" || {
        print_error "创建测试分支失败"
        exit 1
    }
    
    print_success "测试分支创建成功"
}

# 创建分发包
create_distribution_package() {
    print_info "创建分发包..."
    
    # 调用 backup 脚本
    if [[ -x "custom-skills/project-deploy/create-backup.sh" ]]; then
        ./custom-skills/project-deploy/create-backup.sh || {
            print_error "创建分发包失败"
            exit 1
        }
    else
        print_error "找不到 create-backup.sh 脚本"
        exit 1
    fi
    
    print_success "分发包创建成功"
}

# 注意：分发包不推送到 Git（超过 100MB 限制）
# 仅保留为本地存档
note_backup_location() {
    print_info "分发包位置说明..."
    
    # 检查备份文件
    local backup_file=$(ls -t backups/nanobot-custom-*.tar.gz 2>/dev/null | head -1)
    if [[ -f "$backup_file" ]]; then
        local size=$(du -h "$backup_file" | cut -f1)
        print_warning "分发包未推送到 GitHub（文件大小 ${size}，超过 100MB 限制）"
        print_info "本地存档位置：${backup_file}"
        print_info "如需远程备份，请手动上传到云存储或发布到 Releases"
    fi
    
    print_success "分发包已保存到本地"
}

# 推送到远程
push_to_github() {
    print_info "推送到 GitHub 远程仓库..."
    
    # 推送到测试分支
    git push -u origin "$TEST_BRANCH" || {
        print_error "推送到远程失败"
        exit 1
    }
    
    print_success "推送成功"
}

# 创建 Git 标签
create_tag() {
    local tag_name="v${TIMESTAMP_DATE}-${TIMESTAMP_TIME}"
    
    print_info "创建 Git 标签：${tag_name}"
    
    git tag "$tag_name"
    git push origin "$tag_name" || {
        print_warning "标签推送失败（可能已存在）"
    }
    
    print_success "标签创建成功"
}

# 生成部署报告
generate_report() {
    local report_file="DEPLOYMENT_REPORT_${TIMESTAMP}.md"
    
    print_info "生成部署报告..."
    
    # 获取 Git 信息
    local commit_hash=$(git rev-parse HEAD)
    local short_hash=$(echo "$commit_hash" | cut -c1-7)
    local commit_msg=$(git log -1 --pretty=%B)
    
    # 获取备份文件信息
    local backup_file=$(ls -t backups/nanobot-custom-*.tar.gz 2>/dev/null | head -1)
    local backup_name=""
    local backup_size="N/A"
    if [[ -f "$backup_file" ]]; then
        backup_name=$(basename "$backup_file")
        backup_size=$(du -h "$backup_file" | cut -f1)
    fi
    
    cat > "$report_file" << EOF
# 部署报告

**部署时间**: $(date '+%Y-%m-%d %H:%M:%S %Z')
**测试分支**: \`${TEST_BRANCH}\`
**Git 标签**: \`v${TIMESTAMP_DATE}-${TIMESTAMP_TIME}\`

## 基本信息

| 项目 | 值 |
|------|-----|
| 提交哈希 | \`$short_hash\` |
| 提交信息 | ${commit_msg%%$'\n'*} |
| 测试分支 | $TEST_BRANCH (在 GitHub 查看) |
| 标签 | v${TIMESTAMP_DATE}-${TIMESTAMP_TIME} |

## 分发包信息

| 项目 | 值 |
|------|-----|
| 文件名 | $backup_name |
| 文件大小 | ${backup_size} |
| 文件路径 | \`backups/$backup_name\` |
| 远程存储 | 本地存档（超过 100MB，未推送到 GitHub） |

## 部署步骤

1. ✅ 检查工作区状态
2. ✅ 创建测试分支 \`${TEST_BRANCH}\`
3. ✅ 创建分发包
4. ✅ 记录分发包位置（本地存档）
5. ✅ 推送到 GitHub（测试分支 + 标签）
6. ✅ 生成部署报告

## 快速访问

- 查看测试分支：git checkout $TEST_BRANCH
- 下载分发包：从本地 backups/ 目录获取
- 回滚到当前版本：git checkout v${TIMESTAMP_DATE}-${TIMESTAMP_TIME}

## 注意事项

- ⚠️ 此分支为自动创建的测试分支
- ⚠️ 分发包已排除敏感文件（.git/, venv/, config.json 等）
- ⚠️ 分发包超过 100MB，未推送到 GitHub，仅作为本地存档
- ⚠️ 如需合并到主分支，请手动执行 \`git checkout main && git merge ${TEST_BRANCH}\`

---
*此报告由自动部署脚本生成*
EOF
    
    # 添加报告到 git 并提交
    git add "$report_file"
    git commit -m "Report: Deployment report for ${TEST_BRANCH}" 
    git push origin "$TEST_BRANCH"
    
    print_success "部署报告已生成：${report_file}"
}

# 回滚到主要分支
rollback_to_main() {
    print_info "切换回 main 分支..."
    
    git checkout main || git checkout master || {
        print_warning "无法切换到 main/master 分支"
        return 1
    }
    
    print_success "已切换到主分支"
}

# 主函数
main() {
    print_info "========================================="
    print_info "  nanobot-custom 自动部署工具"
    print_info "  测试分支：${TEST_BRANCH}"
    print_info "  时间戳：${TIMESTAMP}"
    print_info "========================================="
    
    # 检查是否在项目根目录
    if [[ ! -f "install.sh" ]] || [[ ! -d "nanobot" ]]; then
        print_error "请在 nanobot-custom 项目根目录运行此脚本"
        exit 1
    fi
    
    # 检查是否是 git 仓库
    if [[ ! -d ".git" ]]; then
        print_error "不是 Git 仓库"
        exit 1
    fi
    
    # 执行部署步骤
    check_git_status
    create_test_branch
    create_distribution_package
    note_backup_location    # 仅记录，不推送大文件
    push_to_github
    create_tag
    generate_report
    
    print_info "========================================="
    print_success "部署完成！"
    print_info "测试分支: ${TEST_BRANCH}"
    print_info "Git 标签: v${TIMESTAMP_DATE}-${TIMESTAMP_TIME}"
    print_info "分发包：backups/nanobot-custom-${TIMESTAMP}.tar.gz"
    print_info "报告：DEPLOYMENT_REPORT_${TIMESTAMP}.md"
    print_info "========================================="
    
    # 切换回主分支（可选）
    rollback_to_main
    
    print_info "========================================="
    print_success "所有任务完成！"
    print_info "========================================="
}

# 执行主函数
main "$@"
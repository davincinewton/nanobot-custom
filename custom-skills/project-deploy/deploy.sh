#!/bin/bash

# ============================================================================
# nanobot-custom 自动化部署脚本
# 版本: 2.0.0
# 功能: 安全检查 + 自动部署 + 生成报告
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
REPO_NAME="nanobot-custom"
CHECK_ONLY=false
DRY_RUN=false
CUSTOM_TAG=""

# 统计
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=()

# 打印函数
print_header() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((CHECKS_PASSED++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((CHECKS_FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARNINGS+=("$1")
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check)
                CHECK_ONLY=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --tag)
                CUSTOM_TAG="$2"
                shift 2
                ;;
            -h|--help)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --check      仅执行安全检查，不部署"
                echo "  --dry-run    模拟执行（不实际推送）"
                echo "  --tag 版本  创建指定版本的标签"
                echo "  -h, --help   显示帮助信息"
                exit 0
                ;;
            *)
                echo "未知选项: $1"
                exit 1
                ;;
        esac
    done
}

# 安全检查函数
run_security_checks() {
    print_header "🔐 安全检查"
    
    local has_errors=false
    
    # 1. 敏感信息扫描
    print_info "正在扫描敏感信息..."
    
    # 检查真正硬编码的密钥 (排除注释、示例和空值)
    local secret_found=false
    
    # 检查 ghp_ 开头的真实密钥 (排除注释和示例)
    local ghp_matches=$(grep -rn "ghp_[a-zA-Z0-9]\{36\}" --include="*.py" --include="*.sh" --include="*.json" . 2>/dev/null | \
                        grep -v "^[^:]*:[^:]*#[^:]*ghp_" | \
                        grep -v "example\|your_\|xxx\|placeholder" || true)
    
    if [ -n "$ghp_matches" ]; then
        print_error "发现硬编码的 GitHub Token！"
        echo "$ghp_matches" | head -3
        secret_found=true
    fi
    
    # 检查 sk- 开头的真实密钥 (OpenAI 等)
    local sk_matches=$(grep -rn "sk-[a-zA-Z0-9]\{40,\}" --include="*.py" --include="*.sh" --include="*.json" . 2>/dev/null | \
                       grep -v "^[^:]*:[^:]*#[^:]*sk-" | \
                       grep -v "example\|your_\|xxx\|placeholder" || true)
    
    if [ -n "$sk_matches" ]; then
        print_error "发现硬编码的 API 密钥！"
        echo "$sk_matches" | head -3
        secret_found=true
    fi
    
    # 检查 discord_bot_token 实际赋值
    local discord_matches=$(grep -rn "discord_bot_token[[:space:]]*=[[:space:]]*[\"'][^\"']\{10,\}" --include="*.py" --include="*.sh" . 2>/dev/null | \
                            grep -v "example\|your_\|xxx" || true)
    
    if [ -n "$discord_matches" ]; then
        print_error "发现硬编码的 Discord Token！"
        echo "$discord_matches" | head -3
        secret_found=true
    fi
    
    if [ "$secret_found" = true ]; then
        has_errors=true
    else
        print_success "未发现硬编码密钥"
    fi
    
    # 检查 .env 文件
    if find . -maxdepth 3 -name ".env*" -type f 2>/dev/null | grep -q .; then
        print_error "发现 .env 文件！"
        find . -maxdepth 3 -name ".env*" -type f 2>/dev/null
        has_errors=true
    else
        print_success "未发现 .env 文件"
    fi
    
    # 检查 config.json
    if find . -maxdepth 3 -name "config.json" -type f 2>/dev/null | grep -q .; then
        print_error "发现 config.json 文件！"
        find . -maxdepth 3 -name "config.json" -type f 2>/dev/null
        has_errors=true
    else
        print_success "未发现 config.json 文件"
    fi
    
    # 2. 验证 .gitignore
    print_info "正在验证 .gitignore..."
    
    if [ ! -f ".gitignore" ]; then
        print_error "缺少 .gitignore 文件！"
        has_errors=true
    else
        local gitignore_ok=true
        
        if ! grep -q "config.json" .gitignore; then
            print_warning ".gitignore 缺少 config.json"
            gitignore_ok=false
        fi
        
        if ! grep -q "\.env" .gitignore; then
            print_warning ".gitignore 缺少 .env"
            gitignore_ok=false
        fi
        
        if ! grep -q "venv/" .gitignore; then
            print_warning ".gitignore 缺少 venv/"
            gitignore_ok=false
        fi
        
        if [ "$gitignore_ok" = true ]; then
            print_success ".gitignore 配置正确"
        fi
    fi
    
    # 3. 文件完整性检查
    print_info "正在验证必需文件..."
    
    local required_files=(
        "install.sh"
        "start-nanobot.sh"
        "README.md"
        "pyproject.toml"
    )
    
    local required_dirs=(
        "custom-skills"
        "web-channel"
        "nanobot"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "找到: $file"
        else
            print_error "缺少文件: $file"
            has_errors=true
        fi
    done
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_success "找到目录: $dir/"
        else
            print_error "缺少目录: $dir/"
            has_errors=true
        fi
    done
    
    # 4. Git 状态检查
    print_info "正在检查 Git 状态..."
    
    if ! git status --porcelain 2>/dev/null | grep -q .; then
        print_success "工作区干净（无未提交更改）"
    else
        print_warning "存在未提交的更改："
        git status --short | head -10
    fi
    
    # 检查远程仓库
    if git remote -v | grep -q origin; then
        print_success "远程仓库配置正确"
    else
        print_error "缺少远程仓库 'origin'"
        has_errors=true
    fi
    
    # 返回检查结果
    if [ "$has_errors" = true ]; then
        print_header "❌ 安全检查失败"
        echo "请解决上述错误后再继续部署。"
        return 1
    else
        print_header "✅ 安全检查通过"
        return 0
    fi
}

# 部署函数
deploy() {
    print_header "🚀 开始部署"
    
    # 获取时间戳
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    TEST_BRANCH="test-${TIMESTAMP}"
    TAG_NAME="${CUSTOM_TAG:-v1.0.0-${TIMESTAMP}}"
    
    print_info "部署分支: ${TEST_BRANCH}"
    print_info "标签版本: ${TAG_NAME}"
    
    # 如果是 dry-run，只模拟不执行
    if [ "$DRY_RUN" = true ]; then
        print_warning "干燥运行模式，不实际执行推送"
        print_info "模拟操作："
        echo "  1. 创建分支: ${TEST_BRANCH}"
        echo "  2. 提交更改"
        echo "  3. 推送到远程"
        echo "  4. 创建标签: ${TAG_NAME}"
        echo "  5. 生成部署报告"
        print_info "模拟完成（未实际执行）"
        return 0
    fi
    
    # 1. 创建测试分支
    print_info "正在创建测试分支..."
    git checkout -b "${TEST_BRANCH}"
    print_success "已切换到分支: ${TEST_BRANCH}"
    
    # 2. 提交更改
    print_info "正在提交更改..."
    COMMIT_MSG="自动部署：$(date '+%Y-%m-%d %H:%M:%S')"
    git add .
    git commit -m "${COMMIT_MSG}" || echo "没有更改需要提交"
    
    # 3. 推送到远程
    print_info "正在推送到远程仓库..."
    git push -u origin "${TEST_BRANCH}"
    print_success "已推送到分支: ${TEST_BRANCH}"
    
    # 4. 创建标签
    print_info "正在创建标签..."
    git tag -a "${TAG_NAME}" -m "Release ${TAG_NAME}"
    git push origin "${TAG_NAME}"
    print_success "已创建标签: ${TAG_NAME}"
    
    # 5. 切换回原分支
    print_info "切换回原分支..."
    git checkout main 2>/dev/null || git checkout master 2>/dev/null || git checkout
    print_success "已切换回原分支"
    
    # 生成部署报告
    generate_report "${TEST_BRANCH}" "${TAG_NAME}"
    
    print_header "✅ 部署完成"
    echo "📊 部署报告：DEPLOYMENT_REPORT.md"
    echo "🔗 仓库：https://github.com/davincinewton/${REPO_NAME}"
    echo "🌿 测试分支: ${TEST_BRANCH}"
    echo "🏷️ 标签: ${TAG_NAME}"
}

# 生成部署报告
generate_report() {
    local branch_name=$1
    local tag_name=$2
    
    print_info "正在生成部署报告..."
    
    cat > DEPLOYMENT_REPORT.md << EOF
# 部署报告

## 基本信息
- **部署时间**: $(date '+%Y-%m-%d %H:%M:%S')
- **项目**: ${REPO_NAME}
- **仓库**: https://github.com/davincinewton/${REPO_NAME}
- **分支**: main → ${branch_name}

## 安全检查结果
✅ 敏感信息扫描: 通过
✅ 文件完整性: 通过
✅ .gitignore: 正确配置
✅ Git 状态: 验证通过

## Git 操作
- **提交**: $(git log -1 --format='%h %s')
- **分支**: ${branch_name}
- **标签**: ${tag_name}

## 警告记录
$(if [ ${#WARNINGS[@]} -gt 0 ]; then
    for warning in "${WARNINGS[@]}"; do
        echo "- ⚠️  $warning"
    done
else
    echo "无"
fi)

## 部署状态
✅ 成功

## 下一步
1. 验证测试分支内容
2. 合并到 main（如需要）
3. 更新版本文档

---
*此报告由 deploy.sh 自动生成*
EOF
    
    print_success "部署报告已生成: DEPLOYMENT_REPORT.md"
}

# 显示检查结果
show_check_results() {
    print_header "📊 检查结果"
    
    echo "通过: ${CHECKS_PASSED}"
    echo "失败: ${CHECKS_FAILED}"
    
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo ""
        echo "警告:"
        for warning in "${WARNINGS[@]}"; do
            echo "  ⚠️  $warning"
        done
    fi
    
    if [ ${CHECKS_FAILED} -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ 所有检查通过，可以安全部署！${NC}"
    else
        echo ""
        echo -e "${RED}❌ 存在错误，请先修复后再部署${NC}"
    fi
}

# 主函数
main() {
    parse_args "$@"
    
    print_header "🔧 nanobot-custom 部署工具 v2.0.0"
    
    # 检查是否在正确的项目目录
    if [ ! -d ".git" ]; then
        print_error "当前目录不是 Git 仓库！"
        print_info "请进入项目目录后运行此脚本。"
        exit 1
    fi
    
    # 运行安全检查
    if ! run_security_checks; then
        show_check_results
        exit 1
    fi
    
    # 如果只检查，退出
    if [ "$CHECK_ONLY" = true ]; then
        show_check_results
        exit 0
    fi
    
    # 执行部署
    deploy
    
    show_check_results
}

# 运行主函数
main "$@"
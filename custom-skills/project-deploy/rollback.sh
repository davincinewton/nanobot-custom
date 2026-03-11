#!/bin/bash

# 回滚工具脚本
# 功能：列出所有测试分支和标签，支持一键回滚

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

# 列出所有测试分支
list_test_branches() {
    print_info "========================================="
    print_info "  可用的测试分支"
    print_info "========================================="
    
    local branches=$(git branch -r | grep "origin/test-" | sed 's/origin\///' | sort -r)
    
    if [[ -z "$branches" ]]; then
        print_warning "没有发现测试分支"
        return
    fi
    
    echo "$branches" | while read branch; do
        local commit=$(git rev-parse --short "$branch" 2>/dev/null || echo "N/A")
        local date=$(git log -1 --format=%ci "$branch" 2>/dev/null | cut -d' ' -f1 || echo "N/A")
        echo "  - ${branch} (${commit}) - ${date}"
    done
}

# 列出所有标签
list_tags() {
    print_info "========================================="
    print_info "  可用的 Git 标签"
    print_info "========================================="
    
    local tags=$(git tag -l "v*" | sort -r | head -20)
    
    if [[ -z "$tags" ]]; then
        print_warning "没有发现标签"
        return
    fi
    
    echo "$tags" | while read tag; do
        local commit=$(git rev-parse --short "$tag" 2>/dev/null || echo "N/A")
        local date=$(git log -1 --format=%ci "$tag" 2>/dev/null | cut -d' ' -f1 || echo "N/A")
        echo "  - ${tag} (${commit}) - ${date}"
    done
}

# 回滚到指定分支
rollback_to_branch() {
    local target_branch=$1
    
    print_info "回滚到分支：${target_branch}"
    
    # 确保远程分支已获取
    git fetch origin
    
    # 创建或切换本地分支
    if git show-ref --verify --quiet "refs/heads/${target_branch}"; then
        git checkout "${target_branch}"
    else
        git checkout -b "${target_branch}" "origin/${target_branch}"
    fi
    
    print_success "已切换到 ${target_branch}"
}

# 回滚到指定标签
rollback_to_tag() {
    local target_tag=$1
    
    print_info "回滚到标签：${target_tag} ( detached HEAD 状态 )"
    
    git checkout "${target_tag}"
    
    print_success "已切换到 ${target_tag}"
    print_warning "注意：当前处于 detached HEAD 状态"
    print_info "如需创建新分支，运行：git checkout -b <new-branch-name>"
}

# 删除测试分支
delete_test_branch() {
    local target_branch=$1
    
    print_warning "准备删除测试分支：${target_branch}"
    read -p "确定要删除吗？(y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 删除本地分支
        git branch -D "${target_branch}" 2>/dev/null || true
        
        # 删除远程分支
        git push origin --delete "${target_branch}" 2>/dev/null || true
        
        print_success "已删除 ${target_branch}"
    else
        print_info "已取消操作"
    fi
}

# 显示菜单
show_menu() {
    echo ""
    print_info "========================================="
    print_info "  回滚工具菜单"
    print_info "========================================="
    echo "1. 列出所有测试分支"
    echo "2. 列出所有标签"
    echo "3. 回滚到指定分支"
    echo "4. 回滚到指定标签"
    echo "5. 删除指定测试分支"
    echo "6. 退出"
    echo "========================================="
    echo -n "请选择 (1-6): "
}

# 主函数
main() {
    # 检查是否在项目根目录
    if [[ ! -d ".git" ]]; then
        print_error "不是 Git 仓库"
        exit 1
    fi
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                list_test_branches
                ;;
            2)
                list_tags
                ;;
            3)
                print_info "请输入分支名称:"
                read -r branch_name
                if [[ -n "$branch_name" ]]; then
                    rollback_to_branch "$branch_name"
                else
                    print_warning "分支名称不能为空"
                fi
                ;;
            4)
                print_info "请输入标签名称:"
                read -r tag_name
                if [[ -n "$tag_name" ]]; then
                    rollback_to_tag "$tag_name"
                else
                    print_warning "标签名称不能为空"
                fi
                ;;
            5)
                print_info "请输入要删除的分支名称:"
                read -r branch_name
                if [[ -n "$branch_name" ]]; then
                    delete_test_branch "$branch_name"
                else
                    print_warning "分支名称不能为空"
                fi
                ;;
            6)
                print_info "退出"
                exit 0
                ;;
            *)
                print_warning "无效的选择，请重新输入"
                ;;
        esac
        
        echo ""
        print_info "按回车键继续..."
        read -r
    done
}

# 如果提供了参数，直接执行相应操作
if [[ $# -gt 0 ]]; then
    case "$1" in
        --list-branches|-lb)
            list_test_branches
            ;;
        --list-tags|-lt)
            list_tags
            ;;
        --to-branch|-tb)
            if [[ -z "$2" ]]; then
                print_error "请指定分支名称"
                exit 1
            fi
            rollback_to_branch "$2"
            ;;
        --to-tag|-tt)
            if [[ -z "$2" ]]; then
                print_error "请指定标签名称"
                exit 1
            fi
            rollback_to_tag "$2"
            ;;
        --delete|-d)
            if [[ -z "$2" ]]; then
                print_error "请指定要删除的分支名称"
                exit 1
            fi
            delete_test_branch "$2"
            ;;
        --help|-h)
            echo "使用方法:"
            echo "  $0                     # 交互式菜单"
            echo "  $0 --list-branches     # 列出测试分支"
            echo "  $0 --list-tags         # 列出标签"
            echo "  $0 --to-branch <name>  # 回滚到分支"
            echo "  $0 --to-tag <name>     # 回滚到标签"
            echo "  $0 --delete <name>     # 删除分支"
            echo "  $0 --help              # 显示帮助"
            ;;
        *)
            print_error "未知参数：$1"
            echo "使用 $0 --help 查看帮助"
            exit 1
            ;;
    esac
else
    # 没有参数，显示交互式菜单
    main
fi
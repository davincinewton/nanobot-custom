#!/bin/bash

# 创建项目分发包脚本
# 用于发布和分享 nanobot-custom 项目（不包含 .git/ 等敏感文件）

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

# 检查必需文件
check_files() {
    print_info "检查必需文件..."
    
    local missing=0
    
    for file in install.sh README.md pyproject.toml; do
        if [[ ! -f "$file" ]]; then
            print_error "缺少必需文件：$file"
            missing=1
        fi
    done
    
    if [[ ! -d "custom-skills" ]]; then
        print_error "缺少目录：custom-skills/"
        missing=1
    fi
    
    if [[ $missing -eq 1 ]]; then
        print_error "文件检查失败，请确保在项目根目录运行此脚本"
        exit 1
    fi
    
    print_success "文件检查通过"
}

# 创建备份
create_backup() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="backups"
    local backup_name="nanobot-custom-${timestamp}.tar.gz"
    local backup_path="${backup_dir}/${backup_name}"
    
    print_info "创建分发包..."
    print_info "时间戳：${timestamp}"
    
    # 创建备份目录
    mkdir -p "$backup_dir"
    
    # 创建排除文件列表
    local exclude_file=$(mktemp)
    cat > "$exclude_file" << EOF
.git/
.gitignore
__pycache__/
*.pyc
*.log
*.pid
venv/
.venv/
env/
*.egg-info/
.build/
dist/
*.swp
*.swo
*~
.DS_Store
Thumbs.db
memory/*.log
sessions/*.log
config.json
.env
.env.*
*.bak
backups/
EOF
    
    print_info "打包项目（排除 .git/ 和开发文件）..."
    
    # 创建 tar.gz 压缩包（临时文件，避免备份目录在打包时变化）
    local temp_backup=$(mktemp)
    tar -czf "$temp_backup" \
        --exclude-from="$exclude_file" \
        . 2>/dev/null || tar -czf "$temp_backup" .
    
    # 移动到最终位置
    mv "$temp_backup" "$backup_path"
    
    rm -f "$exclude_file"
    
    # 验证压缩包
    if [[ -f "$backup_path" ]]; then
        local size=$(du -h "$backup_path" | cut -f1)
        print_success "分发包创建成功：${backup_path}"
        print_info "文件大小：${size}"
        
        # 验证压缩包完整性
        print_info "验证压缩包完整性..."
        if tar -tzf "$backup_path" > /dev/null 2>&1; then
            print_success "压缩包验证通过"
            
            # 列出主要文件
            print_info "包内主要文件："
            tar -tzf "$backup_path" | grep -E '^[^/]+\.(sh|md|toml|py)$|custom-skills/|web-channel/' | head -20
            
            return 0
        else
            print_error "压缩包验证失败"
            return 1
        fi
    else
        print_error "分发包创建失败"
        return 1
    fi
}

# 主函数
main() {
    print_info "========================================="
    print_info "  nanobot-custom 分发包创建工具"
    print_info "========================================="
    
    # 检查是否在项目根目录
    if [[ ! -f "install.sh" ]] || [[ ! -d "nanobot" ]]; then
        print_error "请在 nanobot-custom 项目根目录运行此脚本"
        exit 1
    fi
    
    check_files
    create_backup
    
    print_info "========================================="
    print_success "分发包创建完成！"
    print_info "位置：backups/nanobot-custom-*.tar.gz"
    print_info "可用于发布和分发"
    print_info "========================================="
}

# 执行主函数
main "$@"
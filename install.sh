#!/bin/bash

# nanobot-custom 完整安装脚本
# 正确的安装流程：
# 1. 创建 Python venv 并激活
# 2. 运行 pip install -e .
# 3. 运行 nanobot onboard（必须先运行，创建 workspace/skills 目录）
# 4. 安装所有定制的东西（Skills, Web Channel）
# 5. 提示用户编辑 config.json 然后运行 nanobot agent 或 gateway

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查 Python 版本
check_python() {
    print_info "检查 Python 版本..."
    
    if ! command -v python3 &> /dev/null; then
        print_error "未找到 Python 3，请先安装 Python 3.11+"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    print_success "Python 版本：$PYTHON_VERSION"
    
    # 检查版本是否 >= 3.11
    if [[ $(echo "$PYTHON_VERSION < 3.11" | bc -l) -eq 1 ]]; then
        print_error "需要 Python 3.11 或更高版本"
        exit 1
    fi
}

# 检查 pip
check_pip() {
    print_info "检查 pip..."
    
    if ! command -v pip3 &> /dev/null; then
        print_error "未找到 pip3，请先安装 pip"
        exit 1
    fi
    
    print_success "pip 版本：$(pip3 --version)"
}

# 创建虚拟环境
create_venv() {
    print_info "创建虚拟环境..."
    
    if [ -d "venv" ]; then
        print_warning "虚拟环境已存在，将重新创建..."
        rm -rf venv
    fi
    
    python3 -m venv venv
    print_success "虚拟环境创建成功：$(pwd)/venv"
}

# 激活虚拟环境
activate_venv() {
    print_info "激活虚拟环境..."
    
    source venv/bin/activate
    print_success "虚拟环境已激活"
}

# 升级 pip
upgrade_pip() {
    print_info "升级 pip..."
    
    pip install --upgrade pip setuptools wheel
    print_success "pip 已升级"
}

# 安装核心依赖（包含 ddgs, requests）
install_core() {
    print_info "安装核心依赖（包含 ddgs, requests）..."
    
    pip install -e .
    print_success "核心依赖安装成功"
}

# 安装 jina-cli
install_jina_cli() {
    print_info "安装 jina-cli CLI 工具..."
    
    pip install jina-cli
    print_success "jina-cli 安装成功"
}

# 安装 Web Channel 依赖
install_web_channel_deps() {
    print_info "安装 Web Channel Python 依赖..."
    
    if [ -f "web-channel/requirements.txt" ]; then
        pip install -r web-channel/requirements.txt
        print_success "Web Channel 依赖安装成功"
    else
        print_warning "未找到 web-channel/requirements.txt"
    fi
}

# 初始化 nanobot（必须先运行，创建 workspace/skills 目录）
initialize_nanobot() {
    print_info "初始化 nanobot 配置（创建 workspace/skills 目录）..."
    
    python -m nanobot onboard
    print_success "nanobot 初始化完成，workspace/skills 目录已创建"
}

# 安装 Skills 到正确位置
install_skills() {
    print_info "安装 Skills 到 ~/.nanobot/workspace/skills/..."
    
    # 创建目标目录（onboard 已经创建了）
    mkdir -p ~/.nanobot/workspace/skills
    
    # 复制 custom-skills 到目标位置
    if [ -d "custom-skills" ]; then
        cp -r custom-skills/* ~/.nanobot/workspace/skills/
        print_success "Skills 已安装到 ~/.nanobot/workspace/skills/"
        
        # 显示已安装的 Skills
        print_info "已安装的 Skills:"
        ls -1 ~/.nanobot/workspace/skills/ | while read skill; do
            echo "  - $skill"
        done
    else
        print_warning "未找到 custom-skills 目录"
    fi
}

# 安装 Web Channel
install_web_channel() {
    print_info "安装 Web Channel 到 ~/.nanobot/workspace/web-channel/..."
    
    # 创建目标目录
    mkdir -p ~/.nanobot/workspace/web-channel
    
    # 复制 web-channel 到目标位置
    if [ -d "web-channel" ]; then
        cp -r web-channel/* ~/.nanobot/workspace/web-channel/
        print_success "Web Channel 已安装到 ~/.nanobot/workspace/web-channel/"
        
        # 显示安装的文件
        print_info "已安装的文件:"
        ls -1 ~/.nanobot/workspace/web-channel/ | while read file; do
            echo "  - $file"
        done
    else
        print_warning "未找到 web-channel 目录"
    fi
}

# 显示安装完成信息和下一步操作
show_completion_info() {
    print_success "=========================================="
    print_success "nanobot-custom 安装完成！"
    print_success "=========================================="
    echo ""
    print_info "=========================================="
    print_info "下一步操作："
    print_info "=========================================="
    echo ""
    print_warning "1. 编辑配置文件"
    echo ""
    print_info "   请编辑 config.json 文件配置您的 nanobot:"
    echo ""
    echo -e "   ${BLUE}~/.nanobot/config.json${NC}"
    echo ""
    print_info "   主要配置项:"
    echo "   - Telegram Bot Token"
    echo "   - 其他 API 密钥"
    echo "   - 系统设置"
    echo ""
    print_warning "2. 启动 nanobot"
    echo ""
    print_info "   选择以下一种方式启动:"
    echo ""
    echo -e "   ${BLUE}方式 1: 启动 Agent${NC}"
    echo "   source venv/bin/activate"
    echo "   python -m nanobot agent"
    echo ""
    echo -e "   ${BLUE}方式 2: 启动 Gateway${NC}"
    echo "   source venv/bin/activate"
    echo "   python -m nanobot gateway"
    echo ""
    print_info "3. 启动 Web Channel（可选）"
    echo ""
    print_info "   cd ~/.nanobot/workspace/web-channel"
    print_info "   python3 app.py"
    print_info "   访问：http://localhost:5000"
    echo ""
    print_success "=========================================="
    print_success "更多信息请查看 README.md 和 INSTALLATION_PLAN.md"
    print_success "=========================================="
    echo ""
}

# 主函数
main() {
    print_info "=========================================="
    print_info "nanobot-custom 完整安装脚本"
    print_info "=========================================="
    echo ""
    
    # 1. 检查系统
    print_info "步骤 1/6: 检查系统..."
    check_python
    check_pip
    echo ""
    
    # 2. 创建虚拟环境
    print_info "步骤 2/6: 创建虚拟环境..."
    create_venv
    activate_venv
    upgrade_pip
    echo ""
    
    # 3. 安装核心依赖
    print_info "步骤 3/6: 安装核心依赖（包含 ddgs, requests）..."
    install_core
    install_jina_cli
    install_web_channel_deps
    echo ""
    
    # 4. 初始化 nanobot（必须先运行，创建 workspace/skills 目录）
    print_info "步骤 4/6: 初始化 nanobot（创建 workspace/skills 目录）..."
    initialize_nanobot
    echo ""
    
    # 5. 安装定制组件
    print_info "步骤 5/6: 安装定制组件..."
    install_skills
    install_web_channel
    echo ""
    
    # 6. 显示完成信息
    print_info "步骤 6/6: 显示下一步操作..."
    show_completion_info
    echo ""
    
    # 退出（需要用户手动编辑 config.json）
    print_info "安装完成！请按照提示编辑 config.json 然后启动 nanobot。"
    echo ""
    print_warning "按 Enter 键退出..."
    read -r
    
    exit 0
}

# 运行主函数
main "$@"

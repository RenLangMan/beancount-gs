#!/bin/bash

###
 # @Author: liangzai450
 # @Date: 2025-09-13
 # @Description: Beancount v3 环境清理和启动脚本
 # 用法: 
 #   ./run.sh          # 快速模式 (默认，不清理缓存和虚拟环境)
 #   ./run.sh clean    # 完整重构模式 (清理所有缓存和虚拟环境)
 #   ./run.sh help     # 显示帮助信息
 # Copyright (c) 2025 by ${git_name_email}, All Rights Reserved. 
### 

# 模式设置
MODE="${1:-fast}"  # 默认快速模式

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# 显示帮助信息
show_help() {
    echo "========================================"
    echo "Beancount v3 环境启动脚本"
    echo "========================================"
    echo "用法: $0 [模式]"
    echo ""
    echo "模式选项:"
    echo "  fast      快速模式 - 不清理缓存和虚拟环境 (默认)"
    echo "  clean     完整重构模式 - 清理所有缓存和虚拟环境"
    echo "  help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0          # 快速启动"
    echo "  $0 fast     # 快速启动"
    echo "  $0 clean    # 完整重构"
    echo "  $0 help     # 显示帮助"
    echo "========================================"
}

# 清理函数 - 完整重构模式
clean_environment() {
    print_info "开始完整清理环境..."
    
    # 1. 检查并删除 beancount-gs
    BEANCOUNT_GS="/workspace/beancount-gs"
    print_info "检查 beancount-gs 文件: $BEANCOUNT_GS"
    
    if [ -f "$BEANCOUNT_GS" ]; then
        print_warning "发现已存在的 beancount-gs 文件，正在删除..."
        rm -f "$BEANCOUNT_GS"
        if [ $? -eq 0 ]; then
            print_success "beancount-gs 删除成功"
        else
            print_error "beancount-gs 删除失败"
            exit 1
        fi
    else
        print_info "没有发现已存在的 beancount-gs 文件"
    fi

    # 2. 删除 Go 缓存
    print_info "清理 Go 缓存..."
    if command -v go >/dev/null 2>&1; then
        print_info "清理 Go 构建缓存..."
        go clean -cache
        
        print_info "清理 Go 模块缓存..."
        go clean -modcache
        
        print_success "Go 缓存清理完成"
    else
        print_warning "Go 未安装，跳过缓存清理"
    fi

    # 3. 检查并删除现有的虚拟环境
    VENV_DIR="/workspace/.env_beancount-v3"
    print_info "检查现有的虚拟环境: $VENV_DIR"
    
    if [ -d "$VENV_DIR" ]; then
        print_warning "发现已存在的虚拟环境，正在删除..."
        rm -rf "$VENV_DIR"
        if [ $? -eq 0 ]; then
            print_success "虚拟环境删除成功"
        else
            print_error "虚拟环境删除失败"
            exit 1
        fi
    else
        print_info "没有发现已存在的虚拟环境"
    fi

    # 4. 检查并删除依赖文件
    REQUIREMENTS_FILE="/workspace/requirements-beancount-v3.txt"
    print_info "检查现有的依赖文件: $REQUIREMENTS_FILE"
    
    if [ -f "$REQUIREMENTS_FILE" ]; then
        print_warning "发现已存在的依赖文件，正在删除..."
        rm -f "$REQUIREMENTS_FILE"
        if [ $? -eq 0 ]; then
            print_success "依赖文件删除成功"
        else
            print_error "依赖文件删除失败"
        fi
    else
        print_info "没有发现已存在的依赖文件"
    fi
    
    # 5. 清理 Python 缓存文件
    print_info "清理 Python 缓存文件..."
    find /workspace -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
    find /workspace -name "*.pyc" -delete 2>/dev/null
    find /workspace -name "*.pyo" -delete 2>/dev/null
    print_success "Python 缓存清理完成"
}

# 快速模式准备
fast_prepare() {
    print_info "快速模式 - 仅进行基础检查..."
    
    # 只检查必要项，不清理
    BEANCOUNT_GS="/workspace/beancount-gs"
    if [ -f "$BEANCOUNT_GS" ]; then
        print_warning "发现已存在的 beancount-gs 文件，快速模式将保留"
    fi
    
    VENV_DIR="/workspace/.env_beancount-v3"
    if [ -d "$VENV_DIR" ]; then
        print_info "使用现有虚拟环境: $VENV_DIR"
    else
        print_warning "虚拟环境不存在，启动脚本将自动创建"
    fi
}

# 主函数
main() {
    # 清屏
    clear
    
    # 显示模式信息
    echo "========================================"
    echo "Beancount v3 环境启动脚本"
    echo "模式: $MODE"
    echo "========================================"

    # 处理帮助请求
    if [ "$MODE" = "help" ] || [ "$MODE" = "-h" ] || [ "$MODE" = "--help" ]; then
        show_help
        exit 0
    fi

    # 验证模式参数
    case "$MODE" in
        "fast"|"clean")
            # 有效模式，继续执行
            ;;
        *)
            print_error "未知模式: $MODE"
            show_help
            exit 1
            ;;
    esac

    # 1. 检查启动脚本是否存在
    START_SCRIPT="/workspace/.scripts/start_on_cnb.sh"
    print_info "检查启动脚本: $START_SCRIPT"
    
    if [ ! -f "$START_SCRIPT" ]; then
        print_error "启动脚本不存在: $START_SCRIPT"
        echo "请确保脚本路径正确"
        exit 1
    fi
    print_success "启动脚本存在"

    # 2. 添加可执行权限
    print_info "添加启动脚本可执行权限..."
    chmod +x "$START_SCRIPT"
    if [ $? -eq 0 ]; then
        print_success "可执行权限添加成功"
    else
        print_error "可执行权限添加失败"
        exit 1
    fi

    # 3. 根据模式进行环境准备
    case "$MODE" in
        "clean")
            clean_environment
            ;;
        "fast")
            fast_prepare
            ;;
    esac

    echo ""
    echo "========================================"
    print_info "开始执行 Beancount v3 环境构建 ($MODE 模式)..."
    echo "========================================"

    # 4. 执行启动脚本
    "$START_SCRIPT"

    # 5. 检查执行结果
    if [ $? -eq 0 ]; then
        echo ""
        echo "========================================"
        print_success "Beancount v3 环境构建完成！ ($MODE 模式)"
        echo "========================================"
        
        # 显示模式提示
        case "$MODE" in
            "fast")
                print_info "提示: 如需完整重构，请运行: $0 clean"
                ;;
            "clean")
                print_success "环境已完全重构，所有缓存已清理"
                ;;
        esac
    else
        echo ""
        echo "========================================"
        print_error "Beancount v3 环境构建失败！"
        echo "========================================"
        
        # 失败时建议
        print_warning "建议: 如果遇到依赖问题，尝试完整重构模式: $0 clean"
        exit 1
    fi
}

# 执行主函数
main "$@"
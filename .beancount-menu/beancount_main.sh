#!/bin/bash

###
# @Author: liangzai450
# @Description: Beancount 跨平台统一管理菜单
# 支持: Linux, Windows Git Bash
# 用法: ./beancount_main.sh [模式]
# 模式: fast (默认), clean, help
###

# 模式设置
MODE="${1:-fast}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 基础路径 - 动态获取并适配多平台
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FUNCTIONS_FILE="$SCRIPT_DIR/beancount_functions.sh"
GIT_FILE="$SCRIPT_DIR/beancount_git.sh"
NOTIFY_FILE="$SCRIPT_DIR/beancount_notify.sh"
ENV_FILE="$SCRIPT_DIR/beancount_env.sh"

# 导出项目目录供子模块使用
export PROJECT_DIR

# 临时定义基础打印函数（在加载模块前使用）
temp_print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
temp_print_success() { echo -e "${GREEN}✅ $1${NC}"; }
temp_print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
temp_print_error() { echo -e "${RED}❌ $1${NC}"; }
temp_print_menu() { echo -e "${CYAN}📋 $1${NC}"; }

# 加载功能模块
load_modules() {
    temp_print_info "加载功能模块..."
    
    local modules=("$FUNCTIONS_FILE" "$GIT_FILE" "$NOTIFY_FILE" "$ENV_FILE")
    local loaded_count=0
    
    for module in "${modules[@]}"; do
        if [ -f "$module" ]; then
            source "$module"
            if [ $? -eq 0 ]; then
                temp_print_success "加载模块: $(basename "$module")"
                loaded_count=$((loaded_count + 1))
            else
                temp_print_error "加载模块失败: $(basename "$module")"
            fi
        else
            temp_print_warning "模块不存在: $module"
        fi
    done
    
    if [ $loaded_count -eq ${#modules[@]} ]; then
        temp_print_success "所有模块加载完成"
    else
        temp_print_warning "部分模块加载失败 ($loaded_count/${#modules[@]})"
    fi
}

# 平台检测
detect_platform() {
    temp_print_info "检测运行平台..."
    
    case "$OSTYPE" in
        linux-gnu*)  PLATFORM="linux" ;;
        msys*)       PLATFORM="windows" ;;
        cygwin*)     PLATFORM="windows" ;;
        *)           PLATFORM="unknown" ;;
    esac
    
    temp_print_success "检测到平台: $PLATFORM"
    export PLATFORM
}

# 环境检测
detect_environment() {
    temp_print_info "检测系统环境..."
    
    # 检测Python
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_CMD="python3"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_CMD="python"
    else
        temp_print_error "未找到Python"
        return 1
    fi
    
    # 检测Go
    if command -v go >/dev/null 2>&1; then
        GO_AVAILABLE=true
    else
        GO_AVAILABLE=false
        temp_print_warning "Go未安装，部分功能不可用"
    fi
    
    # 检测虚拟环境 (使用项目目录)
    if [ -d "$PROJECT_DIR/.env_beancount-v3" ]; then
        VENV_AVAILABLE=true
    else
        VENV_AVAILABLE=false
    fi
    
    export PYTHON_CMD GO_AVAILABLE VENV_AVAILABLE
    temp_print_success "环境检测完成"
}

# 主菜单
show_main_menu() {
    clear
    echo "========================================"
    echo "Beancount 跨平台统一管理菜单"
    echo "平台: $PLATFORM | 模式: $MODE"
    echo "========================================"
    print_menu "1. 环境设置和配置"
    print_menu "2. Git 操作"
    print_menu "3. 构建和运行"
    print_menu "4. 规则生成器"
    print_menu "5. 数据同步"
    print_menu "6. 通知管理"
    print_menu "7. 系统状态"
    print_menu "8. 清理和维护"
    print_menu "0. 退出"
    echo "========================================"
}

# 环境设置菜单
show_env_menu() {
    clear
    echo "========================================"
    echo "环境设置和配置"
    echo "========================================"
    print_menu "1. 快速环境设置 (fast)"
    print_menu "2. 完整环境重构 (clean)"
    print_menu "3. 创建虚拟环境"
    print_menu "4. 安装Python依赖"
    print_menu "5. 添加中文账户支持"
    print_menu "6. 构建 beancount-gs"
    print_menu "7. 克隆示例账本"
    print_menu "8. 返回主菜单"
    echo "========================================"
}

# Git操作菜单
# 在 Git 菜单中也添加显示别名的选项
show_git_menu() {
    clear
    echo "========================================"
    echo "Git 操作"
    echo "========================================"
    print_menu "1. 克隆仓库"
    print_menu "2. 快速推送更改"
    print_menu "3. 查看状态"
    print_menu "4. 拉取更新"
    print_menu "5. 自定义提交"
    print_menu "6. 添加到上次提交"
    print_menu "7. 安全强制推送"
    print_menu "8. 强制推送场景助手"
    print_menu "9. Git 配置管理"
    print_menu "10. Git 仓库管理"
    print_menu "11. 分支管理"
    print_menu "12. 显示 Git 别名"
    print_menu "0. 返回主菜单"
    echo "========================================"
}

# 构建运行菜单
show_build_menu() {
    clear
    echo "========================================"
    echo "构建和运行"
    echo "========================================"
    print_menu "1. 构建 beancount-gs"
    print_menu "2. 构建并发送通知"
    print_menu "3. 启动 Web 服务"
    print_menu "4. 启动服务并发送通知"
    print_menu "5. 停止 Web 服务"
    print_menu "6. 停止服务并发送通知"
    print_menu "7. 重启 Web 服务"
    print_menu "8. 查看服务状态"
    print_menu "9. 查看服务日志"
    print_menu "0. 返回主菜单"
    echo "========================================"
}

# 规则生成器菜单
show_rule_menu() {
    clear
    echo "========================================"
    echo "规则生成器"
    echo "========================================"
    print_menu "1. 完整流程运行"
    print_menu "2. 分步运行"
    print_menu "3. 仅初始化数据库"
    print_menu "4. 仅加载提取数据"
    print_menu "5. 仅分析规则"
    print_menu "6. 仅生成规则文件"
    print_menu "7. 返回主菜单"
    echo "========================================"
}

# 通知管理菜单
show_notify_menu() {
    clear
    echo "========================================"
    echo "通知管理"
    echo "========================================"
    print_menu "1. 快速发送通知"
    print_menu "2. 钉钉配置管理"
    print_menu "3. 发送构建开始通知"
    print_menu "4. 发送构建成功通知"
    print_menu "5. 发送构建失败通知"
    print_menu "6. 发送服务启动通知"
    print_menu "7. 发送服务停止通知"
    print_menu "8. 发送错误告警"
    print_menu "9. 测试钉钉配置"
    print_menu "10. 查看通知配置"
    print_menu "0. 返回主菜单"
    echo "========================================"
}

# 系统状态菜单
show_status_menu() {
    clear
    echo "========================================"
    echo "系统状态"
    echo "========================================"
    print_menu "1. 环境诊断"
    print_menu "2. 服务状态检查"
    print_menu "3. 磁盘空间检查"
    print_menu "4. 依赖检查"
    print_menu "5. 返回主菜单"
    echo "========================================"
}

# 清理维护菜单
show_maintenance_menu() {
    clear
    echo "========================================"
    echo "清理和维护"
    echo "========================================"
    print_menu "1. 环境备份"
    print_menu "2. 环境恢复"
    print_menu "3. 环境清理"
    print_menu "4. 环境修复工具"
    print_menu "5. 环境设置管理"
    print_menu "6. 返回主菜单"
    echo "========================================"
}

# 处理菜单选择
handle_menu_selection() {
    local choice="$1"
    
    case "$choice" in
        1) # 环境设置
            while true; do
                show_env_menu
                read -p "请选择 [1-8]: " env_choice
                case "$env_choice" in
                    1) setup_environment_fast ;;
                    2) setup_environment_clean ;;
                    3) create_virtualenv ;;
                    4) install_dependencies ;;
                    5) patch_chinese_support ;;
                    6) build_beancount_gs ;;
                    7) clone_example_beanbook ;;
                    8) break ;;
                    *) print_error "无效选择" ;;
                esac
                read -p "按回车继续..."
            done
            ;;
            
        2) # Git操作
            while true; do
                show_git_menu
                read -p "请选择 [0-11]: " git_choice
                case "$git_choice" in
                    1) git_clone_repo ;;
                    2) git_quick_push ;;
                    3) git_status ;;
                    4) git_pull ;;
                    5) git_custom_commit ;;
                    6) git_add_to_last_commit ;;
                    7) git_safe_force_push ;;
                    8) git_force_push_helper ;;
                    9) manage_git_config ;;
                    10) manage_git_repositories ;;
                    11) git_branch_management ;;
                    12) show_git_aliases ;;
                    0) break ;;
                    *) print_error "无效选择" ;;
                esac
                read -p "按回车继续..."
            done
            ;;
            
        3) # 构建运行
            while true; do
                show_build_menu
                read -p "请选择 [0-9]: " build_choice
                case "$build_choice" in
                    1) build_beancount_gs ;;
                    2) build_with_notification ;;
                    3) start_beancount_gs ;;
                    4) start_service_with_notification ;;
                    5) stop_beancount_gs ;;
                    6) stop_service_with_notification ;;
                    7) 
                        stop_beancount_gs
                        sleep 2
                        start_beancount_gs 
                        ;;
                    8) show_beancount_gs_status ;;
                    9) show_beancount_gs_logs ;;
                    0) break ;;
                    *) print_error "无效选择" ;;
                esac
                read -p "按回车继续..."
            done
            ;;
            
        4) # 规则生成器
            while true; do
                show_rule_menu
                read -p "请选择 [1-7]: " rule_choice
                case "$rule_choice" in
                    1) run_rule_generator_full ;;
                    2) run_rule_generator_steps ;;
                    3) run_rule_init ;;
                    4) run_rule_load ;;
                    5) run_rule_analyze ;;
                    6) run_rule_generate ;;
                    7) break ;;
                    *) print_error "无效选择" ;;
                esac
                read -p "按回车继续..."
            done
            ;;
            
        5) # 数据同步
            handle_data_sync
            ;;
            
        6) # 通知管理
            while true; do
                show_notify_menu
                read -p "请选择 [0-10]: " notify_choice
                case "$notify_choice" in
                    1) quick_notification ;;
                    2) manage_dingtalk_config ;;
                    3) 
                        read -p "请输入附加信息 (可选): " additional_info
                        send_build_notification "build_start" "success" "$additional_info"
                        ;;
                    4)
                        read -p "请输入附加信息 (可选): " additional_info
                        send_build_notification "build_complete" "success" "$additional_info"
                        ;;
                    5)
                        read -p "请输入错误信息: " additional_info
                        send_build_notification "build_complete" "failed" "$additional_info"
                        ;;
                    6)
                        read -p "请输入服务信息 (可选): " additional_info
                        send_build_notification "service_start" "success" "$additional_info"
                        ;;
                    7)
                        read -p "请输入停止原因 (可选): " additional_info
                        send_build_notification "service_stop" "success" "$additional_info"
                        ;;
                    8)
                        read -p "请输入错误详情: " additional_info
                        send_build_notification "error_alert" "error" "$additional_info"
                        ;;
                    9) test_dingtalk_config ;;
                    10) show_notification_settings ;;
                    0) break ;;
                    *) print_error "无效选择" ;;
                esac
                read -p "按回车继续..."
            done
            ;;
            
        7) # 系统状态
            while true; do
                show_status_menu
                read -p "请选择 [1-5]: " status_choice
                case "$status_choice" in
                    1) environment_diagnosis ;;
                    2) show_beancount_gs_status ;;
                    3) check_disk_space ;;
                    4) check_dependencies ;;
                    5) break ;;
                    *) print_error "无效选择" ;;
                esac
                read -p "按回车继续..."
            done
            ;;
            
        8) # 清理维护
            while true; do
                show_maintenance_menu
                read -p "请选择 [1-6]: " maintenance_choice
                case "$maintenance_choice" in
                    1) environment_backup ;;
                    2) environment_restore ;;
                    3) environment_cleanup ;;
                    4) environment_repair_tool ;;
                    5) manage_environment_settings ;;
                    6) break ;;
                    *) print_error "无效选择" ;;
                esac
                read -p "按回车继续..."
            done
            ;;
            
        0) # 退出
            print_success "感谢使用 Beancount 管理菜单!"
            exit 0
            ;;
            
        *)
            print_error "无效选择"
            ;;
    esac
}

# 显示帮助
show_help() {
    echo "========================================"
    echo "Beancount 跨平台统一管理菜单 - 帮助"
    echo "========================================"
    echo "用法: $0 [模式]"
    echo ""
    echo "模式选项:"
    echo "  fast   快速模式 - 使用现有环境 (默认)"
    echo "  clean  完整重构 - 清理并重建环境"
    echo "  help   显示此帮助信息"
    echo ""
    echo "功能模块:"
    echo "  1. 环境设置 - 虚拟环境, 依赖安装"
    echo "  2. Git操作 - 克隆, 推送, 状态"
    echo "  3. 构建运行 - 编译, 启动服务"
    echo "  4. 规则生成 - 自动规则生成器"
    echo "  5. 数据同步 - 账本数据同步"
    echo "  6. 通知管理 - 钉钉通知"
    echo "  7. 系统状态 - 环境检查"
    echo "  8. 清理维护 - 缓存清理"
    echo ""
    echo "示例:"
    echo "  $0          # 快速启动"
    echo "  $0 clean    # 完整重构"
    echo "  $0 help     # 显示帮助"
    echo "========================================"
}

# 主函数
main() {
    # 清屏
    clear
    
    # 显示欢迎信息
    echo "========================================"
    echo "Beancount 跨平台统一管理菜单"
    echo "版本: 1.0 | 作者: liangzai450"
    echo "========================================"
    
    # 初始化
    detect_platform
    detect_environment
    load_modules
    
    # 处理命令行参数
    case "$MODE" in
        "help"|"-h"|"--help")
            show_help
            exit 0
            ;;
        "clean")
            print_warning "完整重构模式"
            setup_environment_clean
            ;;
        "fast")
            print_info "快速模式"
            setup_environment_fast
            ;;
        *)
            print_error "未知模式: $MODE"
            show_help
            exit 1
            ;;
    esac
    
    # 主菜单循环
    while true; do
        show_main_menu
        read -p "请选择 [0-8]: " main_choice
        handle_menu_selection "$main_choice"
    done
}

# 执行主函数
main "$@"

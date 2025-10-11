#!/bin/bash

# 环境配置函数库 - Beancount 跨平台管理

# 环境配置
ENV_CONFIG_FILE="$SCRIPT_DIR/.env_config"
PLATFORM_CONFIG_FILE="$SCRIPT_DIR/.platform_config"

# 初始化环境配置
init_env_config() {
    print_info "初始化环境配置..."
    
    # 创建配置目录 (使用SCRIPT_DIR)
    mkdir -p "$(dirname "$ENV_CONFIG_FILE")"
    mkdir -p "$(dirname "$PLATFORM_CONFIG_FILE")"
    # 确保使用正确的路径分隔符
    ENV_CONFIG_FILE="${ENV_CONFIG_FILE//\\//}"
    PLATFORM_CONFIG_FILE="${PLATFORM_CONFIG_FILE//\\//}"
    
    # 设置默认环境配置
    if [ ! -f "$ENV_CONFIG_FILE" ]; then
        cat > "$ENV_CONFIG_FILE" << EOF
# Beancount 环境配置
BEANCOUNT_VERSION="3.2.0"
FAVA_VERSION="1.30.6"
PYTHON_VERSION="3.12"
VENV_NAME=".env_beancount-v3"
AUTO_ACTIVATE_VENV=true
BACKUP_BEFORE_CLEAN=true
LOG_LEVEL="INFO"
EOF
        print_success "创建默认环境配置"
    fi
    
    # 设置平台特定配置
    if [ ! -f "$PLATFORM_CONFIG_FILE" ]; then
        detect_platform_specifics
    fi
    
    # 加载配置
    source "$ENV_CONFIG_FILE"
    if [ -f "$PLATFORM_CONFIG_FILE" ]; then
        source "$PLATFORM_CONFIG_FILE"
    fi
    
    print_success "环境配置加载完成"
}

# 检测平台特定配置
detect_platform_specifics() {
    print_info "检测平台特定配置..."
    
    case "$PLATFORM" in
        "linux")
            cat > "$PLATFORM_CONFIG_FILE" << EOF
# Linux 平台配置
PYTHON_CMD="python3"
VENV_ACTIVATE_SCRIPT="bin/activate"
BEANCOUNT_GS_BINARY="beancount-gs"
DEV_ROOT="/workspace"
EOF
            ;;
        "windows")
            cat > "$PLATFORM_CONFIG_FILE" << EOF
# Windows 平台配置
PYTHON_CMD="python"
VENV_ACTIVATE_SCRIPT="Scripts/activate"
BEANCOUNT_GS_BINARY="beancount-gs.exe"
DEV_ROOT="/h/dev"
WIN_PYTHON_PATH="H:/dev/dev_envs/winpython-3.12.10-dot/WPy64-312101/python/python.exe"
WIN_GO_PATH="H:/dev/dev_envs/go-1.24/go/bin/go.exe"
EOF
            ;;
        *)
            print_warning "未知平台，使用默认配置"
            cat > "$PLATFORM_CONFIG_FILE" << EOF
# 通用平台配置
PYTHON_CMD="python3"
VENV_ACTIVATE_SCRIPT="bin/activate"
BEANCOUNT_GS_BINARY="beancount-gs"
DEV_ROOT="."
EOF
            ;;
    esac
    
    print_success "平台配置检测完成"
}

# 环境诊断
environment_diagnosis() {
    print_info "开始环境诊断..."
    
    local issues=()
    local warnings=()
    
    echo ""
    print_menu "=== 系统环境检查 ==="
    
    # 检查 Python
    if command -v $PYTHON_CMD >/dev/null 2>&1; then
        local python_version=$($PYTHON_CMD --version 2>&1)
        print_success "Python: $python_version"
        
        # 检查 Python 版本
        if ! $PYTHON_CMD -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
            warnings+=("Python 版本可能过低，建议使用 3.8+")
        fi
    else
        issues+=("Python 未安装或不在 PATH 中")
    fi
    
    # 检查 pip
    if command -v pip >/dev/null 2>&1; then
        local pip_version=$(pip --version 2>/dev/null | head -n1)
        print_success "pip: $pip_version"
    else
        issues+=("pip 未安装或不在 PATH 中")
    fi
    
    # 检查 Go
    if command -v go >/dev/null 2>&1; then
        local go_version=$(go version 2>&1)
        print_success "Go: $go_version"
    else
        warnings+=("Go 未安装，beancount-gs 构建功能不可用")
    fi
    
    # 检查 Git
    if command -v git >/dev/null 2>&1; then
        local git_version=$(git --version 2>&1)
        print_success "Git: $git_version"
    else
        issues+=("Git 未安装")
    fi
    
    echo ""
    print_menu "=== 项目环境检查 ==="
    
    # 检查虚拟环境
    if [ -d "$VENV_DIR" ]; then
        print_success "虚拟环境: 存在 ($VENV_DIR)"
        
        # 检查虚拟环境状态
        if [ -n "$VIRTUAL_ENV" ]; then
            print_success "虚拟环境状态: 已激活"
        else
            warnings+=("虚拟环境存在但未激活")
        fi
        
        # 检查虚拟环境中的 Python
        local venv_python="$VENV_DIR/$VENV_ACTIVATE_SCRIPT/../python"
        if [ -f "$venv_python" ] || [ -f "${venv_python}.exe" ]; then
            print_success "虚拟环境 Python: 正常"
        else
            issues+=("虚拟环境中的 Python 不可用")
        fi
    else
        warnings+=("虚拟环境不存在")
    fi
    
    # 检查 beancount-gs
    if [ -f "$BEANCOUNT_GS" ]; then
        print_success "beancount-gs: 存在"
        if [ -x "$BEANCOUNT_GS" ]; then
            print_success "beancount-gs: 可执行"
        else
            warnings+=("beancount-gs 不可执行")
        fi
    else
        warnings+=("beancount-gs 不存在")
    fi
    
    # 检查账本仓库
    if [ -d "$BEANCOUNT_REPO" ]; then
        print_success "账本仓库: 存在"
        if [ -d "$BEANCOUNT_REPO/.git" ]; then
            print_success "Git 仓库: 正常"
        else
            warnings+=("账本目录不是 Git 仓库")
        fi
    else
        warnings+=("账本仓库不存在")
    fi
    
    # 检查依赖文件
    if [ -f "$REQUIREMENTS_FILE" ]; then
        print_success "依赖文件: 存在"
    else
        warnings+=("依赖文件不存在")
    fi
    
    echo ""
    print_menu "=== 路径检查 ==="
    
    # 检查关键路径
    local critical_paths=("$PROJECT_DIR" "$VENV_DIR" "$(dirname "$BEANCOUNT_GS")" "$(dirname "$BEANCOUNT_REPO")")
    
    for path in "${critical_paths[@]}"; do
        if [ -d "$path" ]; then
            print_success "路径可访问: $path"
        else
            warnings+=("路径不可访问: $path")
        fi
    done
    
    # 检查磁盘空间
    check_disk_space
    
    echo ""
    print_menu "=== 诊断结果 ==="
    
    if [ ${#issues[@]} -eq 0 ]; then
        print_success "✅ 未发现严重问题"
    else
        print_error "❌ 发现 ${#issues[@]} 个问题:"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
    fi
    
    if [ ${#warnings[@]} -gt 0 ]; then
        print_warning "⚠️  发现 ${#warnings[@]} 个警告:"
        for warning in "${warnings[@]}"; do
            echo "  - $warning"
        done
    fi
    
    # 生成修复建议
    if [ ${#issues[@]} -gt 0 ] || [ ${#warnings[@]} -gt 0 ]; then
        echo ""
        print_menu "修复建议:"
        generate_fix_suggestions "${issues[@]}" "${warnings[@]}"
    fi
}

# 检查磁盘空间
check_disk_space() {
    local project_dir_disk=$(df "$PROJECT_DIR" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ -n "$project_dir_disk" ]; then
        if [ "$project_dir_disk" -lt 80 ]; then
            print_success "磁盘空间: ${project_dir_disk}% 使用 (正常)"
        elif [ "$project_dir_disk" -lt 95 ]; then
            print_warning "磁盘空间: ${project_dir_disk}% 使用 (警告)"
        else
            print_error "磁盘空间: ${project_dir_disk}% 使用 (危险)"
        fi
    else
        print_warning "无法检测磁盘空间"
    fi
}

# 生成修复建议
generate_fix_suggestions() {
    local issues=("$@")
    
    for issue in "${issues[@]}"; do
        case "$issue" in
            *"Python 未安装"*)
                echo "  - 安装 Python 3.8 或更高版本"
                ;;
            *"pip 未安装"*)
                echo "  - 运行: curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python get-pip.py"
                ;;
            *"Git 未安装"*)
                echo "  - 安装 Git: https://git-scm.com/downloads"
                ;;
            *"虚拟环境不存在"*)
                echo "  - 运行菜单中的 '创建虚拟环境' 功能"
                ;;
            *"beancount-gs 不存在"*)
                echo "  - 运行菜单中的 '构建 beancount-gs' 功能"
                ;;
            *"账本仓库不存在"*)
                echo "  - 运行菜单中的 '克隆示例账本' 功能"
                ;;
            *"依赖文件不存在"*)
                echo "  - 运行菜单中的 '安装 Python 依赖' 功能"
                ;;
            *"Python 版本可能过低"*)
                echo "  - 升级到 Python 3.8 或更高版本"
                ;;
            *"虚拟环境存在但未激活"*)
                echo "  - 运行: source $VENV_DIR/$VENV_ACTIVATE_SCRIPT"
                ;;
            *"beancount-gs 不可执行"*)
                echo "  - 运行: chmod +x $BEANCOUNT_GS"
                ;;
            *"账本目录不是 Git 仓库"*)
                echo "  - 删除并重新克隆账本仓库"
                ;;
            *"路径不可访问"*)
                echo "  - 检查路径权限或重新创建目录"
                ;;
            *)
                echo "  - 检查相关配置和依赖"
                ;;
        esac
    done
}

# 环境修复工具
environment_repair_tool() {
    print_info "环境修复工具"
    
    while true; do
        echo ""
        print_menu "修复选项:"
        echo "1. 修复虚拟环境"
        echo "2. 重新安装依赖"
        echo "3. 修复 beancount-gs"
        echo "4. 修复账本仓库"
        echo "5. 修复路径权限"
        echo "6. 运行完整诊断"
        echo "7. 返回"
        
        read -p "请选择 [1-7]: " repair_choice
        
        case "$repair_choice" in
            1)
                repair_virtualenv
                ;;
            2)
                repair_dependencies
                ;;
            3)
                repair_beancount_gs
                ;;
            4)
                repair_beanbook_repo
                ;;
            5)
                repair_path_permissions
                ;;
            6)
                environment_diagnosis
                ;;
            7)
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
        
        read -p "按回车继续..."
    done
}

# 修复虚拟环境
repair_virtualenv() {
    print_info "修复虚拟环境..."
    
    if [ -d "$VENV_DIR" ]; then
        print_warning "虚拟环境已存在，正在备份..."
        local backup_dir="${VENV_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        cp -r "$VENV_DIR" "$backup_dir"
        print_success "虚拟环境已备份到: $backup_dir"
        
        print_info "删除现有虚拟环境..."
        rm -rf "$VENV_DIR"
    fi
    
    create_virtualenv
    if [ $? -eq 0 ]; then
        activate_venv
        install_dependencies
    fi
}

# 修复依赖
repair_dependencies() {
    print_info "修复 Python 依赖..."
    
    if [ ! -d "$VENV_DIR" ]; then
        print_error "虚拟环境不存在，请先创建"
        return 1
    fi
    
    activate_venv
    
    # 卸载所有包然后重新安装
    print_info "清理现有依赖..."
    pip freeze | xargs pip uninstall -y
    
    print_info "重新安装依赖..."
    install_dependencies
}

# 修复 beancount-gs
repair_beancount_gs() {
    print_info "修复 beancount-gs..."
    
    if [ -f "$BEANCOUNT_GS" ]; then
        print_warning "删除现有 beancount-gs..."
        rm -f "$BEANCOUNT_GS"
    fi
    
    build_beancount_gs
}

# 修复账本仓库
repair_beanbook_repo() {
    print_info "修复账本仓库..."
    
    if [ -d "$BEANCOUNT_REPO" ]; then
        print_warning "删除现有账本仓库..."
        rm -rf "$BEANCOUNT_REPO"
    fi
    
    clone_example_beanbook
}

# 修复路径权限
repair_path_permissions() {
    print_info "修复路径权限..."
    
    local paths_to_fix=("$PROJECT_DIR" "$VENV_DIR" "$(dirname "$BEANCOUNT_REPO")")
    
    for path in "${paths_to_fix[@]}"; do
        if [ -d "$path" ]; then
            print_info "修复权限: $path"
            chmod -R 755 "$path" 2>/dev/null && print_success "权限修复成功" || print_warning "权限修复失败"
        fi
    done
    
    # 修复 beancount-gs 执行权限
    if [ -f "$BEANCOUNT_GS" ]; then
        chmod +x "$BEANCOUNT_GS" && print_success "beancount-gs 执行权限修复成功"
    fi
}

# 环境备份
environment_backup() {
    print_info "环境备份工具"
    
    # 使用PROJECT_DIR作为基础路径
    local backup_dir="$PROJECT_DIR/backups/env_backup_$(date +%Y%m%d_%H%M%S)"
    # 标准化路径
    backup_dir="${backup_dir//\\//}"
    local backup_files=()
    
    mkdir -p "$backup_dir"
    
    echo ""
    print_menu "选择要备份的内容:"
    echo "1. 虚拟环境"
    echo "2. 依赖文件"
    echo "3. 配置文件"
    echo "4. 账本数据"
    echo "5. 全部内容"
    echo "6. 返回"
    
    read -p "请选择 [1-6]: " backup_choice
    
    case "$backup_choice" in
        1)
            backup_files+=("$VENV_DIR")
            print_info "备份虚拟环境..."
            ;;
        2)
            backup_files+=("$REQUIREMENTS_FILE")
            print_info "备份依赖文件..."
            ;;
        3)
            backup_files+=("$ENV_CONFIG_FILE" "$PLATFORM_CONFIG_FILE" "$SCRIPT_DIR/.notify_config" "$SCRIPT_DIR/.dingtalk_config")
            print_info "备份配置文件..."
            ;;
        4)
            backup_files+=("$BEANCOUNT_REPO")
            print_info "备份账本数据..."
            ;;
        5)
            backup_files+=("$VENV_DIR" "$REQUIREMENTS_FILE" "$ENV_CONFIG_FILE" "$PLATFORM_CONFIG_FILE" "$SCRIPT_DIR/.notify_config" "$SCRIPT_DIR/.dingtalk_config" "$BEANCOUNT_REPO")
            print_info "备份全部内容..."
            ;;
        6)
            return
            ;;
        *)
            print_error "无效选择"
            return 1
            ;;
    esac
    
    local total_size=0
    local backed_up_files=()
    
    for item in "${backup_files[@]}"; do
        if [ -e "$item" ]; then
            print_info "备份: $item"
            cp -r "$item" "$backup_dir/" 2>/dev/null
            if [ $? -eq 0 ]; then
                backed_up_files+=("$item")
                local size=$(du -sk "$item" 2>/dev/null | cut -f1 || echo 0)
                total_size=$((total_size + size))
                print_success "备份成功"
            else
                print_error "备份失败: $item"
            fi
        else
            print_warning "跳过不存在的项目: $item"
        fi
    done
    
    # 创建备份信息文件
    cat > "$backup_dir/backup_info.txt" << EOF
Beancount 环境备份信息
备份时间: $(date)
备份目录: $backup_dir
备份项目: ${#backed_up_files[@]}
总大小: ${total_size}KB

备份内容:
$(for file in "${backed_up_files[@]}"; do echo "  - $file"; done)

恢复说明:
1. 将备份文件复制到对应位置
2. 运行环境修复工具进行验证
EOF
    
    print_success "备份完成!"
    echo "备份位置: $backup_dir"
    echo "备份大小: ${total_size}KB"
    echo "备份项目: ${#backed_up_files[@]}"
}

# 环境恢复
environment_restore() {
    print_info "环境恢复工具"
    
    local backup_base="$PROJECT_DIR/backups"
    
    if [ ! -d "$backup_base" ]; then
        print_error "备份目录不存在: $backup_base"
        return 1
    fi
    
    # 查找备份
    local backups=($(find "$backup_base" -name "env_backup_*" -type d | sort -r))
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_error "未找到任何备份"
        return 1
    fi
    
    echo ""
    print_menu "可用的备份:"
    for i in "${!backups[@]}"; do
        local backup_name=$(basename "${backups[$i]}")
        local backup_time=$(echo "$backup_name" | sed 's/env_backup_//')
        local backup_size=$(du -sh "${backups[$i]}" 2>/dev/null | cut -f1)
        echo "  $((i+1)). $backup_time ($backup_size)"
    done
    
    read -p "选择要恢复的备份 [1-${#backups[@]}]: " restore_choice
    
    local selected_index=$((restore_choice-1))
    
    if [ $selected_index -lt 0 ] || [ $selected_index -ge ${#backups[@]} ]; then
        print_error "无效选择"
        return 1
    fi
    
    local selected_backup="${backups[$selected_index]}"
    
    echo ""
    print_warning "即将从备份恢复: $(basename "$selected_backup")"
    print_warning "这将覆盖现有文件!"
    
    read -p "确认恢复? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "恢复取消"
        return 0
    fi
    
    # 执行恢复
    print_info "开始恢复..."
    
    # 恢复虚拟环境
    if [ -d "$selected_backup/$VENV_NAME" ]; then
        print_info "恢复虚拟环境..."
        rm -rf "$VENV_DIR" 2>/dev/null
        cp -r "$selected_backup/$VENV_NAME" "$VENV_DIR"
    fi
    
    # 恢复依赖文件
    if [ -f "$selected_backup/$(basename "$REQUIREMENTS_FILE")" ]; then
        print_info "恢复依赖文件..."
        cp "$selected_backup/$(basename "$REQUIREMENTS_FILE")" "$REQUIREMENTS_FILE"
    fi
    
    # 恢复配置文件
    for config_file in "$ENV_CONFIG_FILE" "$PLATFORM_CONFIG_FILE" "$SCRIPT_DIR/.notify_config" "$SCRIPT_DIR/.dingtalk_config"; do
        local config_name=$(basename "$config_file")
        if [ -f "$selected_backup/$config_name" ]; then
            print_info "恢复配置文件: $config_name"
            cp "$selected_backup/$config_name" "$config_file"
        fi
    done
    
    # 恢复账本数据
    if [ -d "$selected_backup/$(basename "$BEANCOUNT_REPO")" ]; then
        print_info "恢复账本数据..."
        rm -rf "$BEANCOUNT_REPO" 2>/dev/null
        cp -r "$selected_backup/$(basename "$BEANCOUNT_REPO")" "$BEANCOUNT_REPO"
    fi
    
    print_success "恢复完成!"
    print_info "建议运行环境诊断验证恢复结果"
}

# 环境清理
environment_cleanup() {
    print_info "环境清理工具"
    
    echo ""
    print_warning "警告: 此操作将删除指定内容，请谨慎操作!"
    
    while true; do
        echo ""
        print_menu "清理选项:"
        echo "1. 清理 Python 缓存"
        echo "2. 清理 pip 缓存"
        echo "3. 清理 Go 缓存"
        echo "4. 清理日志文件"
        echo "5. 清理临时文件"
        echo "6. 深度清理 (所有缓存)"
        echo "7. 返回"
        
        read -p "请选择 [1-7]: " cleanup_choice
        
        case "$cleanup_choice" in
            1)
                cleanup_python_cache
                ;;
            2)
                cleanup_pip_cache
                ;;
            3)
                cleanup_go_cache
                ;;
            4)
                cleanup_logs
                ;;
            5)
                cleanup_temp_files
                ;;
            6)
                deep_cleanup
                ;;
            7)
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
        
        read -p "按回车继续..."
    done
}

# 清理 Python 缓存
cleanup_python_cache() {
    print_info "清理 Python 缓存..."
    
    local cache_dirs=("__pycache__" "*.pyc" "*.pyo" "*.pyd" ".pytype" ".mypy_cache" ".pytest_cache")
    local total_cleaned=0
    
    for cache_pattern in "${cache_dirs[@]}"; do
        local found_items=$(find "$PROJECT_DIR" -name "$cache_pattern" -type f -o -name "$cache_pattern" -type d 2>/dev/null | wc -l)
        if [ "$found_items" -gt 0 ]; then
            print_info "清理 $cache_pattern: $found_items 个项目"
            find "$PROJECT_DIR" -name "$cache_pattern" -type f -delete -o -name "$cache_pattern" -type d -exec rm -rf {} + 2>/dev/null
            total_cleaned=$((total_cleaned + found_items))
        fi
    done
    
    print_success "Python 缓存清理完成: $total_cleaned 个项目"
}

# 清理 Go 缓存
cleanup_go_cache() {
    print_info "清理 Go 缓存..."
    
    if command -v go >/dev/null 2>&1; then
        local go_cache=$(go env GOCACHE 2>/dev/null)
        if [ -n "$go_cache" ] && [ -d "$go_cache" ]; then
            local cache_size=$(du -sh "$go_cache" 2>/dev/null | cut -f1)
            go clean -cache -modcache -testcache
            print_success "Go 缓存清理完成 (原大小: $cache_size)"
        else
            print_warning "Go 缓存目录未找到"
        fi
    else
        print_warning "Go 未安装"
    fi
}

# 清理日志文件
cleanup_logs() {
    print_info "清理日志文件..."
    
    local log_files=("*.log" "*.log.*" "logs/" "*.out" "*.err")
    local total_cleaned=0
    
    for log_pattern in "${log_files[@]}"; do
        local found_items=$(find "$PROJECT_DIR" -name "$log_pattern" -type f 2>/dev/null | wc -l)
        if [ "$found_items" -gt 0 ]; then
            print_info "清理 $log_pattern: $found_items 个文件"
            find "$PROJECT_DIR" -name "$log_pattern" -type f -delete 2>/dev/null
            total_cleaned=$((total_cleaned + found_items))
        fi
    done
    
    print_success "日志文件清理完成: $total_cleaned 个文件"
}

# 清理临时文件
cleanup_temp_files() {
    print_info "清理临时文件..."
    
    local temp_patterns=("*.tmp" "*.temp" "*.swp" "*.swo" "*.swn" ".DS_Store" "Thumbs.db")
    local total_cleaned=0
    
    for temp_pattern in "${temp_patterns[@]}"; do
        local found_items=$(find "$PROJECT_DIR" -name "$temp_pattern" -type f 2>/dev/null | wc -l)
        if [ "$found_items" -gt 0 ]; then
            print_info "清理 $temp_pattern: $found_items 个文件"
            find "$PROJECT_DIR" -name "$temp_pattern" -type f -delete 2>/dev/null
            total_cleaned=$((total_cleaned + found_items))
        fi
    done
    
    print_success "临时文件清理完成: $total_cleaned 个文件"
}

# 深度清理
deep_cleanup() {
    print_info "执行深度清理..."
    
    cleanup_python_cache
    cleanup_pip_cache
    cleanup_go_cache
    cleanup_logs
    cleanup_temp_files
    
    # 清理备份文件（保留最近3个）
    local backup_dir="$PROJECT_DIR/backups"
    if [ -d "$backup_dir" ]; then
        print_info "清理旧备份文件..."
        local backups=($(find "$backup_dir" -name "env_backup_*" -type d | sort -r))
        if [ ${#backups[@]} -gt 3 ]; then
            for ((i=3; i<${#backups[@]}; i++)); do
                print_info "删除旧备份: $(basename "${backups[$i]}")"
                rm -rf "${backups[$i]}"
            done
        fi
    fi
    
    print_success "深度清理完成!"
}

# 环境设置管理
manage_environment_settings() {
    print_info "环境设置管理"
    
    while true; do
        echo ""
        print_menu "当前设置:"
        echo "  Beancount 版本: $BEANCOUNT_VERSION"
        echo "  Fava 版本: $FAVA_VERSION"
        echo "  Python 版本: $PYTHON_VERSION"
        echo "  虚拟环境名称: $VENV_NAME"
        echo "  自动激活虚拟环境: $AUTO_ACTIVATE_VENV"
        echo "  清理前备份: $BACKUP_BEFORE_CLEAN"
        echo ""
        
        echo "1. 修改 Beancount 版本"
        echo "2. 修改 Fava 版本"
        echo "3. 修改虚拟环境名称"
        echo "4. 切换自动激活设置"
        echo "5. 切换备份设置"
        echo "6. 查看完整配置"
        echo "7. 重置配置"
        echo "8. 返回"
        
        read -p "请选择 [1-8]: " setting_choice
        
        case "$setting_choice" in
            1)
                read -p "请输入 Beancount 版本 [当前: $BEANCOUNT_VERSION]: " new_version
                if [ -n "$new_version" ]; then
                    BEANCOUNT_VERSION="$new_version"
                    save_env_config
                fi
                ;;
            2)
                read -p "请输入 Fava 版本 [当前: $FAVA_VERSION]: " new_version
                if [ -n "$new_version" ]; then
                    FAVA_VERSION="$new_version"
                    save_env_config
                fi
                ;;
            3)
                read -p "请输入虚拟环境名称 [当前: $VENV_NAME]: " new_name
                if [ -n "$new_name" ]; then
                    VENV_NAME="$new_name"
                    # 使用PROJECT_DIR作为基础路径
    VENV_DIR="$PROJECT_DIR/$VENV_NAME"
    # 标准化路径
    VENV_DIR="${VENV_DIR//\\//}"
                    save_env_config
                fi
                ;;
            4)
                if [ "$AUTO_ACTIVATE_VENV" = "true" ]; then
                    AUTO_ACTIVATE_VENV="false"
                    print_warning "自动激活虚拟环境已禁用"
                else
                    AUTO_ACTIVATE_VENV="true"
                    print_success "自动激活虚拟环境已启用"
                fi
                save_env_config
                ;;
            5)
                if [ "$BACKUP_BEFORE_CLEAN" = "true" ]; then
                    BACKUP_BEFORE_CLEAN="false"
                    print_warning "清理前备份已禁用"
                else
                    BACKUP_BEFORE_CLEAN="true"
                    print_success "清理前备份已启用"
                fi
                save_env_config
                ;;
            6)
                show_env_config
                ;;
            7)
                reset_env_config
                ;;
            8)
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
    done
}

# 保存环境配置
save_env_config() {
    cat > "$ENV_CONFIG_FILE" << EOF
# Beancount 环境配置
BEANCOUNT_VERSION="${BEANCOUNT_VERSION}"
FAVA_VERSION="${FAVA_VERSION}"
PYTHON_VERSION="${PYTHON_VERSION}"
VENV_NAME="${VENV_NAME}"
AUTO_ACTIVATE_VENV="${AUTO_ACTIVATE_VENV}"
BACKUP_BEFORE_CLEAN="${BACKUP_BEFORE_CLEAN}"
LOG_LEVEL="${LOG_LEVEL}"
EOF
    print_success "环境配置已保存"
}

# 显示环境配置
show_env_config() {
    print_info "环境配置:"
    cat "$ENV_CONFIG_FILE"
    echo ""
    if [ -f "$PLATFORM_CONFIG_FILE" ]; then
        print_info "平台配置:"
        cat "$PLATFORM_CONFIG_FILE"
    fi
}

# 重置环境配置
reset_env_config() {
    rm -f "$ENV_CONFIG_FILE"
    rm -f "$PLATFORM_CONFIG_FILE"
    init_env_config
    print_success "环境配置已重置"
}

# 初始化环境模块
initialize_env_module() {
    print_info "初始化环境模块..."
    init_env_config
    print_success "环境模块初始化完成"
}

# 自动初始化
initialize_env_module

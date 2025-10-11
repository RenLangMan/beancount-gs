#!/bin/bash

# 通用功能函数库 - Beancount 跨平台管理

# 打印函数
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_menu() { echo -e "${CYAN}📋 $1${NC}"; }

#!/bin/bash

# 唯一初始化检查 - 使用函数存在性检查
if ! declare -f init_functions > /dev/null; then
    # 初始化函数库
    init_functions() {
        print_info "初始化功能函数库..."
        
        # 自动检测平台
        if [ -n "$CNB_PLATFORM_API" ] || [ -n "$CNB_STACK_ID" ]; then
            PLATFORM="cnb"
        elif [ "$OSTYPE" = "linux-gnu" ]; then
            PLATFORM="linux"
        elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
            PLATFORM="windows"
        else
            PLATFORM="linux" # 默认回退到linux
        fi
        
        export PLATFORM
        print_success "功能函数库初始化完成"
    }

    # 路径配置
    setup_paths() {
        print_info "配置平台路径..."
        case "$PLATFORM" in
            "linux"|"cnb")
                PROJECT_DIR="${CNB_APP_DIR:-/workspace}"
                PYTHON_CMD="python3"
                VENV_DIR="$PROJECT_DIR/.env_beancount-v3"
                BEANCOUNT_GS="$PROJECT_DIR/beancount-gs"
                REQUIREMENTS_FILE="$PROJECT_DIR/requirements-beancount-v3.txt"
                BEANCOUNT_REPO="$PROJECT_DIR/data/beancount/3978d009748ef54ad6ef7bf851bd55491b1fe6bb"
                ;;
            "windows")
                PROJECT_DIR="/h/dev/projects/beancount-gs"
                PYTHON_CMD="python"
                VENV_DIR="$PROJECT_DIR/.env_beancount-v3"
                BEANCOUNT_GS="$PROJECT_DIR/beancount-gs.exe"
                REQUIREMENTS_FILE="$PROJECT_DIR/requirements-beancount-v3.txt"
                BEANCOUNT_REPO="$PROJECT_DIR/data/beancount/3978d009748ef54ad6ef7bf851bd55491b1fe6bb"
                
                # Windows 特定路径
                WIN_PYTHON_PATH="H:/dev/dev_envs/winpython-3.12.10-dot/WPy64-312101/python/python.exe"
                WIN_GO_PATH="H:/dev/dev_envs/go-1.24/go/bin/go.exe"
                ;;
        esac
        
        export PROJECT_DIR VENV_DIR BEANCOUNT_GS REQUIREMENTS_FILE BEANCOUNT_REPO
        print_success "路径配置完成"
    }

    # 主执行逻辑
    if [ "$1" = "--init" ]; then
        init_functions
        setup_paths
    fi
fi

# 路径配置
setup_paths() {
    # 防止重复配置
    if [ -n "$__PATHS_CONFIGURED" ]; then
        return 0
    fi
    
    print_info "配置平台路径..."
    
    case "$PLATFORM" in
        "linux")
            PROJECT_DIR="/workspace"
            PYTHON_CMD="python3"
            VENV_DIR="$PROJECT_DIR/.env_beancount-v3"
            BEANCOUNT_GS="$PROJECT_DIR/beancount-gs"
            REQUIREMENTS_FILE="$PROJECT_DIR/requirements-beancount-v3.txt"
            BEANCOUNT_REPO="/workspace/data/beancount/3978d009748ef54ad6ef7bf851bd55491b1fe6bb"
            ;;
        "windows")
            PROJECT_DIR="/h/dev/projects/beancount-gs"
            PYTHON_CMD="python"
            VENV_DIR="$PROJECT_DIR/.env_beancount-v3"
            BEANCOUNT_GS="$PROJECT_DIR/beancount-gs.exe"
            REQUIREMENTS_FILE="$PROJECT_DIR/requirements-beancount-v3.txt"
            BEANCOUNT_REPO="$PROJECT_DIR/data/beancount/3978d009748ef54ad6ef7bf851bd55491b1fe6bb"
            
            # Windows 特定路径
            WIN_PYTHON_PATH="H:/dev/dev_envs/winpython-3.12.10-dot/WPy64-312101/python/python.exe"
            WIN_GO_PATH="H:/dev/dev_envs/go-1.24/go/bin/go.exe"
            ;;
        "cnb")
            # CNB云开发环境路径配置
            PROJECT_DIR="${CNB_APP_DIR:-/workspace}"
            PYTHON_CMD="python3"
            VENV_DIR="$PROJECT_DIR/.env_beancount-v3"
            BEANCOUNT_GS="$PROJECT_DIR/beancount-gs"
            REQUIREMENTS_FILE="$PROJECT_DIR/requirements-beancount-v3.txt"
            BEANCOUNT_REPO="$PROJECT_DIR/data/beancount/3978d009748ef54ad6ef7bf851bd55491b1fe6bb"
            ;;
        *)
            print_error "不支持的平台: $PLATFORM"
            return 1
            ;;
    esac
    
    # 导出变量
    export PROJECT_DIR VENV_DIR BEANCOUNT_GS REQUIREMENTS_FILE BEANCOUNT_REPO
    print_success "路径配置完成"
}

# 环境清理函数
clean_environment() {
    print_info "开始清理环境..."
    
    # 1. 检查并删除 beancount-gs
    if [ -f "$BEANCOUNT_GS" ]; then
        print_warning "删除已存在的 beancount-gs 文件..."
        rm -f "$BEANCOUNT_GS"
        print_success "beancount-gs 删除完成"
    fi

    # 2. 删除 Go 缓存
    if command -v go >/dev/null 2>&1; then
        print_info "清理 Go 缓存..."
        go clean -cache
        go clean -modcache
        print_success "Go 缓存清理完成"
    fi

    # 3. 清理 pip 缓存
    clean_pip_cache

    # 4. 删除现有的虚拟环境
    if [ -d "$VENV_DIR" ]; then
        print_warning "删除虚拟环境..."
        rm -rf "$VENV_DIR"
        print_success "虚拟环境删除完成"
    fi

    # 5. 删除依赖文件
    if [ -f "$REQUIREMENTS_FILE" ]; then
        print_warning "删除依赖文件..."
        rm -f "$REQUIREMENTS_FILE"
        print_success "依赖文件删除完成"
    fi
    
    # 6. 清理 Python 缓存文件
    print_info "清理 Python 缓存..."
    find "$PROJECT_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
    find "$PROJECT_DIR" -name "*.pyc" -delete 2>/dev/null
    find "$PROJECT_DIR" -name "*.pyo" -delete 2>/dev/null
    print_success "Python 缓存清理完成"
    
    print_success "环境清理完成"
}

# 清理 pip 缓存
clean_pip_cache() {
    print_info "清理 pip 缓存..."
    
    if command -v pip >/dev/null 2>&1; then
        if pip cache purge 2>/dev/null; then
            print_success "pip 缓存清理完成"
        else
            print_warning "pip cache purge 失败，尝试手动清理..."
            local cache_dir=$(pip cache dir 2>/dev/null || echo "$HOME/.cache/pip")
            if [ -d "$cache_dir" ]; then
                rm -rf "$cache_dir"
                print_success "手动清理 pip 缓存完成"
            fi
        fi
    else
        print_warning "pip 未安装，跳过缓存清理"
    fi
}

# 快速环境设置
setup_environment_fast() {
    print_info "快速环境设置模式..."
    
    # 检查工作目录
    check_workspace_dir
    
    # 基础检查
    if [ -f "$BEANCOUNT_GS" ]; then
        print_warning "发现已存在的 beancount-gs 文件，快速模式将保留"
    fi
    
    if [ -d "$VENV_DIR" ]; then
        print_info "使用现有虚拟环境: $VENV_DIR"
    else
        print_warning "虚拟环境不存在，将自动创建"
        create_virtualenv || return 1
    fi
    
    # 激活虚拟环境
    activate_venv || return 1
    
    # 检查依赖
    if ! check_dependencies; then
        print_warning "部分依赖缺失，开始安装..."
        install_dependencies || return 1
    fi
    
    print_success "快速环境设置完成"
}

# 完整环境重构
setup_environment_clean() {
    print_info "完整环境重构模式..."
    
    # 检查工作目录
    check_workspace_dir
    
    # 清理环境
    clean_environment
    
    # 创建虚拟环境
    create_virtualenv || return 1
    
    # 激活虚拟环境
    activate_venv || return 1
    
    # 安装依赖
    install_dependencies || return 1
    
    # 添加中文支持
    patch_chinese_support
    
    print_success "完整环境重构完成"
}

# 检查工作目录
check_workspace_dir() {
    local current_dir=$(pwd)
    
    case "$PLATFORM" in
        "linux")
            if [ "$current_dir" != "/workspace" ]; then
                print_warning "当前目录: $current_dir"
                print_info "切换到 /workspace 目录..."
                cd /workspace || {
                    print_error "无法切换到 /workspace 目录"
                    return 1
                }
                print_success "已切换到 /workspace 目录"
            fi
            ;;
        "windows")
            if [ "$current_dir" != "/h/dev/projects/beancount-gs" ]; then 
                print_warning "当前目录: $current_dir"
                print_info "切换到项目目录..."
                cd "/h/dev/projects/beancount-gs" || {
                    print_error "无法切换到项目目录"
                    return 1
                }
                print_success "已切换到项目目录"
            fi
            ;;
    esac
}

# 创建虚拟环境
create_virtualenv() {
    print_info "创建虚拟环境: $VENV_NAME..."
    
    if [ -d "$VENV_DIR" ]; then
        print_info "虚拟环境已存在，跳过创建"
        return 0
    fi
    
    case "$PLATFORM" in
        "linux")
            $PYTHON_CMD -m venv "$VENV_DIR"
            ;;
        "windows")
            if [ -f "$WIN_PYTHON_PATH" ]; then
                "$WIN_PYTHON_PATH" -m venv "$VENV_DIR"
            else
                $PYTHON_CMD -m venv "$VENV_DIR"
            fi
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        print_success "虚拟环境创建成功"
        return 0
    else
        print_error "虚拟环境创建失败"
        return 1
    fi
}

# 激活虚拟环境
activate_venv() {
    print_info "激活虚拟环境..."
    
    local activate_script
    case "$PLATFORM" in
        "linux")
            activate_script="$VENV_DIR/bin/activate"
            ;;
        "windows")
            activate_script="$VENV_DIR/Scripts/activate"
            ;;
    esac
    
    if [ ! -f "$activate_script" ]; then
        print_error "虚拟环境激活脚本不存在: $activate_script"
        return 1
    fi
    
    source "$activate_script"
    
    if [ $? -eq 0 ]; then
        print_success "虚拟环境激活成功"
        $PYTHON_CMD --version
        return 0
    else
        print_error "虚拟环境激活失败"
        return 1
    fi
}

# 检查依赖
check_dependencies() {
    print_info "检查依赖..."
    local missing_deps=()
    local required_deps=("beancount==3.2.0" "fava==1.30.6" "dateparser==1.2.2" "debugpy==1.8.16" "pytest==8.4.2" "pygments==2.19.2" "pyyaml==6.0.3")

    for dep in "${required_deps[@]}"; do
        if ! pip show "${dep%%==*}" | grep -q "Version: ${dep#*=}"; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -eq 0 ]; then
        print_success "所有依赖已安装"
        return 0
    else
        print_warning "缺失依赖: ${missing_deps[*]}"
        return 1
    fi
}

# 安装依赖
install_dependencies() {
    print_info "安装 Python 依赖..."
    
    # 升级 pip
    print_info "升级 pip..."
    pip install --upgrade pip
    
    # 安装固定版本的依赖
    print_info "安装核心依赖..."
    pip install \
        beancount==3.2.0 \
        beanquery==0.2.0 \
        fava==1.30.6 \
        beangulp==0.2.0 \
        dateparser==1.2.2 \
        debugpy==1.8.16 \
        pytest==8.4.2 \
        Pygments==2.19.2 \
        pyzipper==0.3.6 \
        PyYAML==6.0.3
    
    if [ $? -eq 0 ]; then
        print_success "依赖安装成功"
        
        # 生成 requirements 文件
        pip freeze > "$REQUIREMENTS_FILE"
        print_success "依赖已保存到 $REQUIREMENTS_FILE"
        return 0
    else
        print_error "依赖安装失败"
        return 1
    fi
}

# 验证安装
verify_installation() {
    print_info "验证安装..."
    
    local success=true
    
    echo "1. 检查 fava 版本:"
    $PYTHON_CMD -c "import fava; print(f'Fava版本: {fava.__version__}')" 2>/dev/null && 
        print_success "fava 版本检查成功" || 
        { print_error "fava 导入失败"; success=false; }
    
    echo "2. 检查 dateparser 版本:"
    $PYTHON_CMD -c "import dateparser; print(f'Dateparser版本: {dateparser.__version__}')" 2>/dev/null && 
        print_success "dateparser 版本检查成功" || 
        { print_error "dateparser 导入失败"; success=false; }
    
    echo "3. 检查 debugpy 版本:"
    $PYTHON_CMD -c "import debugpy; print(f'Debugpy版本: {debugpy.__version__}')" 2>/dev/null && 
        print_success "debugpy 版本检查成功" || 
        { print_error "debugpy 导入失败"; success=false; }
    
    echo "4. 检查 pytest 版本:"
    $PYTHON_CMD -c "import pytest; print(f'Pytest版本: {pytest.__version__}')" 2>/dev/null && 
        print_success "pytest 版本检查成功" || 
        { print_error "pytest 导入失败"; success=false; }
    
    echo "5. 检查 Pygments 版本:"
    $PYTHON_CMD -c "import pygments; print(f'Pygments版本: {pygments.__version__}')" 2>/dev/null && 
        print_success "Pygments 版本检查成功" || 
        { print_error "Pygments 导入失败"; success=false; }
    
    echo "6. 检查 pyzipper:"
    $PYTHON_CMD -c "import pyzipper; print(f'Pyzipper版本: {pyzipper.__version__}')" 2>/dev/null && 
        print_success "pyzipper 版本检查成功" || 
        $PYTHON_CMD -c "import pyzipper; print('Pyzipper导入成功')" 2>/dev/null && 
        print_success "pyzipper 导入成功" || 
        { print_error "pyzipper 导入失败"; success=false; }
    
    echo "7. 检查 beancount 版本:"
    $PYTHON_CMD -c "import beancount; print(f'Beancount版本: {beancount.__version__}')" 2>/dev/null && 
        print_success "beancount 版本检查成功" || 
        { print_error "beancount 导入失败"; success=false; }
    
    echo "8. 检查 beanquery:"
    $PYTHON_CMD -c "import beanquery; print('Beanquery导入成功')" 2>/dev/null && 
        print_success "beanquery 导入成功" || 
        { print_error "beanquery 导入失败"; success=false; }
    
    if [ "$success" = true ]; then
        print_success "所有依赖安装验证完成"
        return 0
    else
        print_warning "部分依赖验证失败"
        return 1
    fi
}

# 添加中文账户名支持
patch_chinese_support() {
    print_info "为 Beancount 添加中文账户名支持..."
    
    # 查找 account.py 文件
    local account_files
    case "$PLATFORM" in
        "linux")
            account_files="$VENV_DIR/lib/python"*"/site-packages/beancount/core/account.py"
            ;;
        "windows")
            account_files="$VENV_DIR/Lib/site-packages/beancount/core/account.py"
            ;;
    esac
    
    # 使用通配符展开找到确切的文件路径
    local found_files=$(ls $account_files 2>/dev/null)
    
    if [ -z "$found_files" ]; then
        print_error "未找到 beancount 库的 account.py 文件"
        print_warning "跳过中文支持补丁"
        return 1
    fi
    
    print_success "找到 account.py 文件:"
    echo "$found_files"
    
    # 为每个找到的文件创建备份并进行替换
    for file in $found_files; do
        print_info "处理文件: $file"
        
        # 创建备份
        local backup="${file}.bak"
        cp "$file" "$backup"
        print_success "已创建备份: $backup"
        
        # 查找替换范围
        local start_line=$(grep -n "Component separator for account names" "$file" | cut -d: -f1)
        local end_line=$(grep -n "TYPE = \"<AccountDummy>\"" "$file" | cut -d: -f1)
        
        if [ -z "$start_line" ] || [ -z "$end_line" ]; then
            print_error "无法找到替换范围标记"
            print_warning "使用固定行号替换..."
            start_line=28
            end_line=41
        fi
        
        print_success "找到替换范围: 第${start_line}行到第${end_line}行"
        
        # 使用 sed 进行替换
        sed -i.tmp "${start_line},${end_line}c\\
# Component separator for account names.\\
sep = \":\"\\
\\
\\
# Regular expression string that matches valid account name components.\\
# Categories are:\\
#   Lu: Uppercase letters.\\
#   L: All letters.\\
#   Nd: Decimal numbers.\\
ACC_COMP_TYPE_RE = (\\
    r\"[\\\\p{Lu}][\\\\p{L}\\\\p{Nd}\\\\-]*\"  # Root account type (e.g. Assets or Income)\\
)\\
ACC_COMP_NAME_RE = r\"[\\\\p{Han}\\\\p{Lu}][\\\\p{Han}\\\\p{L}\\\\p{Nd}\\\\-]*\"  # Account name components (e.g. Cash or 现金)\\
# ACC_COMP_NAME_RE = r\"[\\\\p{Han}\\\\p{Lu}\\\\p{Nd}][\\\\p{Han}\\\\p{Lu}\\\\p{Nd}\\\\-（）()·—、，,\\\\.]*\" # Account name components (e.g. Cash or 现—金)\\
\\
# Regular expression string that matches a valid account. {5672c7270e1e}\\
ACCOUNT_RE = r\"(?:{})(?:{}{})+\".format(ACC_COMP_TYPE_RE, sep, ACC_COMP_NAME_RE)\\
\\
\\
# A dummy object which stands for the account type. Values in custom directives\\
# use this to disambiguate between string objects and account names.\\
TYPE = \"<AccountDummy>\"\\
" "$file"
        
        if [ $? -eq 0 ]; then
            # 删除临时文件
            rm -f "${file}.tmp"
            print_success "文件已成功更新"
        else
            print_error "更新失败，正在恢复备份"
            cp "$backup" "$file"
            print_warning "中文账户名支持添加失败"
            return 1
        fi
    done
    
    print_success "中文账户名支持已添加"
    print_success "现在可以使用如下中文账户名:"
    echo "  Assets:银行:工商银行:储蓄卡"
    echo "  Income:工资:基本工资"
    echo "  Expenses:食品:早餐"
    return 0
}

# 构建 beancount-gs 程序
build_beancount_gs() {
    print_info "构建 beancount-gs 程序..."
    
    # 检查是否在虚拟环境中
    if [ -z "$VIRTUAL_ENV" ]; then
        print_warning "不在虚拟环境中，尝试激活..."
        activate_venv || return 1
    fi
    
    # 检查 Go 是否可用
    if [ "$GO_AVAILABLE" != "true" ]; then
        print_error "Go 不可用，无法构建 beancount-gs"
        return 1
    fi
    
    # 切换到项目目录
    cd "$PROJECT_DIR" || {
        print_error "无法切换到项目目录"
        return 1
    }
    
    # 停止可能正在运行的旧版本
    stop_beancount_gs
    
    # 检查是否存在旧版本
    if [ -f "$BEANCOUNT_GS" ]; then
        print_warning "发现旧版本: $BEANCOUNT_GS"
        
        # 显示旧版本信息
        echo ""
        print_info "旧版本信息:"
        echo "  文件路径: $BEANCOUNT_GS"
        echo "  文件大小: $(du -h "$BEANCOUNT_GS" | cut -f1)"
        echo "  修改时间: $(stat -c %y "$BEANCOUNT_GS" 2>/dev/null || stat -f %Sm "$BEANCOUNT_GS" 2>/dev/null || echo "未知")"
        
        # 检查是否正在运行
        if pgrep -f "beancount-gs" >/dev/null 2>&1; then
            print_warning "检测到 beancount-gs 正在运行"
        fi
        
        echo ""
        read -p "是否删除旧版本并重新构建? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_info "保留旧版本，不重新构建..."
            return 0
            print_info "未重新构建 beancount-gs"
        else
            print_info "删除旧版本..."
            rm -f "$BEANCOUNT_GS"
            if [ $? -eq 0 ]; then
                print_success "旧版本删除成功"
            else
                print_error "旧版本删除失败"
                return 1
            fi
        fi
    fi
    
    # 清理构建缓存
    print_info "清理 Go 构建缓存..."
    go clean -cache
    
    # 构建程序
    print_info "开始构建 beancount-gs..."
    go build -o "$BEANCOUNT_GS" .
    
    if [ $? -eq 0 ] && [ -f "$BEANCOUNT_GS" ]; then
        chmod +x "$BEANCOUNT_GS"
        
        # 显示构建信息
        echo ""
        print_success "beancount-gs 构建成功!"
        echo "  文件路径: $BEANCOUNT_GS"
        echo "  文件大小: $(du -h "$BEANCOUNT_GS" | cut -f1)"
        echo "  构建时间: $(date '+%Y-%m-%d %H:%M:%S')"
        
        # 验证构建结果
        if validate_beancount_gs_build; then
            print_success "构建验证通过"
        else
            print_warning "构建验证失败，但文件已生成"
        fi
        
        return 0
    else
        print_error "beancount-gs 构建失败"
        
        # 提供调试信息
        echo ""
        print_menu "调试建议:"
        echo "  1. 检查 Go 环境: go version"
        echo "  2. 检查依赖: go mod tidy"
        echo "  3. 查看详细错误: go build -x -o \"$BEANCOUNT_GS\" ."
        
        return 1
    fi
}

# 停止 beancount-gs 服务
stop_beancount_gs() {
    print_info "停止 beancount-gs 服务..."
    
    local stopped_count=0
    
    # 方法1: 通过进程名停止
    if pgrep -f "beancount-gs" >/dev/null 2>&1; then
        print_info "通过进程名停止 beancount-gs..."
        pkill -f "beancount-gs"
        sleep 2
        if pgrep -f "beancount-gs" >/dev/null 2>&1; then
            print_warning "进程仍在运行，强制停止..."
            pkill -9 -f "beancount-gs"
            sleep 1
        fi
        stopped_count=$((stopped_count + 1))
    fi
    
    # 方法2: 清理可能占用的端口
    local ports=(10000 8080 3000)  # beancount-gs 常用端口
    for port in "${ports[@]}"; do
        if cleanup_port $port; then
            stopped_count=$((stopped_count + 1))
        fi
    done
    
    if [ $stopped_count -gt 0 ]; then
        print_success "beancount-gs 服务停止完成"
    else
        print_info "未发现运行的 beancount-gs 服务"
    fi
}

# 验证 beancount-gs 构建结果
validate_beancount_gs_build() {
    print_info "验证 beancount-gs 构建结果..."
    
    if [ ! -f "$BEANCOUNT_GS" ]; then
        print_error "构建文件不存在"
        return 1
    fi
    
    # 检查文件是否可执行
    if [ ! -x "$BEANCOUNT_GS" ]; then
        print_error "构建文件不可执行"
        return 1
    fi
    
    # 检查文件类型
    local file_type=$(file "$BEANCOUNT_GS" 2>/dev/null)
    if [[ "$file_type" != *"executable"* ]] && [[ "$file_type" != *"ELF"* ]] && [[ "$file_type" != *"Mach-O"* ]]; then
        print_warning "文件类型可能不正确: $file_type"
    fi
    
    # 尝试获取版本信息（如果支持）
    if timeout 5s "$BEANCOUNT_GS" --version >/dev/null 2>&1; then
        print_success "版本检查通过"
        return 0
    elif timeout 5s "$BEANCOUNT_GS" -version >/dev/null 2>&1; then
        print_success "版本检查通过"
        return 0
    elif timeout 5s "$BEANCOUNT_GS" version >/dev/null 2>&1; then
        print_success "版本检查通过"
        return 0
    else
        print_warning "无法获取版本信息，但文件已生成"
        return 0
    fi
}

# 克隆示例账本
clone_example_beanbook() {
    print_info "拉取远程账本示例..."
    
    local target_dir="$BEANCOUNT_REPO"
    local repo_url="https://cnb.cool/ysundy/bean/example-beanbook"
    local branch="3978d009748ef54ad6ef7bf851bd55491b1fe6bb"
    
    # 检查目标目录是否已存在
    if [ -d "$target_dir" ] && [ -d "$target_dir/.git" ]; then
        print_success "账本示例已存在，跳过克隆"
        return 0
    fi
    
    # 创建目录并克隆
    mkdir -p "$(dirname "$target_dir")" && \
    git clone -b "$branch" "$repo_url" "$target_dir"
    
    if [ $? -eq 0 ]; then
        print_success "账本示例克隆成功"
        return 0
    else
        print_error "账本示例克隆失败"
        return 1
    fi
}

# 清理端口占用
cleanup_port() {
    local port=$1
    print_info "检查端口 $port 占用情况..."
    
    local cleaned=false
    
    # 检查端口是否被占用
    if command -v lsof >/dev/null 2>&1; then
        if lsof -i :$port >/dev/null 2>&1; then
            print_warning "端口 $port 被占用，正在清理..."
            
            # 获取占用端口的进程信息
            local process_info=$(lsof -i :$port | awk 'NR==2 {print $1, $2, $NF}')
            local pids=$(lsof -ti :$port)
            
            if [ -n "$pids" ]; then
                print_warning "占用进程: $process_info"
                print_warning "杀死进程: $pids"
                
                # 先尝试正常终止
                kill $pids 2>/dev/null
                sleep 2
                
                # 如果还在运行，强制杀死
                if lsof -i :$port >/dev/null 2>&1; then
                    print_warning "进程仍在运行，强制杀死..."
                    kill -9 $pids 2>/dev/null
                    sleep 1
                fi
                
                # 最终检查
                if lsof -i :$port >/dev/null 2>&1; then
                    print_error "无法完全清理端口 $port 的占用"
                    return 1
                else
                    print_success "端口 $port 已清理完成"
                    cleaned=true
                fi
            fi
        else
            print_success "端口 $port 空闲可用"
            cleaned=true
        fi
    else
        print_warning "lsof 命令不可用，使用 netstat 检查端口..."
        
        if command -v netstat >/dev/null 2>&1; then
            if netstat -tulpn 2>/dev/null | grep ":$port" >/dev/null 2>&1; then
                print_warning "端口 $port 被占用（netstat 检测）"
                print_warning "请手动检查并终止占用进程"
                return 1
            else
                print_success "端口 $port 空闲可用"
                cleaned=true
            fi
        else
            print_warning "无法检测端口占用情况，跳过检查"
            cleaned=true
        fi
    fi
    
    if [ "$cleaned" = true ]; then
        return 0
    else
        return 1
    fi
}

# 启动 beancount-gs web 界面
start_beancount_gs() {
    print_info "启动 beancount-gs web 界面..."
    
    # 检查可执行文件是否存在
    if [ ! -f "$BEANCOUNT_GS" ]; then
        print_error "beancount-gs 可执行文件不存在"
        read -p "是否立即构建? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            return 1
        else
            if ! build_beancount_gs; then
                return 1
            fi
        fi
    fi
    
    local port=10000
    local secret="B8nK2dL7qR4tY9"
    local debug="false"  # 使用字符串
    
    # 停止可能正在运行的实例
    stop_beancount_gs
    
    # 清理端口占用
    if ! cleanup_port $port; then
        print_error "无法清理端口 $port，启动失败"
        return 1
    fi
    
    # 验证构建文件
    if ! validate_beancount_gs_build; then
        print_warning "构建文件验证失败，但尝试启动..."
    fi
    
    print_info "启动 beancount-gs web 界面..."
    print_info "配置: 端口=$port, 调试模式=$debug"
    
    # 启动程序
    local log_file="$PROJECT_DIR/beancount-gs.log"
    print_info "日志文件: $log_file"
    
    case "$PLATFORM" in
        "linux")
            print_info "使用 nohup 后台运行...,日志文件: $log_file, 调试模式: $debug"
            nohup "$BEANCOUNT_GS" -p "$port" -secret "$secret" -debug "$debug" > "$log_file" 2>&1 &
            ;;
        "windows")
            # Windows 下使用 start 命令在后台运行
             # 添加Windows平台的调试信息输出
            print_info "Windows平台调试模式: $debug"
            cmd //c "start /B \"beancount-gs\" \"$BEANCOUNT_GS\" -p $port -secret $secret -debug \"$debug\" > \"$log_file\" 2>&1"
            ;;
    esac
    
    local pid=$!
    
    # 等待程序启动
    print_info "等待服务启动..."
    sleep 5
    
    # 检查程序是否正常运行
    if ps -p $pid >/dev/null 2>&1 || pgrep -f "beancount-gs" >/dev/null 2>&1; then
        print_success "beancount-gs 启动成功!"
        echo ""
        print_menu "服务信息:"
        echo "  PID: $pid"
        echo "  端口: $port"
        echo "  密钥: $secret"
        echo "  日志: $log_file"
        echo "  Web界面: http://localhost:$port"
        echo "  调试模式: $debug"
        echo ""
        print_info "查看实时日志: tail -f \"$log_file\""
        
        # 检查服务是否真正响应
        check_service_health() {
            local port=$1
            local timeout=5
            local max_retries=3
            local retry_interval=1
            local retry_count=0
            
            # 检查端口是否被监听
            if ! lsof -i :$port >/dev/null 2>&1; then
                return 1
            fi
            
            # 尝试访问/version端点
            while [ $retry_count -lt $max_retries ]; do
                if curl -sSf -m $timeout http://localhost:$port/api/version >/dev/null 2>&1; then
                    return 0
                fi
                retry_count=$((retry_count + 1))
                sleep $retry_interval
            done
            
            return 1
        }
        
        if ! check_service_health $port; then
            print_error "服务未响应"
            return 1
        fi
        
        return 0
    else
        print_error "beancount-gs 启动失败"
        
        # 显示日志文件内容
        if [ -f "$log_file" ]; then
            echo ""
            print_error "启动日志:"
            tail -20 "$log_file"
        fi
        
        return 1
    fi
}

# 显示 beancount-gs 状态
show_beancount_gs_status() {
    print_info "beancount-gs 服务状态"
    
    echo ""
    print_menu "文件状态:"
    if [ -f "$BEANCOUNT_GS" ]; then
        echo "  ✅ 可执行文件存在: $BEANCOUNT_GS"
        echo "     大小: $(du -h "$BEANCOUNT_GS" | cut -f1)"
        echo "     修改: $(stat -c %y "$BEANCOUNT_GS" 2>/dev/null || stat -f %Sm "$BEANCOUNT_GS" 2>/dev/null || echo "未知")"
    else
        echo "  ❌ 可执行文件不存在"
    fi
    
    echo ""
    print_menu "进程状态:"
    if pgrep -f "beancount-gs" >/dev/null 2>&1; then
        echo "  ✅ 服务正在运行"
        local pids=$(pgrep -f "beancount-gs")
        echo "     PIDs: $pids"
        
        # 检查端口占用
        local ports=(10000 8080 3000)
        for port in "${ports[@]}"; do
            if lsof -i :$port >/dev/null 2>&1 || (command -v netstat >/dev/null && netstat -tulpn 2>/dev/null | grep ":$port" >/dev/null); then
                echo "     端口 $port: 被占用"
            fi
        done
    else
        echo "  ❌ 服务未运行"
    fi
    
    echo ""
    print_menu "网络状态:"
    if curl -s "http://localhost:10000" >/dev/null 2>&1; then
        echo "  ✅ Web 界面可访问: http://localhost:10000"
    else
        echo "  ❌ Web 界面不可访问"
    fi
}

# 显示 beancount-gs 日志
show_beancount_gs_logs() {
    local log_file="$PROJECT_DIR/beancount-gs.log"
    
    if [ ! -f "$log_file" ]; then
        print_warning "日志文件不存在: $log_file"
        return 1
    fi
    
    echo ""
    print_menu "beancount-gs 日志 (最后 20 行)"
    echo "========================================"
    tail -20 "$log_file"
    echo "========================================"
    echo ""
    print_info "完整日志文件: $log_file"
    print_info "实时查看: tail -f \"$log_file\""
}

# 安装 VSCode 中文语言包
install_vscode_language_pack() {
    print_info "安装 VSCode 中文语言包..."
    
    if command -v code >/dev/null 2>&1; then
        code --install-extension MS-CEINTL.vscode-language-pack-zh-hans
        
        if [ $? -eq 0 ]; then
            print_success "VSCode 中文语言包安装成功"
        else
            print_error "VSCode 中文语言包安装失败，请手动安装"
        fi
    else
        print_warning "VSCode 命令未找到，跳过语言包安装"
    fi
}

# 系统状态检查
check_system_status() {
    print_info "7. 检查系统状态..."
    
    echo ""
    print_menu "=== 平台信息 ==="
    echo "平台: $PLATFORM"
    echo "项目目录: $PROJECT_DIR"
    
    echo ""
    print_menu "=== Python 环境 ==="
    if command -v $PYTHON_CMD >/dev/null 2>&1; then
        echo "Python: $($PYTHON_CMD --version 2>&1)"
        echo "Python 路径: $(which $PYTHON_CMD)"
    else
        print_error "Python 未找到"
    fi
    
    echo ""
    print_menu "=== 虚拟环境 ==="
    if [ -d "$VENV_DIR" ]; then
        print_success "虚拟环境存在: $VENV_DIR"
        if [ -n "$VIRTUAL_ENV" ]; then
            print_success "虚拟环境已激活"
        else
            print_warning "虚拟环境未激活"
        fi
    else
        print_error "虚拟环境不存在"
    fi
    
    echo ""
    print_menu "=== Go 环境 ==="
    if [ "$GO_AVAILABLE" = "true" ]; then
        print_success "Go 可用: $(go version)"
    else
        print_warning "Go 不可用"
    fi
    
    echo ""
    print_menu "=== Beancount-gs ==="
    if [ -f "$BEANCOUNT_GS" ]; then
        print_success "beancount-gs 可执行文件存在"
        # 检查是否在运行
        if pgrep -f "beancount-gs" >/dev/null 2>&1; then
            print_success "beancount-gs 正在运行"
        else
            print_info "beancount-gs 未运行"
        fi
    else
        print_warning "beancount-gs 可执行文件不存在"
    fi
    
    echo ""
    print_menu "=== 账本仓库 ==="
    if [ -d "$BEANCOUNT_REPO" ]; then
        print_success "账本仓库存在: $BEANCOUNT_REPO"
        if [ -d "$BEANCOUNT_REPO/.git" ]; then
            print_success "Git 仓库初始化正常"
        else
            print_warning "不是有效的 Git 仓库"
        fi
    else
        print_error "账本仓库不存在"
    fi
}

# 数据同步处理
handle_data_sync() {
    print_info "5. 数据同步功能"
    # 这里可以添加数据同步逻辑
    print_warning "5. 数据同步功能待实现"
}

# 通知管理
# 通知管理
handle_notification() {
    print_info "6. 通知管理功能"
    
    while true; do
        echo ""
        print_menu "6. 通知管理"
        echo "6-1. 快速发送通知"
        echo "6-2. 钉钉配置管理"
        echo "6-3. 发送构建开始通知"
        echo "6-4. 发送构建成功通知"
        echo "6-5. 发送构建失败通知"
        echo "6-6. 发送服务启动通知"
        echo "6-7. 发送服务停止通知"
        echo "6-8. 发送错误告警"
        echo "6-9. 测试钉钉配置"
        echo "6-10. 查看通知配置"
        echo "6-11. 返回主菜单"
        
        read -p "请选择 [1-11]: " notify_choice
        
        case "$notify_choice" in
            1)
                quick_notification
                ;;
            2)
                manage_dingtalk_config
                ;;
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
            9)
                test_dingtalk_config
                ;;
            10)
                show_notification_settings
                ;;
            11)
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
        
        read -p "按回车继续..."
    done
}

# 维护功能
handle_maintenance() {
    print_info "8. 系统维护功能"
    
    echo ""
    print_menu "请选择维护操作:"
    echo "8-1. 清理 Python 缓存"
    echo "8-2. 清理 pip 缓存"
    echo "8-3. 清理 Go 缓存"
    echo "8-4. 删除虚拟环境"
    echo "8-5. 删除依赖文件"
    echo "8-6. 完整清理"
    echo "8-7. 返回主菜单"
    
    read -p "请选择 [1-7]: " maintenance_choice
    
    case "$maintenance_choice" in
        1)
            print_info "清理 Python 缓存..."
            find "$PROJECT_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
            find "$PROJECT_DIR" -name "*.pyc" -delete 2>/dev/null
            find "$PROJECT_DIR" -name "*.pyo" -delete 2>/dev/null
            print_success "Python 缓存清理完成"
            ;;
        2)
            clean_pip_cache
            ;;
        3)
            if command -v go >/dev/null 2>&1; then
                print_info "清理 Go 缓存..."
                go clean -cache
                go clean -modcache
                print_success "Go 缓存清理完成"
            else
                print_warning "Go 未安装"
            fi
            ;;
        4)
            if [ -d "$VENV_DIR" ]; then
                print_warning "删除虚拟环境..."
                rm -rf "$VENV_DIR"
                print_success "虚拟环境删除完成"
            else
                print_info "虚拟环境不存在"
            fi
            ;;
        5)
            if [ -f "$REQUIREMENTS_FILE" ]; then
                print_warning "删除依赖文件..."
                rm -f "$REQUIREMENTS_FILE"
                print_success "依赖文件删除完成"
            else
                print_info "依赖文件不存在"
            fi
            ;;
        6)
            clean_environment
            ;;
        7)
            return
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
    
    read -p "按回车继续..."
}

# 初始化函数
initialize_functions() {
    print_info "初始化功能函数库..."
    setup_paths
    print_success "功能函数库初始化完成"
}

# 自动初始化
initialize_functions
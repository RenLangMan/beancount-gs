# 重构脚本

## 重构原因

当前架构的问题

1. **功能重叠**：`run.sh` 负责环境清理，`start_on_cnb.sh` 负责环境构建
2. **职责不清**：用户需要知道两个脚本的区别和使用顺序
3. **维护复杂**：两个脚本都需要维护，容易产生不一致
4. **用户体验差**：需要运行两个脚本才能完成完整流程

## 建议的合并方案

将 `run.sh` 的功能整合到 `start_on_cnb.sh` 中，通过参数控制模式：

### 合并后的 `start_on_cnb.sh`

```bash
#!/bin/bash

###
 # @Author: liangzai450
 # @Date: 2025-09-06 13:18:36
 # @LastEditors: liangzai450
 # @LastEditTime: 2025-09-13 00:00:00
 # @FilePath: /workspace/.scripts/start_on_cnb.sh
 # @Description: Beancount v3 云端开发环境自动配置脚本
 # 用法:
 #   ./start_on_cnb.sh          # 快速模式 (默认)
 #   ./start_on_cnb.sh clean    # 完整重构模式
 #   ./start_on_cnb.sh help     # 显示帮助
 # Copyright (c) 2025 by ${git_name_email}, All Rights Reserved. 
 # ==============================================
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
    echo "Beancount v3 云端开发环境自动配置脚本"
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

# 检查是否在 /workspace 目录
check_workspace_dir() {
    local current_dir=$(pwd)
    if [ "$current_dir" != "/workspace" ]; then
        print_warning "当前目录: $current_dir"
        print_info "切换到 /workspace 目录..."
        cd /workspace || {
            print_error "无法切换到 /workspace 目录"
            exit 1
        }
        print_success "已切换到 /workspace 目录"
    fi
}

# 清理 pip 缓存函数
clean_pip_cache() {
    print_info "清理 pip 缓存..."
    
    if command -v pip >/dev/null 2>&1; then
        # 显示清理前状态
        print_info "清理前 pip 缓存状态:"
        pip cache info
        
        # 执行清理
        print_info "执行 pip cache purge..."
        if pip cache purge 2>/dev/null; then
            print_success "pip 缓存清理完成"
            
            # 显示清理后状态
            print_info "清理后 pip 缓存状态:"
            pip cache info
        else
            print_warning "pip cache purge 失败，尝试手动清理..."
            local cache_dir=$(pip cache dir 2>/dev/null || echo "/root/.cache/pip")
            if [ -d "$cache_dir" ]; then
                rm -rf "$cache_dir"
                print_success "手动清理 pip 缓存完成"
            fi
        fi
    else
        print_warning "pip 未安装，跳过缓存清理"
    fi
}

# 完整环境清理函数
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

    # 3. 清理 pip 缓存
    clean_pip_cache

    # 4. 检查并删除现有的虚拟环境
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

    # 5. 检查并删除依赖文件
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
    
    # 6. 清理 Python 缓存文件
    print_info "清理 Python 缓存文件..."
    find /workspace -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
    find /workspace -name "*.pyc" -delete 2>/dev/null
    find /workspace -name "*.pyo" -delete 2>/dev/null
    print_success "Python 缓存清理完成"
    
    print_success "完整环境清理完成！"
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
        print_warning "虚拟环境不存在，将自动创建"
    fi
}

# 环境初始化
setup_environment() {
    echo "[Beancount v3 云端开发环境自动配置脚本]"
    echo "========================================"
    echo "模式: $MODE"
    echo "========================================"

    # 脚本目录设置
    SCRIPT_DIR="/workspace/.scripts"
    if [ ! -d "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi

    # 基础路径设置
    DEV_DIR="workspace"
    DEV_ROOT="/$DEV_DIR"
    export DEV_ROOT

    # 添加工具到PATH
    export PATH="$DEV_ROOT/dev_tools/nodejs:$DEV_ROOT/dev_tools/git/bin:$PATH"

    # Python路径
    PYTHON_PATH="/usr/local/bin/python"

    if [ -f "$PYTHON_PATH" ]; then
        export PATH="$PYTHON_PATH:$PATH"
        print_success "Python已添加到PATH"
    else
        print_error "Python未找到: $PYTHON_PATH"
        exit 1
    fi

    # 设置别名
    alias python="$PYTHON_PATH"
    alias pip="$PYTHON_PATH -m pip"

    # 进入项目目录
    cd /workspace || { print_error "无法进入workspace目录"; exit 1; }

    # 检查Python版本
    print_info "检查Python版本..."
    python --version
}

# 原有的函数保持不变（只需要修改函数内部的echo语句为彩色输出）
create_venv() {
    print_info "创建虚拟环境: $VENV_NAME..."
    python -m venv "$VENV_NAME"
    
    if [ $? -eq 0 ]; then
        print_success "虚拟环境创建成功"
        return 0
    else
        print_error "虚拟环境创建失败"
        return 1
    fi
}

activate_venv() {
    print_info "激活虚拟环境..."
    source "$VENV_NAME/bin/activate"
    
    if [ $? -eq 0 ]; then
        print_success "虚拟环境激活成功"
        python --version
        return 0
    else
        print_error "虚拟环境激活失败"
        return 1
    fi
}

# 函数：安装依赖
install_dependencies() {
    print_info "安装Beancount v3依赖..."
    
    # 升级pip
    pip install --upgrade pip
    
    # 安装固定版本的依赖
    print_info "安装固定版本的依赖..."
    pip install beancount==3.2.0 beanquery==0.2.0 fava==1.30.6 beangulp==0.2.0 dateparser==1.2.2 debugpy==1.8.16 pytest==8.4.2 Pygments==2.19.2 pyzipper==0.3.6

    if [ $? -eq 0 ]; then
        print_success "依赖安装成功"
        
        # 生成requirements文件
        pip freeze > "$REQUIREMENTS_FILE"
        print_success "依赖已保存到 $REQUIREMENTS_FILE"
        return 0
    else
        print_error "依赖安装失败"
        return 1
    fi
}

# 函数：验证安装
verify_installation() {
    print_info "验证安装..."
    
    print_info "1. 检查fava版本:"
    python -c "import fava; print(f'Fava版本: {fava.__version__}')" 2>/dev/null && print_success "fava 版本检查成功" || print_error "fava 导入失败"
    
    print_info "2. 检查dateparser版本:"
    python -c "import dateparser; print(f'Dateparser版本: {dateparser.__version__}')" 2>/dev/null && print_success "dateparser 版本检查成功" || print_error "dateparser 导入失败"
    
    print_info "3. 检查debugpy版本:"
    python -c "import debugpy; print(f'Debugpy版本: {debugpy.__version__}')" 2>/dev/null && print_success "debugpy 版本检查成功" || print_error "debugpy 导入失败"
    
    print_info "4. 检查pytest版本:"
    python -c "import pytest; print(f'Pytest版本: {pytest.__version__}')" 2>/dev/null && print_success "pytest 版本检查成功" || print_error "pytest 导入失败"
    
    print_info "5. 检查Pygments版本:"
    python -c "import pygments; print(f'Pygments版本: {pygments.__version__}')" 2>/dev/null && print_success "Pygments 版本检查成功" || print_error "Pygments 导入失败"
    
    print_info "6. 检查pyzipper:"
    python -c "import pyzipper; print(f'Pyzipper版本: {pyzipper.__version__}')" 2>/dev/null && print_success "pyzipper 版本检查成功" || python -c "import pyzipper; print('Pyzipper导入成功')" 2>/dev/null && print_success "pyzipper 导入成功"
    
    print_info "7. 检查beancount版本:"
    python -c "import beancount; print(f'Beancount版本: {beancount.__version__}')" 2>/dev/null && print_success "beancount 版本检查成功" || print_error "beancount 导入失败"
    
    print_info "8. 检查beanquery:"
    python -c "import beanquery; print('Beanquery导入成功')" 2>/dev/null && print_success "beanquery 导入成功" || print_error "beanquery 导入失败"
    
    print_success "所有依赖安装验证完成"
}

# 函数：为Beancount添加中文账户名支持
patch_beancount_for_chinese() {
    echo ""
    print_info "为Beancount添加中文账户名支持..."
    
    # 直接定位account.py文件
    ACCOUNT_FILE="$VENV_NAME/lib/python"*"/site-packages/beancount/core/account.py"
    
    # 使用通配符展开找到确切的文件路径
    ACCOUNT_FILES=$(ls $ACCOUNT_FILE 2>/dev/null)
    
    if [ -z "$ACCOUNT_FILES" ]; then
        print_error "未找到beancount库的account.py文件"
        
        # 非CNB环境中询问用户
        print_warning "是否继续执行脚本？(跳过中文支持补丁) [Y/n]"
        read -r response
        if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
            print_error "用户选择中断脚本执行"
            return 1
        else
            print_warning "跳过中文支持补丁但继续执行脚本其他内容"
            return 0
        fi
    fi
    
    print_success "找到account.py文件:"
    echo "$ACCOUNT_FILES"
    
    # 为每个找到的文件创建备份并进行替换
    for FILE in $ACCOUNT_FILES; do
        print_info "处理文件: $FILE"
        
        # 创建备份
        BACKUP="${FILE}.bak"
        cp "$FILE" "$BACKUP"
        print_success "已创建备份: $BACKUP"
        
        # 使用grep查找包含"Component separator for account names"的行号
        START_LINE=$(grep -n "Component separator for account names" "$FILE" | cut -d: -f1)
        
        if [ -z "$START_LINE" ]; then
            print_error "无法找到起始行标记"
            print_warning "尝试使用固定行号替换..."
            START_LINE=28
        fi
        
        # 使用grep查找包含"TYPE = \"<AccountDummy>\""的行号
        END_LINE=$(grep -n "TYPE = \"<AccountDummy>\"" "$FILE" | cut -d: -f1)
        
        if [ -z "$END_LINE" ]; then
            print_error "无法找到结束行标记"
            print_warning "尝试使用固定行号替换..."
            END_LINE=41
        fi
        
        print_success "找到替换范围: 第${START_LINE}行到第${END_LINE}行"
        
        # 使用sed进行替换，使用动态行号
        sed -i.tmp "${START_LINE},${END_LINE}c\\
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
" "$FILE"
        
        # 检查替换是否成功
        if [ $? -eq 0 ]; then
            print_success "文件已成功更新"
            # 删除临时文件
            rm -f "${FILE}.tmp"

            print_success "中文账户名支持已添加"
            print_success "现在可以使用如下中文账户名:"
            echo "  Assets:银行:工商银行:储蓄卡"
            echo "  Income:工资:基本工资"
            echo "  Expenses:食品:早餐"
            print_success "现在可以使用中文账户名了！"
        else
            print_error "更新失败，正在恢复备份"
            cp "$BACKUP" "$FILE"
            print_info "备份文件: $BACKUP"
            print_info "原始文件: $FILE"
            print_info "请手动检查文件是否正确更新"
            print_warning "请注意，中文账户名支持添加失败，脚本将继续执行"
            print_warning "beancount-gs将无法支持中文账户名"
        fi
    done
}

# 函数：安装VSCode中文语言包
install_vscode_language_pack() {
    print_info "安装VSCode中文语言包..."
    code-server --install-extension MS-CEINTL.vscode-language-pack-zh-hans
    
    if [ $? -eq 0 ]; then
        print_success "VSCode中文语言包安装成功"
    else
        print_error "VSCode中文语言包安装失败，请手动安装"
    fi
}

# 函数：构建beancount-gs程序
build_beancount_gs() {
    print_info "构建beancount-gs程序..."
    
    # 检查是否在虚拟环境中
    if [ -z "$VIRTUAL_ENV" ]; then
        print_warning "不在虚拟环境中，尝试激活..."
        source "$VENV_NAME/bin/activate"
    fi
    
    # 构建程序
    go build -o beancount-gs .
    
    if [ $? -eq 0 ] && [ -f "beancount-gs" ]; then
        print_success "beancount-gs构建成功"
        chmod +x beancount-gs
    else
        print_error "beancount-gs构建失败"
        return 1
    fi
}

# 函数：拉取远程账本示例
clone_example_beanbook() {
    print_info "拉取远程账本示例..."
    
    TARGET_DIR="/workspace/data/beancount/3978d009748ef54ad6ef7bf851bd55491b1fe6bb"
    
    # 检查目标目录是否已存在
    if [ -d "$TARGET_DIR" ] && [ -d "$TARGET_DIR/.git" ]; then
        print_success "账本示例已存在，跳过克隆"
        return 0
    fi
    
    # 创建目录并克隆
    mkdir -p "$TARGET_DIR" && \
    git clone -b 3978d009748ef54ad6ef7bf851bd55491b1fe6bb \
        https://cnb.cool/ysundy/bean/example-beanbook \
        "$TARGET_DIR"
    
    if [ $? -eq 0 ]; then
        print_success "账本示例克隆成功"
    else
        print_error "账本示例克隆失败"
        return 1
    fi
}

# 函数：清理端口占用
cleanup_port() {
    local port=$1
    print_info "检查端口 $port 占用情况..."
    
    # 检查端口是否被占用
    if lsof -i :$port >/dev/null 2>&1; then
        print_warning "端口 $port 被占用，正在清理..."
        
        # 获取占用端口的进程ID并杀死
        pids=$(lsof -ti :$port)
        if [ -n "$pids" ]; then
            print_warning "杀死占用端口的进程: $pids"
            kill -9 $pids 2>/dev/null
            sleep 2  # 等待进程完全终止
            
            # 再次检查是否清理成功
            if lsof -i :$port >/dev/null 2>&1; then
                print_error "无法完全清理端口 $port 的占用"
                return 1
            else
                print_success "端口 $port 已清理完成"
                return 0
            fi
        fi
    else
        print_success "端口 $port 空闲可用"
        return 0
    fi
}

# 函数：启动beancount-gs web界面
start_beancount_gs() {
    print_info "启动beancount-gs web界面..."
    
    local port=10000
    local secret="B8nK2dL7qR4tY9"
    local debug=false
    
    # 清理端口占用
    if ! cleanup_port $port; then
        print_error "无法清理端口 $port，启动失败"
        return 1
    fi
    
    if [ -f "beancount-gs" ]; then
        print_info "启动beancount-gs web界面..."
        print_info "当前debug模式: $debug"
        # 启动程序并指定端口（如果程序支持端口参数）
        ./beancount-gs --p $port -secret $secret -debug $debug &
        local pid=$!
        
        # 等待程序启动
        sleep 3
        
        # 检查程序是否正常运行
        if ps -p $pid >/dev/null 2>&1; then
            print_success "beancount-gs已启动 (PID: $pid, 端口: $port, 密钥: $secret)"
            print_info "Web界面地址: http://localhost:$port"
            return 0
        else
            print_error "beancount-gs启动失败"
            return 1
        fi
    else
        print_error "beancount-gs可执行文件不存在，请先构建"
        return 1
    fi
}

# 设置 Git 工具别名
setup_git_aliases() {
    print_info "设置 Git 快捷命令..."
    if [ -f "$SCRIPT_DIR/beancount-aliases.sh" ]; then
        source "$SCRIPT_DIR/beancount-aliases.sh"
        print_success "已加载 beancount-aliases.sh"
    else
        # 基础别名
        alias gp='git add . && git commit -m "Update beancount files" && git push'
        alias gs='git status'
        alias ga='git add'
        alias gc='git commit'
        alias gpl='git pull'
        alias githelp='echo "可用命令: gp(快速推送), gs(状态), ga(添加), gc(提交), gpl(拉取)"'
        print_success "已设置基础 Git 别名"
    fi
}

# 主执行流程
main() {
    # 清屏
    clear
    # 检查工作目录
    check_workspace_dir
    
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

    # 根据模式进行环境准备
    case "$MODE" in
        "clean")
            clean_environment
            ;;
        "fast")
            fast_prepare
            ;;
    esac

    # 环境初始化
    setup_environment
    echo "========================================"
    print_success "1/11.  Beancount v3 环境初始化完成！"
    echo "========================================"

    # 定义虚拟环境名称和依赖文件
    VENV_NAME=".env_beancount-v3"
    REQUIREMENTS_FILE="requirements-beancount-v3.txt"

    # 设置 Git 工具别名
    print_info "设置 Git 快捷命令..."
    if [ -f "$SCRIPT_DIR/beancount-aliases.sh" ]; then
        source "$SCRIPT_DIR/beancount-aliases.sh"
    else
        alias gp='git add . && git commit -m "Update beancount files" && git push'
        alias gs='git status'
        alias ga='git add'
        alias gc='git commit'
        alias gpl='git pull'
        alias githelp='echo "可用命令: gp(快速推送), gs(状态), ga(添加), gc(提交), gpl(拉取)"'
    fi
    echo "========================================"
    print_success "2/11.  Git 工具配置完成!"
    echo "========================================"

    # 检查虚拟环境是否存在
    if [ ! -d "$VENV_NAME" ]; then
        print_info "虚拟环境不存在，开始创建..."
        create_venv || exit 1
    else
        print_info "虚拟环境已存在，跳过创建"
    fi
    
    echo "========================================"
    print_success "3/11.  虚拟环境创建完成!"
    echo "========================================"
    
    # 激活虚拟环境
    activate_venv || exit 1
    
    echo "========================================"
    print_success "4/11.  虚拟环境激活完成!"
    echo "========================================"
    
    # 检查是否已安装beancount
    if ! python -c "import beancount" 2>/dev/null; then
        print_info "Beancount未安装，开始安装依赖..."
        install_dependencies
    else
        print_info "Beancount已安装，跳过依赖安装"
    fi

    echo "========================================"
    print_success "5/11.  Beancount依赖安装完成!"
    echo "========================================"
    
    # 验证安装
    verify_installation

    echo "========================================"
    print_success "6/11.  Beancount安装验证完成!"
    echo "========================================"
    
    # 添加中文账户名支持
    patch_beancount_for_chinese

    echo "========================================"
    print_success "7/11.  Beancount中文支持添加完成!"
    echo "========================================"
    
    # 安装VSCode中文语言包
    install_vscode_language_pack

    echo "========================================"
    print_success "8/11.  VSCode中文语言包安装完成!"
    echo "========================================"
    
    # 构建beancount-gs程序
    build_beancount_gs

    echo "========================================"
    print_success "9/11.  Beancount-GS构建完成!"
    echo "========================================"
    
    # 拉取远程账本示例
    clone_example_beanbook

    echo "========================================"
    print_success "10/11.  账本示例拉取完成!"
    echo "========================================"
    
    # 启动beancount-gs web界面
    start_beancount_gs

    echo "========================================"
    print_success "11/11.  Beancount-GS启动完成!"
    echo "========================================"
    
    echo ""
    echo "========================================"
    print_success "Beancount v3 云端开发环境配置完成！ ($MODE 模式)"
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
}

# 执行主函数
main "$@"
```

## 合并后的优势

1. **单一入口**：用户只需要知道一个脚本
2. **模式选择**：通过参数控制清理级别
3. **更好的用户体验**：清晰的彩色输出和提示
4. **易于维护**：所有功能在一个脚本中
5. **向后兼容**：默认行为保持不变

## 使用方式

```bash
# 快速模式（默认）
/workspace/.scripts/start_on_cnb.sh

# 完整重构模式
/workspace/.scripts/start_on_cnb.sh clean

# 帮助信息
/workspace/.scripts/start_on_cnb.sh help
```

这样合并后，你的脚本会更加用户友好且易于维护！

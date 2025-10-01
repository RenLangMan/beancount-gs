#!/bin/bash

###
 # @Author: liangzai450
 # @Date: 2025-09-06 13:18:36
 # @LastEditors: liangzai450
 # @LastEditTime: 2025-09-17 23:07:18
 # @FilePath: /cnb-beancount/linux_start_dev.sh
 # @Description: Beancount v3 开发环境自动配置脚本 (Linux版本)
 # Copyright (c) 2025 by ${git_name_email}, All Rights Reserved. 
 # ==============================================
### 

echo "[Beancount v3 开发环境自动配置脚本 - Linux版本]"
echo "========================================"

# 检查是否在支持的终端中运行
if [[ "$OSTYPE" != "linux-gnu"* && "$OSTYPE" != "darwin"* ]]; then
    echo "警告: 此脚本专为 Linux/macOS 设计，当前环境: $OSTYPE"
    read -p "是否继续? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 获取脚本所在目录作为根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$SCRIPT_DIR"

export DEV_ROOT

echo "项目根目录: $DEV_ROOT"

# 添加工具到PATH（如果存在dev_tools目录）
if [ -d "$DEV_ROOT/dev_tools" ]; then
    export PATH="$DEV_ROOT/dev_tools/nodejs:$DEV_ROOT/dev_tools/git/bin:$PATH"
    echo "✓ 开发工具已添加到PATH"
fi

# Python路径 - 使用系统Python或指定路径
PYTHON_PATH="python"

if command -v "$PYTHON_PATH" >/dev/null 2>&1; then
    echo "✓ 使用系统Python: $(which $PYTHON_PATH)"
else
    echo "✗ Python未找到，请确保已安装Python3"
    exit 1
fi

echo ""
echo "环境设置完成！"
echo "========================================"

# 进入脚本所在目录
cd "$SCRIPT_DIR" || { echo "无法进入项目目录"; exit 1; }

# 检查Python版本
echo "检查Python版本..."
$PYTHON_PATH --version

# 支持通过环境变量设置虚拟环境路径
DEFAULT_VENV_NAME=".env_beancount-v3"
if [ -n "$BEANCOUNT_VENV" ]; then
    VENV_NAME="$BEANCOUNT_VENV"
    echo "使用自定义虚拟环境: $VENV_NAME"
else
    VENV_NAME="$DEFAULT_VENV_NAME"
fi

REQUIREMENTS_FILE="requirements-beancount-v3.txt"

# 函数：创建虚拟环境
create_venv() {
    echo "创建虚拟环境: $VENV_NAME..."
    $PYTHON_PATH -m venv "$VENV_NAME"
    
    if [ $? -eq 0 ]; then
        echo "✓ 虚拟环境创建成功"
        return 0
    else
        echo "✗ 虚拟环境创建失败"
        return 1
    fi
}

# 函数：激活虚拟环境
activate_venv() {
    echo "激活虚拟环境..."
    if [ -f "$VENV_NAME/bin/activate" ]; then
        source "$VENV_NAME/bin/activate"
    else
        echo "✗ 找不到activate脚本"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        echo "✓ 虚拟环境激活成功"
        python --version
        return 0
    else
        echo "✗ 虚拟环境激活失败"
        return 1
    fi
}

# 函数：安装依赖
install_dependencies() {
    echo "安装Beancount v3依赖..."
    
    # 升级pip
    pip install --upgrade pip
    
    # 安装固定版本的依赖
    echo "安装固定版本的依赖..."
    pip install beancount==3.1.0 beanquery==0.2.0 fava==1.30.5 beangulp==0.2.0 dateparser==1.2.2 debugpy==1.8.16 pytest==8.4.2 Pygments==2.19.2 pyzipper==0.3.6

    if [ $? -eq 0 ]; then
        echo "✓ 依赖安装成功"
        
        # 生成requirements文件
        pip freeze > "$REQUIREMENTS_FILE"
        echo "✓ 依赖已保存到 $REQUIREMENTS_FILE"
        return 0
    else
        echo "✗ 依赖安装失败，尝试使用requirements文件安装..."
        
        if [ -f "$REQUIREMENTS_FILE" ]; then
            pip install -r "$REQUIREMENTS_FILE"
            if [ $? -eq 0 ]; then
                echo "✓ 使用requirements文件安装成功"
                return 0
            fi
        fi
        return 1
    fi
}

# 函数：验证安装
verify_installation() {
    echo "验证安装..."
    
    local success=true
    
    echo "1. 检查fava版本:"
    python -c "import fava; print(f'Fava版本: {fava.__version__}')" 2>/dev/null || { echo "  ✗ Fava未安装"; success=false; }
    
    echo "2. 检查dateparser版本:"
    python -c "import dateparser; print(f'Dateparser版本: {dateparser.__version__}')" 2>/dev/null || { echo "  ✗ Dateparser未安装"; success=false; }
    
    echo "3. 检查debugpy版本:"
    python -c "import debugpy; print(f'Debugpy版本: {debugpy.__version__}')" 2>/dev/null || { echo "  ✗ Debugpy未安装"; success=false; }
    
    echo "4. 检查pytest版本:"
    python -c "import pytest; print(f'Pytest版本: {pytest.__version__}')" 2>/dev/null || { echo "  ✗ Pytest未安装"; success=false; }
    
    echo "5. 检查Pygments版本:"
    python -c "import pygments; print(f'Pygments版本: {pygments.__version__}')" 2>/dev/null || { echo "  ✗ Pygments未安装"; success=false; }
    
    echo "6. 检查pyzipper:"
    python -c "import pyzipper; print(f'Pyzipper版本: {pyzipper.__version__}')" 2>/dev/null || python -c "import pyzipper; print('Pyzipper导入成功')" 2>/dev/null || { echo "  ✗ Pyzipper未安装"; success=false; }
    
    echo "7. 检查beancount版本:"
    python -c "import beancount; print(f'Beancount版本: {beancount.__version__}')" 2>/dev/null || { echo "  ✗ Beancount未安装"; success=false; }
    
    echo "8. 检查beanquery:"
    python -c "import beanquery; print('Beanquery导入成功')" 2>/dev/null || { echo "  ✗ Beanquery未安装"; success=false; }
    
    if [ "$success" = true ]; then
        echo "✓ 所有依赖安装验证完成"
    else
        echo "⚠ 部分依赖未安装成功"
    fi
}

# 主执行流程
main() {
    # 检查虚拟环境是否存在
    if [ ! -d "$VENV_NAME" ]; then
        echo "虚拟环境不存在，开始创建..."
        create_venv || exit 1
    else
        echo "虚拟环境已存在，跳过创建"
        echo "当前路径为: $(pwd)"
    fi
    
    # 激活虚拟环境
    activate_venv || exit 1
    
    # 检查是否已安装beancount
    if ! python -c "import beancount" 2>/dev/null; then
        echo "Beancount未安装，开始安装依赖..."
        install_dependencies || {
            echo "依赖安装失败，请手动检查"
            exit 1
        }
    else
        echo "Beancount已安装，跳过依赖安装"
    fi
    
    # 验证安装
    verify_installation
    
    echo ""
    echo "========================================"
    echo "🎉 Beancount v3 开发环境配置完成！"
    echo "虚拟环境: $VENV_NAME"
    echo "项目目录: $(pwd)"
    echo ""
    echo "可用命令:"
    echo "  source $VENV_NAME/bin/activate  # 激活虚拟环境"
    echo "  bean-check your_file.bean      # 检查语法"
    echo "  bean-query your_file.bean      # 执行查询"
    echo "  fava your_file.bean            # 启动Web界面"
    echo "  go build .                     # 编译Beancount-gs"
    echo "  ./beancount-gs --p 10000 --secret \"C16E943D75\" --debug true --venv \"$VENV_NAME\"  # 运行Beancount-gs"
    echo ""
    echo "或者设置环境变量:"
    echo "  export BEANCOUNT_VENV=\"your_custom_venv_name\""
    echo "  ./linux_start_dev.sh"
    echo "========================================"
    
    # 保持脚本运行在激活的虚拟环境中
    exec bash
}

# 执行主函数
main "$@"
#!/bin/bash

# Git 自动克隆脚本
REPO_DIR="/workspace/data/beancount/3978d009748ef54ad6ef7bf851bd55491b1fe6bb"
REPO_URL="https://cnb.cool/ysundy/bean/example-beanbook"

# 设置默认仓库URL
REPO_URL="https://cnb.cool/ysundy/bean/example-beanbook"

# 如果有参数则使用参数URL
if [ $# -gt 0 ]; then
    REPO_URL="$1"
fi

echo "ℹ️ 使用仓库URL: $REPO_URL"

# 检查目录是否已存在
if [ -d "$REPO_DIR" ]; then
    echo "⚠ 警告: 目标目录已存在: $REPO_DIR"
    read -p "是否删除并重新克隆? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        exit 0
    fi
    rm -rf "$REPO_DIR"
fi

# 创建父目录
mkdir -p "$(dirname "$REPO_DIR")" || {
    echo "❌ 错误: 无法创建目录: $(dirname "$REPO_DIR")"
    exit 1
}

echo "� 开始克隆仓库..."
echo "� 远程仓库: $REPO_URL"
echo "📁 本地目录: $REPO_DIR"
echo "----------------------------------------"

# 执行克隆操作
git clone "$REPO_URL" "$REPO_DIR" || {
    echo "❌ 错误: 克隆仓库失败"
    exit 1
}

echo "----------------------------------------"
echo "✅ 克隆完成!"
echo "📌 仓库位置: $REPO_DIR"
echo "🌿 默认分支: $(cd "$REPO_DIR" && git branch --show-current)"

# 设置后续推送脚本
PUSH_SCRIPT="/workspace/.scripts/git_push.sh"
if [ -f "$PUSH_SCRIPT" ]; then
    echo "📝 推送脚本已存在: $PUSH_SCRIPT"
else
    echo "⚠ 警告: 推送脚本不存在，请确保已创建 $PUSH_SCRIPT"
fi
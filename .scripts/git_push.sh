#!/bin/bash

# Git 自动推送脚本 - 专为 Beancount v3 环境设计
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PUSH_COUNT_FILE="$SCRIPT_DIR/.push_count"
BEANCOUNT_REPO="/workspace/data/beancount/3978d009748ef54ad6ef7bf851bd55491b1fe6bb"

# 设置颜色输出
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 切换到仓库目录
cd "$BEANCOUNT_REPO" || { 
    echo -e "${RED}❌ 错误: 无法进入 Beancount 仓库目录${NC}"
    echo -e "请检查路径: $BEANCOUNT_REPO"
    exit 1
}

# 检查是否有更改
if [ -z "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}📝 没有需要提交的更改${NC}"
    exit 0
fi

# 读取或初始化推送次数
if [ -f "$PUSH_COUNT_FILE" ]; then
    PUSH_COUNT=$(cat "$PUSH_COUNT_FILE")
else
    PUSH_COUNT=0
fi

PUSH_COUNT=$((PUSH_COUNT + 1))
echo "$PUSH_COUNT" > "$PUSH_COUNT_FILE"

# 生成提交信息
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
BRANCH=$(git branch --show-current)
COMMIT_PREFIX="beancount"

# 如果有参数，使用参数作为提交信息
if [ $# -gt 0 ]; then
    COMMIT_MSG="$*"
else
    # 自动检测更改类型
    CHANGES=$(git status --porcelain)
    if echo "$CHANGES" | grep -q "month/.*\.bean"; then
        COMMIT_MSG="$COMMIT_PREFIX: 更新月度账本 - $TIMESTAMP"
    elif echo "$CHANGES" | grep -q "\.bean"; then
        COMMIT_MSG="$COMMIT_PREFIX: 更新账本文件 - $TIMESTAMP"
    else
        COMMIT_MSG="$COMMIT_PREFIX: 第$PUSH_COUNT次推送 - $TIMESTAMP"
    fi
fi

echo -e "${BLUE}🚀 Beancount Git 推送操作${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "📋 分支: ${GREEN}$BRANCH${NC}"
echo -e "💬 提交信息: ${YELLOW}$COMMIT_MSG${NC}"
echo -e "${BLUE}========================================${NC}"

# 显示更改摘要
echo -e "📊 更改摘要:"
git status --short

# 执行 Git 操作
echo -e "\n1. ${BLUE}添加文件...${NC}"
git add . || { echo -e "${RED}❌ git add 失败${NC}"; exit 1; }

echo -e "2. ${BLUE}提交更改...${NC}"
git commit -m "$COMMIT_MSG" || { echo -e "${RED}❌ git commit 失败${NC}"; exit 1; }

echo -e "3. ${BLUE}推送到远程...${NC}"
git push || { echo -e "${RED}❌ git push 失败${NC}"; exit 1; }

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ 推送完成!${NC}"
echo -e "📈 第 ${YELLOW}$PUSH_COUNT${NC} 次推送"
echo -e "⏰ 时间: ${YELLOW}$TIMESTAMP${NC}"
echo -e "🌿 分支: ${GREEN}$BRANCH${NC}"
echo -e "${BLUE}========================================${NC}"

#!/bin/bash

# 进入脚本所在目录
cd "$(dirname "$0")"

# 检查是否为Go模块，如果不是则初始化
if [ ! -f "go.mod" ]; then
    echo "初始化Go模块..."
    go mod init cnb.cool/ysundy/bean/beancount-gs/importer
fi

# 获取依赖
echo "获取依赖..."
go mod tidy

# 构建Beancount导入器
echo "构建Beancount导入器..."
go build -o beancount-importer .

# 检查构建是否成功
if [ $? -eq 0 ]; then
    chmod +x ./beancount-importer
    echo "构建成功！可执行文件已生成: ./beancount-importer"
    echo "使用说明:"
    echo "  ./beancount-importer -csv <csv文件> -rules <规则文件> -output <输出文件>"
else
    echo "构建失败，请检查错误信息"
    exit 1
fi
# 111-venv.go

## 文件概述
`venv.go` 是 beancount-gs 项目中负责虚拟环境命令执行的工具文件。该文件封装了 Python 虚拟环境中的命令执行功能，特别是与 beancount 相关的命令调用。

## 主要功能
1. **虚拟环境命令执行**：在指定虚拟环境中执行命令
2. **beancount 工具调用**：封装 bean-query、bean-check 等命令
3. **fava 服务器启动**：启动 fava 网页服务
4. **路径处理**：自动处理不同操作系统的路径差异

## 关键组件

### 核心结构
- `VenvExecutor`：虚拟环境执行器，封装了虚拟环境中的命令执行功能

### 主要方法
- `Execute()`：执行虚拟环境中的命令
- `ExecuteWithOutput()`：执行命令并捕获输出
- `BeanQueryStdout()`：执行 bean-query 并返回标准输出
- `BeanCheck()`：执行 bean-check 语法检查
- `Fava()`：启动 fava 服务器
- `CheckVenvExists()`：检查虚拟环境是否存在

### 辅助方法
- `GetCommandPath()`：获取虚拟环境中命令的完整路径
- `dirExists()`：检查目录是否存在

## 技术特点
- 支持跨平台路径处理（Windows/Unix）
- 封装了 beancount 相关命令的调用
- 提供标准输出和错误输出的捕获
- 实现虚拟环境存在性检查
- 简洁的命令执行接口

## 应用场景
- 执行 bean-query 查询账本数据
- 使用 bean-check 检查账本语法
- 启动 fava 网页界面查看账本
- 在虚拟环境中执行其他 Python 命令

## 注意事项
- 需要正确配置虚拟环境路径
- 命令执行可能受权限限制
- 跨平台路径处理需要注意系统差异
- 错误输出需要适当处理
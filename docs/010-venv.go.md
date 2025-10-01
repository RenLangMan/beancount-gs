# 010-venv.go

## 文件概述
`venv.go` 是 beancount-gs 项目中负责虚拟环境命令执行的工具文件。该文件实现了虚拟环境执行器，用于在指定的 Python 虚拟环境中执行命令，特别是 beancount 相关的命令（如 bean-query、bean-check、fava 等），是项目与 beancount 工具交互的核心组件。

## 主要功能
1. **虚拟环境命令执行**：在指定虚拟环境中执行命令
2. **命令路径获取**：获取虚拟环境中命令的完整路径
3. **beancount 工具封装**：封装 bean-query、bean-check、fava 等命令
4. **虚拟环境检查**：检查虚拟环境是否存在

## 关键组件

### 结构体
- `VenvExecutor`：虚拟环境执行器
  - `venvPath`：虚拟环境路径

### 主要方法
- `NewVenvExecutor(venvPath string) *VenvExecutor`：创建新的虚拟环境执行器
- `GetCommandPath(command string) (string, error)`：获取虚拟环境中命令的完整路径
- `Execute(command string, args ...string) error`：执行虚拟环境中的命令（输出到标准IO）
- `ExecuteWithOutput(command string, args ...string) ([]byte, []byte, error)`：执行命令并返回输出
- `BeanQueryStdout(beancountFile, query string) ([]byte, error)`：执行 bean-query 命令，只返回纯净的标准输出
- `BeanQuery(beancountFile, query string) ([]byte, error)`：兼容旧代码的 bean-query 执行方法
- `BeanCheck(beancountFile string) error`：执行 bean-check 语法检查
- `Fava(beancountFile string, port int) error`：启动 fava 服务器

### 辅助函数
- `CheckVenvExists(venvPath string) bool`：检查虚拟环境是否存在
- `dirExists(path string) bool`：检查目录是否存在

## 技术特点
- 支持跨平台（Windows 和 Unix-like 系统）
- 使用 Go 标准库的 `os/exec` 包执行命令
- 实现了命令执行的标准输出和错误输出捕获
- 提供了专门的 beancount 工具封装
- 使用文件系统检查确保虚拟环境有效性
- 实现了错误处理和日志记录

## 应用场景
- 执行 bean-query 查询账本数据
- 使用 bean-check 检查账本语法
- 启动 fava 服务器查看账本
- 在指定虚拟环境中执行任意 Python 命令
- 检查虚拟环境是否配置正确

## 注意事项
- 虚拟环境路径需要正确配置
- Windows 和 Unix-like 系统的命令路径结构不同
- 命令执行可能会失败，需要正确处理错误
- bean-query 和 bean-check 需要在虚拟环境中正确安装
- fava 服务器需要指定正确的端口
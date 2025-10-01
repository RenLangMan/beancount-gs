# 001-server.go

## 文件概述
`server.go` 是 beancount-gs 项目的主入口文件，负责初始化服务器、配置路由、启动 Web 服务等核心功能。

## 主要功能
1. **服务器初始化**：初始化虚拟环境执行器、加载服务器配置、创建必要的目录结构
2. **路由注册**：配置 API 路由，包括公开路由和需要授权的路由
3. **授权中间件**：实现基于 ledgerId 的授权验证
4. **服务启动**：启动 Gin Web 服务器，监听指定端口

## 关键组件

### 全局变量
- `venvExecutor`：虚拟环境执行器，用于执行 beancount 命令
- `venvPath`：虚拟环境路径

### 主要函数
- `InitServerFiles()`：初始化服务器文件，检查账本目录是否存在
- `LoadServerCache()`：加载服务器缓存，包括账本配置映射和账户映射
- `AuthorizedHandler()`：授权中间件，验证请求头中的 ledgerId
- `RegisterRouter()`：注册路由，配置静态文件服务、API 路由和需要授权的路由组
- `initVenvExecutor()`：初始化虚拟环境执行器
- `main()`：主函数，程序入口点

### 路由结构
1. **公开 API 路由**：
   - `/api/version`：查询服务版本
   - `/api/check`：检查 beancount 环境
   - `/api/config`：查询/更新服务器配置
   - `/api/ledger`：查询账本列表/打开或创建账本

2. **需要授权的 API 路由**：
   - 账户管理：`/api/auth/account/*`
   - 交易管理：`/api/auth/transaction/*`
   - 统计分析：`/api/auth/stats/*`
   - 文件管理：`/api/auth/file/*`
   - 数据导入：`/api/auth/import/*`
   - 事件管理：`/api/auth/event/*`
   - 标签管理：`/api/auth/tags`

## 技术特点
- 使用 Gin 框架提供 Web 服务
- 支持命令行参数配置（端口、密钥、调试模式等）
- 集成虚拟环境，用于执行 beancount 命令
- 实现日志记录和错误处理机制
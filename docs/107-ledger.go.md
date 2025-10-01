# 107-ledger.go

## 文件概述
`ledger.go` 是 beancount-gs 项目中负责账本管理的服务文件。该文件实现了账本的创建、查询、更新、删除和检查等功能，是项目中账本管理的核心组件。

## 主要功能
1. **账本检查**：检查 beancount 环境是否配置正确
2. **账本查询**：查询服务器配置和账本列表
3. **账本更新**：更新服务器配置
4. **账本创建**：创建新账本
5. **账本删除**：删除指定账本
6. **账本检查**：检查账本语法错误

## 关键组件

### 查询函数
- `CheckBeancount(c *gin.Context)`：检查 beancount 环境
- `QueryServerConfig(c *gin.Context)`：查询服务器配置
- `QueryLedgerList(c *gin.Context)`：查询账本列表

### 账本操作函数
- `UpdateServerConfig(c *gin.Context)`：更新服务器配置
- `OpenOrCreateLedger(c *gin.Context)`：打开或创建账本
- `DeleteLedger(c *gin.Context)`：删除账本
- `CheckLedger(c *gin.Context)`：检查账本语法

### 辅助函数
- `createNewLedger()`：创建新账本
- `initLedgerFiles()`：初始化账本文件
- `copyFile()`：复制账本模板文件

### 数据结构
- `QueryLedgerResult`：账本查询结果结构体
- `LedgerSort`：账本排序类型
- `UpdateConfigForm`：更新配置表单
- `LoginForm`：登录/创建账本表单

## 技术特点
- 使用 Gin 框架处理 HTTP 请求
- 通过 SHA1 生成账本 ID
- 支持账本模板初始化
- 实现了账本缓存管理
- 提供了完整的错误处理和响应机制
- 使用文件操作管理账本数据

## 应用场景
- 检查 beancount 环境配置
- 查询账本列表和配置
- 更新服务器配置
- 创建新账本
- 删除不再使用的账本
- 检查账本语法错误

## 注意事项
- 账本创建需要正确的模板文件
- 账本删除是不可逆操作
- 账本检查依赖于 bean-check 命令
- 账本 ID 是基于名称和密钥生成的哈希值
- 文件操作可能会失败，需要正确处理错误
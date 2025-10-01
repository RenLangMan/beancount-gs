# 101-accounts.go

## 文件概述
`accounts.go` 是 beancount-gs 项目中负责账户管理的服务文件。该文件实现了账户查询、添加、关闭、余额调整等功能，是项目中账户管理的核心组件。

## 主要功能
1. **账户查询**：查询有效账户、所有账户、账户类型
2. **账户管理**：添加账户、关闭账户、添加账户类型
3. **账户余额调整**：调整账户余额
4. **账户图标管理**：更改账户图标
5. **缓存刷新**：刷新账户缓存

## 关键组件

### 查询函数
- `QueryValidAccount(c *gin.Context)`：查询有效账户（未关闭的账户）
- `QueryAllAccount(c *gin.Context)`：查询所有账户及其余额信息
- `QueryAccountType(c *gin.Context)`：查询账户类型

### 账户操作函数
- `AddAccount(c *gin.Context)`：添加新账户
- `CloseAccount(c *gin.Context)`：关闭账户
- `AddAccountType(c *gin.Context)`：添加账户类型
- `BalanceAccount(c *gin.Context)`：调整账户余额
- `ChangeAccountIcon(c *gin.Context)`：更改账户图标
- `RefreshAccountCache(c *gin.Context)`：刷新账户缓存

### 辅助函数
- `multiCurrencies()`：处理多币种账户
- `parseAccountPositions()`：解析账户持仓信息

### 数据结构
- `accountPosition`：账户余额信息结构体
- `AddAccountForm`：添加账户表单
- `AddAccountTypeForm`：添加账户类型表单
- `CloseAccountForm`：关闭账户表单
- `BalanceAccountForm`：调整账户余额表单

## 技术特点
- 使用 Gin 框架处理 HTTP 请求
- 通过 BQL 查询获取账户余额信息
- 支持多币种账户管理
- 实现了账户缓存机制
- 使用正则表达式解析账户持仓信息
- 提供了完整的错误处理和响应机制

## 应用场景
- 展示账户列表和余额
- 添加新账户
- 关闭不再使用的账户
- 调整账户余额
- 管理账户类型
- 更改账户图标
- 刷新账户缓存

## 注意事项
- 账户操作需要正确的账本配置
- 添加账户时需要确保账户名称唯一
- 关闭账户需要指定关闭日期
- 调整账户余额会影响账本数据
- 账户图标需要正确上传
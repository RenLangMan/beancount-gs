# 104-error.go

## 文件概述
`error.go` 是 beancount-gs 项目中负责统一错误处理和响应格式的服务文件。该文件定义了一系列标准化的响应函数，用于在整个项目中保持一致的API响应格式。

## 主要功能
1. **成功响应**：标准化的成功响应格式
2. **错误响应**：各种错误情况的标准化响应
3. **业务错误**：特定业务场景的错误响应

## 关键函数

### 成功响应
- `OK(c *gin.Context, data interface{})`：返回成功的JSON响应，包含数据和状态码200

### 通用错误
- `BadRequest(c *gin.Context, message string)`：返回400错误，表示请求参数错误
- `Unauthorized(c *gin.Context)`：返回401错误，表示未授权
- `InternalError(c *gin.Context, message string)`：返回500错误，表示服务器内部错误

### 业务错误
- `TransactionNotBalance(c *gin.Context)`：返回1001错误，表示交易不平衡
- `LedgerIsNotExist(c *gin.Context)`：返回1006错误，表示账本不存在
- `LedgerIsNotAllowAccess(c *gin.Context)`：返回1006错误，表示账本不允许访问
- `DuplicateAccount(c *gin.Context)`：返回1007错误，表示账户已存在
- `ServerSecretNotMatch(c *gin.Context)`：返回1008错误，表示服务器密钥不匹配

## 技术特点
- 使用 Gin 框架的 JSON 响应功能
- 统一的响应格式：包含状态码、消息和数据
- 简化的错误处理流程
- 支持业务特定的错误代码

## 应用场景
- API 接口的成功响应
- 参数验证失败的错误响应
- 认证和授权失败的错误响应
- 服务器内部错误的响应
- 业务逻辑错误的响应

## 注意事项
- 所有响应都使用 HTTP 状态码 200，实际错误通过自定义状态码区分
- 错误消息需要清晰明确
- 业务错误代码需要保持唯一性
- 成功响应必须包含数据字段
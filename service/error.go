package service

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

// OK 返回成功的JSON响应
// 参数:
//   - c: gin上下文对象
//   - data: 要返回的数据内容
// 响应格式:
//   {"code": 200, "message": "ok", "data": ...}
func OK(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, gin.H{"code": 200, "message": "ok", "data": data})
}

// BadRequest 返回一个400错误响应
// 参数:
//   - c: gin上下文对象
//   - message: 错误信息
// 响应:
//   - 返回JSON格式响应，包含code(400)和message字段
func BadRequest(c *gin.Context, message string) {
	c.JSON(http.StatusOK, gin.H{"code": 400, "message": message})
}

// Unauthorized 返回未授权的错误响应
// 该函数会返回一个状态码为 401 的 JSON 响应
func Unauthorized(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"code": 401})
}

// InternalError 返回一个内部错误响应
// 该函数会设置HTTP状态码为500，并将错误信息以JSON格式返回
// 参数:
//   c *gin.Context: Gin上下文对象
//   message string: 错误信息
func InternalError(c *gin.Context, message string) {
	c.JSON(http.StatusOK, gin.H{"code": 500, "message": message})
}

// TransactionNotBalance 返回交易不平衡的错误响应
// 状态码: 200
// 错误码: 1001
func TransactionNotBalance(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"code": 1001})
}

// LedgerIsNotExist 返回账本不存在的错误响应
// 状态码: 200 (HTTP OK)
// 错误码: 1006 (业务错误码)
func LedgerIsNotExist(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"code": 1006})
}

// LedgerIsNotAllowAccess 返回账本不允许访问的错误响应
// 状态码为 1006，表示当前用户无权访问指定账本
func LedgerIsNotAllowAccess(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"code": 1006})
}

// DuplicateAccount 返回账户重复的错误响应
// 该函数用于处理账户重复的场景，返回预定义的错误码1007
// 响应状态码为200，格式为JSON: {"code": 1007}
func DuplicateAccount(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"code": 1007})
}

// ServerSecretNotMatch 返回服务器密钥不匹配的错误响应
// 状态码: 200 (http.StatusOK)
// 错误码: 1008
func ServerSecretNotMatch(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"code": 1008})
}

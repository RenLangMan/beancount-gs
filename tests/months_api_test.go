/*
 * @Author: liangzai450
 * @Date: 2025-10-06 20:22:45
 * @LastEditors: liangzai450
 * @LastEditTime: 2025-10-06 21:03:56
 * @FilePath: \\beancount-gs\\tests\\months_api_test.go
 * @Description:
 * Copyright (c) 2025 by ${git_name_email}, All Rights Reserved.
 * ==============================================
 */

package tests

import (
	"cnb.cool/ysundy/bean/beancount-gs/script"
	"cnb.cool/ysundy/bean/beancount-gs/service"
	"encoding/json"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestMonthsListAPI(t *testing.T) {
	// 初始化 gin 的测试模式
	gin.SetMode(gin.TestMode)

	// 创建一个 gin 引擎
	r := gin.Default()

	// 模拟 ledgerConfig
	ledgerConfig := &script.Config{
		Id:                "f9d3ea344814ef398e16f2b072ff9c88be8b03d0",
		Mail:              "账本001",
		Title:             "账本001",
		DataPath:          ".\\data\\beancount/f9d3ea344814ef398e16f2b072ff9c88be8b03d0",
		OperatingCurrency: "CNY",
		StartDate:         "2015-01-01",
		IsBak:             true,
		OpeningBalances:   "Equity:Opening-Balances",
		CreateDate:        "2025-09-18",
		DebugMode:         true,
	}

	// 注册路由
	r.GET("/api/auth/stats/months", func(c *gin.Context) {
		// 注入模拟的 ledgerConfig
		c.Set("LedgerConfig", ledgerConfig)

		// 强制设置 mock_bean_query 标志
		c.Set("mock_bean_query", true)
		c.Set("min_date", "2025-01-01")
		c.Set("max_date", "2025-12-31")

		// 模拟虚拟环境执行器
		c.Set("venv_executor", "mock")

		service.MonthsList(c)
	})

	// 创建一个模拟的 HTTP 请求
	req, err := http.NewRequest("GET", "/api/auth/stats/months", nil)
	assert.NoError(t, err)

	// 创建一个 ResponseRecorder 来记录响应
	rr := httptest.NewRecorder()

	// 调用 gin 引擎处理请求
	r.ServeHTTP(rr, req)

	// 检查状态码
	assert.Equal(t, http.StatusOK, rr.Code)

	// 检查返回内容类型
	expectedContentType := "application/json"
	assert.Contains(t, rr.Header().Get("Content-Type"), expectedContentType)

	panic(rr.Body.String())

	// 解析返回的 JSON 数据并验证字段
	var response map[string]interface{}
	err = json.Unmarshal(rr.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, 200, response["code"])
}

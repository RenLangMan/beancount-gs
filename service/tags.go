

/*
 * @Author: liangzai
 * @Date: 2025-10-09 13:24:14
 * @LastEditors: liangzai
 * @LastEditTime: 2025-10-09 16:07:04
 * @FilePath: \\beancount-gs\\service\\tags.go
 * @Description: 
 * Copyright (c) 2025 by ${git_name_email}, All Rights Reserved. 
 * ==============================================
 */

package service

import (
	"fmt"

	"cnb.cool/ysundy/bean/beancount-gs/script"
	"github.com/gin-gonic/gin"
)

type Tags struct {
	Value string `bql:"distinct tags" json:"value"`
}

func QueryTags(c *gin.Context) {
	ledgerConfig := script.GetLedgerConfigFromContext(c)
	tags := make([]Tags, 0)

	// 修正查询参数：只查询非空的 tags 字段
	queryParams := &script.QueryParams{
		Where:      true, // 启用 WHERE 子句
		// 移除错误的 Tag 和 TagNotNull 配置
		// 添加 tags IS NOT NULL 条件
		TagsNotNull: true, // 使用正确的 TagsNotNull 参数
	}

	err := script.BQLQueryList(ledgerConfig, queryParams, &tags)
	if err != nil {
		InternalError(c, err.Error())
		return
	}

	result := make([]string, 0)
	for _, t := range tags {
		if t.Value != "" {
			result = append(result, t.Value)
			// 记录每个标签值
			script.LogDebugDetailed(ledgerConfig.Mail, "TagValue", "标签值: %s", t.Value)
		}
	}

	// 记录最终返回结果
	script.LogDebug(ledgerConfig.Mail, fmt.Sprintf("返回 %d 个标签", len(result)))

	OK(c, result)
}
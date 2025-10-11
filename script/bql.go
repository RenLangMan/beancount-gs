package script

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"reflect"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// handleError 处理错误并根据当前运行模式采取不同的行为：
// - 在调试模式下，触发 panic 并输出错误信息。
// - 在生产环境下，记录警告日志。
//
// 参数：
//
//	err: 需要处理的错误对象。
//	message: 自定义的错误描述信息。
//
// 注意：
//
//	此函数适用于内部错误处理，不对外暴露。
//
//go:noinline
func handleError(err error, message string) {
	if IsDebugMode() {
		panic(fmt.Errorf("%s: %v", message, err))
	} else {
		// 生产环境下记录警告日志
		log.Printf("警告: %s: %v", message, err)
	}
}

/*
QueryParams 结构体定义了查询参数，包含多个字段用于构建查询条件。
每个字段都带有 bql 标签，用于指定在 BQL 查询中的对应字段名。
*/
type QueryParams struct {
	// 日期范围相关字段
	FromYear  int    `bql:"year ="`                 // From 子句中的年份条件
	FromMonth int    `bql:"month ="`                // From 子句中的月份条件
	Year      int    `bql:"year ="`                 // 年份等于条件
	Month     int    `bql:"month ="`                // 月份等于条件
	MinDate   string `bql:"date >=" json:"minDate"` // 最小日期(格式: "YYYY-MM-DD")
	MaxDate   string `bql:"date <=" json:"maxDate"` // 最大日期(格式: "YYYY-MM-DD")

	// 其他查询条件
	Where              bool   `bql:"where"`            // 是否包含 Where 子句
	ID                 string `bql:"id ="`             // ID 等于条件
	IDList             string `bql:"id in"`            // ID 列表条件
	Currency           string `bql:"currency ="`       // 货币等于条件
	Tag                string `bql:"in tags"`          // 用于 tag in tags 条件
	TagsNotNull        bool   `bql:"tags IS NOT NULL"` // 标签非空条件
	Account            string `bql:"account ="`        // 账户等于条件
	AccountLike        string `bql:"account ~"`        // 账户模糊匹配条件
	StrictAccountMatch bool   // true表示账户必须使用精确匹配，false表示使用模糊匹配
	GroupBy            string `bql:"group by"` // 分组条件
	OrderBy            string `bql:"order by"` // 排序条件
	Limit              int    `bql:"limit"`    // 限制结果数量
	Path               string // 查询路径
	Offset             int    // 查询偏移量
}

// HasConditions 检查查询参数是否包含任何条件
// 返回 true 如果 Year, Month, Account, AccountLike, Tag, ID 或 Currency 任一字段不为零值
func (queryParams *QueryParams) HasConditions() bool {
	return queryParams.Year != 0 || queryParams.Month != 0 ||
		queryParams.FromYear != 0 || queryParams.FromMonth != 0 ||
		queryParams.Account != "" || queryParams.AccountLike != "" ||
		queryParams.Tag != "" || queryParams.ID != "" ||
		queryParams.Currency != ""
}

// GetQueryParams 从 gin.Context 中解析查询参数并返回 QueryParams 结构体
// 支持以下查询参数：
//   - year/month: 数值型参数，用于时间范围筛选
//   - tag/account/type/id/idList/currency/path: 字符串型参数
//   - groupBy/orderBy: 分组和排序参数
//   - limit: 限制返回结果数量
//   - strictMode: 布尔值，控制账户匹配模式（精确/模糊）
//
// 默认值：
//   - StrictAccountMatch: true (精确匹配)
//   - OrderBy: "date desc"
//   - Limit: 100
//   - Year/Month: 0 (表示不限制)
//
// 注意：所有参数都会经过有效性检查（非空且不为"undefined"/"null"）
// GetQueryParams 从 gin.Context 中解析查询参数并返回 QueryParams 结构体
// 支持以下查询参数：
//   - year/month: 数值型参数，用于时间范围筛选
//   - tag/account/type/id/idList/currency/path: 字符串型参数
//   - groupBy/orderBy: 分组和排序参数
//   - limit: 限制返回结果数量
//   - strictMode: 布尔值，控制账户匹配模式（精确/模糊）
//
// 默认值：
//   - StrictAccountMatch: true (精确匹配)
//   - OrderBy: "date desc"
//   - Limit: 100
//   - Year/Month: 0 (表示不限制)
//
// 注意：所有参数都会经过有效性检查（非空且不为"undefined"/"null"）
// GetQueryParams 从 gin.Context 中解析查询参数并返回 QueryParams 结构体
// GetQueryParams 从 gin.Context 中解析查询参数并返回 QueryParams 结构体
func GetQueryParams(c *gin.Context) (QueryParams, error) {
	queryParams := QueryParams{
		StrictAccountMatch: true,
		OrderBy:            "date desc",
		Limit:              100,
	}

	// 辅助函数检查有效值
	isValidParam := func(val string) bool {
		return val != "" && val != "undefined" && val != "null" && val != "None"
	}

	// 处理年份参数
	if val := c.Query("year"); isValidParam(val) {
		if num, err := strconv.Atoi(val); err == nil && num > 0 {
			queryParams.Year = num
			DebugLogWithContext("GetQueryParams", "设置有效年份: %d", num)
		} else {
			WarnLogWithContext("GetQueryParams", "无效year参数: %s", val)
		}
	}

	// 处理月份参数
	if val := c.Query("month"); isValidParam(val) {
		if num, err := strconv.Atoi(val); err == nil && num > 0 && num <= 12 {
			queryParams.Month = num
			DebugLogWithContext("GetQueryParams", "设置有效月份: %d", num)
		} else {
			WarnLogWithContext("GetQueryParams", "无效month参数: %s", val)
		}
	}

	// 处理From年份参数
	if val := c.Query("fromYear"); isValidParam(val) {
		if num, err := strconv.Atoi(val); err == nil && num > 0 {
			queryParams.FromYear = num
		}
	}

	// 处理From月份参数
	if val := c.Query("fromMonth"); isValidParam(val) {
		if num, err := strconv.Atoi(val); err == nil && num > 0 && num <= 12 {
			queryParams.FromMonth = num
		}
	}

	// 字符串条件
	setStringParam := func(param *string, queryKey string) {
		if val := c.Query(queryKey); isValidParam(val) {
			*param = val
			DebugLogWithContext("GetQueryParams", "设置%s: %s", queryKey, val)
		}
	}

	// 处理其他字符串参数
	setStringParam(&queryParams.Tag, "tag")
	setStringParam(&queryParams.Account, "account")
	setStringParam(&queryParams.ID, "id")
	setStringParam(&queryParams.IDList, "idList")
	setStringParam(&queryParams.Currency, "currency")
	setStringParam(&queryParams.Path, "path")
	setStringParam(&queryParams.GroupBy, "groupBy")

	// 特殊处理type参数
	if accType := c.Query("type"); isValidParam(accType) {
		queryParams.AccountLike = accType
		queryParams.StrictAccountMatch = false
		DebugLogWithContext("GetQueryParams", "设置账户类型(模糊匹配): %s", accType)
	}

	// 处理orderBy参数（必须覆盖默认值）
	if orderBy := c.Query("orderBy"); isValidParam(orderBy) {
		queryParams.OrderBy = orderBy
	}

	// 处理limit参数（必须覆盖默认值）
	if limitStr := c.Query("limit"); isValidParam(limitStr) {
		if limit, err := strconv.Atoi(limitStr); err == nil && limit > 0 {
			queryParams.Limit = limit
		}
	}

	// 计算日期范围
	queryParams.CalculateDateRange()

	// 设置Where条件
	queryParams.Where = queryParams.HasConditions()

	return queryParams, nil
}

// CalculateDateRange 计算日期范围的辅助方法（优化版）
func (q *QueryParams) CalculateDateRange() {

	if IsDebugMode() {
		// 将QueryParams结构体转换为JSON格式的字符串}
		jsonData, _ := json.MarshalIndent(q, "", "  ")
		fmt.Printf("\n=== CalculateDateRange计算日期范围传入的QueryParams ===\n")
		fmt.Println(string(jsonData))
		fmt.Println("=====================================")
	}

	loc := time.Local // 使用本地时区
	q.MinDate = ""
	q.MaxDate = ""

	// 使用switch判断日期范围模式
	switch {
	// 模式1：处理 fromYear/fromMonth 到 toYear/toMonth 的日期范围
	case q.FromYear > 0:
		DebugLogWithContext("CalculateDateRange", "模式1：处理 fromYear/fromMonth 到 toYear/toMonth 的日期范围,传入参数：起始年份：%d,起始月份：%d,结束年份：%d,结束月份：%d", q.FromYear, q.FromMonth, q.Year, q.Month)
		startMonth := 1
		if q.FromMonth > 0 {
			startMonth = q.FromMonth
		}
		minDate := time.Date(q.FromYear, time.Month(startMonth), 1, 0, 0, 0, 0, loc)
		q.MinDate = minDate.Format("2006-01-02")
		DebugLogWithContext("CalculateDateRange", "模式1：处理 fromYear/fromMonth 到 toYear/toMonth 的日期范围,计算起始日期：%s", q.MinDate)

		// 如果没有设置结束年份，使用开始年份
		endYear := q.FromYear
		if q.Year > 0 {
			endYear = q.Year
		}
		endMonth := 12
		if q.Month > 0 {
			endMonth = q.Month
		}
		maxDate := time.Date(endYear, time.Month(endMonth), 31, 23, 59, 59, 0, loc)
		q.MaxDate = maxDate.Format("2006-01-02")

		q.FromYear = minDate.Year()
		q.FromMonth = int(minDate.Month())
		q.Year = maxDate.Year()
		q.Month = int(maxDate.Month())

	// 模式2：处理 year/month 的日期范围
	case q.Year > 0:
		// 设置开始日期
		startMonth := 1
		if q.Month > 0 {
			startMonth = q.Month
		}
		minDate := time.Date(q.Year, time.Month(startMonth), 1, 0, 0, 0, 0, loc)
		q.MinDate = minDate.Format("2006-01-02")

		// 设置结束日期
		endMonth := 12
		if q.Month > 0 {
			endMonth = q.Month
		}
		maxDate := time.Date(q.Year, time.Month(endMonth), 1, 0, 0, 0, 0, loc).
			AddDate(0, 1, -1).Add(23*time.Hour + 59*time.Minute + 59*time.Second)
		q.MaxDate = maxDate.Format("2006-01-02")

		q.FromYear = minDate.Year()
		q.FromMonth = int(minDate.Month())
		q.Year = maxDate.Year()
		q.Month = int(maxDate.Month())

	// 默认情况（可选）
	default:
		// 默认查询最近一个月
		if q.MinDate == "" || q.MaxDate == "" {

			// 获取当前时间
			now := time.Now()

			// 计算上月1号
			firstOfLastMonth := time.Date(now.Year(), now.Month()-1, 1, 0, 0, 0, 0, now.Location())

			// 计算本月末（下月1号的前一天）
			lastOfThisMonth := time.Date(now.Year(), now.Month()+1, 1, 0, 0, 0, 0, now.Location()).AddDate(0, 0, -1)

			// 设置日期范围
			q.MinDate = firstOfLastMonth.Format("2006-01-02")
			q.MaxDate = lastOfThisMonth.Format("2006-01-02")

			q.FromYear = firstOfLastMonth.Year()
			q.FromMonth = int(firstOfLastMonth.Month())
			q.Year = lastOfThisMonth.Year()
			q.Month = int(lastOfThisMonth.Month())
		}
	}
}

//func BQLQueryOne(ledgerConfig *Config, queryParams *QueryParams, queryResultPtr interface{}) error {
//	assertQueryResultIsPointer(queryResultPtr)
//	output, err := bqlRawQuery(ledgerConfig, "", queryParams, queryResultPtr)
//	if err != nil {
//		return err
//	}
//	err = parseResult(output, queryResultPtr, true)
//	if err != nil {
//		return err
//	}
//	return nil
//}

func BQLPrint(ledgerConfig *Config, transactionId string) (string, error) {
	// PRINT FROM id = 'xxx'
	output, err := queryByBQL(ledgerConfig, "PRINT FROM id = '"+transactionId+"'")
	if err != nil {
		return "", err
	}
	utf8, err := ConvertGBKToUTF8(output)
	if err != nil {
		return "", err
	}
	return utf8, nil
}

// BQLQueryList 执行BQL查询并将结果解析到指定的指针中
//
// 参数:
//
//	ledgerConfig: 账本配置信息
//	queryParams: 查询参数
//	queryResultPtr: 指向查询结果容器的指针，必须是指针类型
//
// 返回值:
//
//	error: 如果查询或解析过程中发生错误，返回错误信息
//
// 注意:
//  1. 函数内部包含详细的调试日志，可通过调试模式控制
//  2. queryResultPtr 必须是指针类型，否则会触发断言错误
//  3. 输出结果会被自动解析到queryResultPtr指向的变量中
func BQLQueryList(ledgerConfig *Config, queryParams *QueryParams, queryResultPtr interface{}) error {
	// 调试模式设置，默认为true（开启调试模式）

	// 调试信息：函数开始执行
	LogDebugDetailed(ledgerConfig.Mail, "BQLQueryList",
		"函数开始执行\n----------------------\n输入查询参数: %+v\n----------------------\nqueryResultPtr 类型: %T",
		queryParams, queryResultPtr)

	assertQueryResultIsPointer(queryResultPtr)

	// 调试信息：执行bqlRawQuery前
	LogDebugDetailed(ledgerConfig.Mail, "BQLQuery",
		"正在执行 bqlRawQuery...")

	output, err := bqlRawQuery(ledgerConfig, "", queryParams, queryResultPtr)

	// 调试信息：bqlRawQuery执行结果
	if err != nil {
		LogError(ledgerConfig.Mail,
			fmt.Sprintf("bqlRawQuery执行失败: %v", err))
		return fmt.Errorf("BQL查询失败: %v", err)
	} else {
		// 限制输出长度，避免日志过大
		outputPreview := output
		if len(output) > 500 {
			outputPreview = output[:500] + "... (输出被截断)"
		}
		LogDebugDetailed(ledgerConfig.Mail, "BQLQuery",
			"bqlRawQuery执行成功，输出预览: %s", outputPreview)
	}

	// 调试信息：执行parseResult前
	LogDebugDetailed(ledgerConfig.Mail, "BQLQuery",
		"正在使用parseResult解析查询结果...")

	parseErr := parseResult(output, queryResultPtr, false)

	// 调试信息：parseResult执行结果
	if parseErr != nil {
		const parseErrorFormat = "parseResult解析失败: %v"
		LogDebugDetailed(ledgerConfig.Mail, "BQLParse", parseErrorFormat, parseErr)
	} else {
		resultValue := reflect.ValueOf(queryResultPtr).Elem()
		const successLog1 = "parseResult解析成功"
		const typeLog = "结果类型: %s"
		const kindLog = "种类: %s"

		LogDebugDetailed(ledgerConfig.Mail, "BQLParse", successLog1)
		LogDebugDetailed(ledgerConfig.Mail, "BQLParse", typeLog, resultValue.Type().String())
		LogDebugDetailed(ledgerConfig.Mail, "BQLParse", kindLog, resultValue.Kind().String())

		if resultValue.Kind() == reflect.Slice {
			const sliceLenLog = "结果包含 %d 个项目"
			LogDebugDetailed(ledgerConfig.Mail, "BQLParse", sliceLenLog, resultValue.Len())
		}
	}

	return parseErr
}

func BQLQueryListByCustomSelect(ledgerConfig *Config, selectBql string, queryParams *QueryParams, queryResultPtr interface{}) error {
	const contextTag = "QueryListByCustomSelect"

	// 调试信息：函数开始执行
	LogBQLQueryDebug(ledgerConfig.Mail, contextTag,
		"函数开始执行\n自定义 selectBql: %s\n输入查询参数: %+v\nqueryResultPtr 类型: %T",
		selectBql, queryParams, queryResultPtr)

	assertQueryResultIsPointer(queryResultPtr)

	// 调试信息：执行bqlRawQuery前
	LogBQLQueryDebug(ledgerConfig.Mail, contextTag, "正在执行 bqlRawQuery...")

	output, err := bqlRawQuery(ledgerConfig, selectBql, queryParams, queryResultPtr)

	// 调试信息：bqlRawQuery执行结果
	if err != nil {
		LogBQLQueryDebug(ledgerConfig.Mail, contextTag, "bqlRawQuery 执行失败: %v", err)
	} else {
		// 限制输出长度，避免日志过大
		outputPreview := output
		if len(output) > 500 {
			outputPreview = output[:500] + "... (输出被截断)"
		}
		LogBQLQueryDebug(ledgerConfig.Mail, contextTag,
			"bqlRawQuery 执行成功，输出预览: %s", outputPreview)
	}

	if err != nil {
		errorMsg := fmt.Sprintf("BQL:%s - 自定义 BQL 查询失败: %v", contextTag, err)
		LogError(ledgerConfig.Mail, errorMsg)
		return fmt.Errorf("自定义 BQL 查询失败: %v", err)
	}

	// 调试信息：执行parseResult前
	LogBQLQueryDebug(ledgerConfig.Mail, contextTag, "正在调用parseResult解析查询结果...")

	parseErr := parseResult(output, queryResultPtr, false)

	// 调试信息：parseResult执行结果
	if parseErr != nil {
		LogBQLQueryDebug(ledgerConfig.Mail, contextTag, "parseResult 解析失败: %v", parseErr)
	} else {
		resultValue := reflect.ValueOf(queryResultPtr).Elem()
		LogBQLQueryDebug(ledgerConfig.Mail, contextTag,
			"parseResult 解析成功\n结果类型: %s\n种类: %s",
			resultValue.Type().String(), resultValue.Kind().String())

		if resultValue.Kind() == reflect.Slice {
			LogBQLQueryDebug(ledgerConfig.Mail, contextTag,
				"结果包含 %d 个项目", resultValue.Len())
		}
	}

	return parseErr
}

// 修改后的bqlRawQuery函数
func bqlRawQuery(ledgerConfig *Config, selectBql string, queryParamsPtr *QueryParams, queryResultPtr interface{}) (string, error) {
	LogDebugDetailed(ledgerConfig.Mail, "BQLBuilder",
		"=== 开始构建BQL查询 ===\n输入参数: selectBql='%s'\nqueryParamsPtr=%+v",
		selectBql, queryParamsPtr)

	// 1. 构建SELECT部分
	selectPart, err := buildSelectPart(selectBql, queryResultPtr, ledgerConfig)
	if err != nil {
		return "", err
	}

	// 2. 构建WHERE条件
	wherePart, err := buildWherePart(queryParamsPtr, ledgerConfig)
	if err != nil {
		return "", err
	}

	// 3. 构建GROUP BY部分
	groupByPart := buildGroupByPart(queryParamsPtr, ledgerConfig)

	// 4. 构建ORDER BY部分
	orderByPart := buildOrderByPart(queryParamsPtr, ledgerConfig)

	// 5. 构建LIMIT部分
	limitPart := buildLimitPart(queryParamsPtr, ledgerConfig)

	// 组合完整查询
	finalQuery := strings.Join([]string{
		selectPart,
		wherePart,
		groupByPart,
		orderByPart,
		limitPart,
	}, " ")

	// 验证SQL语法
	if err := validateSQL(finalQuery); err != nil {
		LogError(ledgerConfig.Mail, "SQL验证失败: "+err.Error())
		return "", err
	}

	LogDebugDetailed(ledgerConfig.Mail, "BQLGenerator",
		"=== 最终生成的BQL ===\n%s", finalQuery)
	return queryByBQL(ledgerConfig, finalQuery)
}

// 构建SELECT部分
func buildSelectPart(selectBql string, queryResultPtr interface{}, ledgerConfig *Config) (string, error) {
	if selectBql != "" {
		return selectBql, nil
	}

	queryResultPtrType := reflect.TypeOf(queryResultPtr)
	queryResultType := queryResultPtrType.Elem()
	if queryResultType.Kind() == reflect.Slice {
		queryResultType = queryResultType.Elem()
	}

	var fields []string
	for i := 0; i < queryResultType.NumField(); i++ {
		typeField := queryResultType.Field(i)
		if b := typeField.Tag.Get("bql"); b != "" {
			if strings.Contains(b, "distinct") {
				b = strings.ReplaceAll(b, "distinct", "")
				fields = append(fields, "DISTINCT "+b)
			} else {
				fields = append(fields, b)
			}
			fields = append(fields, "'\\'")
		}
	}

	if len(fields) == 0 {
		return "", fmt.Errorf("没有可用的查询字段")
	}

	return "SELECT " + strings.Join(fields, ", "), nil
}

// 构建WHERE条件
func buildWherePart(queryParamsPtr *QueryParams, ledgerConfig *Config) (string, error) {
	if queryParamsPtr == nil || !queryParamsPtr.HasConditions() {
		return "", nil
	}

	if !queryParamsPtr.Where {
		DebugLogWithContext("QueryListByCustomSelect", "没有启用WHERE条件", queryParamsPtr)
		return "", nil
	}

	if err := validateQueryParams(queryParamsPtr); err != nil {
		return "", err
	}

	var conditions []string

	// 日期条件构建
	dateCondition := buildDateCondition(queryParamsPtr, ledgerConfig)
	if dateCondition != "" {
		conditions = append(conditions, dateCondition)
	}

	// 其他条件保持不变
	if queryParamsPtr.Account != "" {
		conditions = append(conditions,
			fmt.Sprintf("account = '%s'", escapeSQLString(queryParamsPtr.Account)))
	} else if queryParamsPtr.AccountLike != "" {
		conditions = append(conditions,
			fmt.Sprintf("account ~ '%s'", escapeSQLString(queryParamsPtr.AccountLike)))
	}

	if queryParamsPtr.Tag != "" {
		conditions = append(conditions, "tag in tags")
	}
	if queryParamsPtr.TagsNotNull {
		conditions = append(conditions, "tags IS NOT NULL")
	}
	if queryParamsPtr.ID != "" {
		conditions = append(conditions,
			fmt.Sprintf("id = '%s'", escapeSQLString(queryParamsPtr.ID)))
	}

	if len(conditions) == 0 {
		return "", nil
	}

	return "WHERE " + strings.Join(conditions, " AND "), nil
}

// 改进的日期条件构建函数
func buildDateCondition(params *QueryParams, ledgerConfig *Config) string {
	var conditions []string

	// 1. 处理显式指定的日期范围（最高优先级）
	if params.MinDate != "" || params.MaxDate != "" {
		if params.MinDate != "" {
			conditions = append(conditions, fmt.Sprintf("date >= %s", params.MinDate))
		}
		if params.MaxDate != "" {
			conditions = append(conditions, fmt.Sprintf("date <= %s", params.MaxDate))
		}
		return strings.Join(conditions, " AND ")
	}

	// 2. 处理FromYear/FromMonth条件（中优先级）
	if params.FromYear > 0 || params.FromMonth > 0 {
		if params.FromYear > 0 && params.FromMonth > 0 {
			conditions = append(conditions,
				fmt.Sprintf("(year > %d OR (year = %d AND month >= %d))",
					params.FromYear, params.FromYear, params.FromMonth))
		} else if params.FromYear > 0 {
			conditions = append(conditions, fmt.Sprintf("year >= %d", params.FromYear))
		} else {
			conditions = append(conditions, fmt.Sprintf("month >= %d", params.FromMonth))
		}
	}

	// 3. 处理Year/Month条件（低优先级）
	if params.Year > 0 {
		conditions = append(conditions, fmt.Sprintf("year = %d", params.Year))
	}
	if params.Month > 0 {
		conditions = append(conditions, fmt.Sprintf("month = %d", params.Month))
	}

	// 4. 应用默认日期范围限制（无其他条件时）
	if len(conditions) == 0 {
		// 获取账本日期范围
		startDate := ledgerConfig.StartDate
		endDate := time.Now().Format("2006-01-02")

		conditions = append(conditions,
			fmt.Sprintf("date >= %s AND date <= %s", startDate, endDate))
	}

	if len(conditions) == 0 {
		return ""
	}

	return "(" + strings.Join(conditions, " AND ") + ")"
}

// 构建GROUP BY部分
func buildGroupByPart(queryParamsPtr *QueryParams, ledgerConfig *Config) string {
	if queryParamsPtr == nil || queryParamsPtr.GroupBy == "" {
		return ""
	}
	return "GROUP BY " + queryParamsPtr.GroupBy
}

// 构建ORDER BY部分
func buildOrderByPart(queryParamsPtr *QueryParams, ledgerConfig *Config) string {
	if queryParamsPtr == nil || queryParamsPtr.OrderBy == "" {
		return ""
	}
	// 清理排序字段
	orderBy := strings.ReplaceAll(queryParamsPtr.OrderBy, "'", "")
	orderBy = strings.ReplaceAll(orderBy, "\"", "")
	orderBy = strings.ReplaceAll(strings.ToLower(orderBy), "order by", "")
	orderBy = strings.TrimSpace(orderBy)
	return "ORDER BY " + orderBy
}

// 构建LIMIT部分
func buildLimitPart(queryParamsPtr *QueryParams, ledgerConfig *Config) string {
	if queryParamsPtr == nil || queryParamsPtr.Limit <= 0 {
		return ""
	}
	return "LIMIT " + strconv.Itoa(queryParamsPtr.Limit)
}

// 验证查询参数
func validateQueryParams(queryParamsPtr *QueryParams) error {
	if queryParamsPtr.Account != "" && queryParamsPtr.AccountLike != "" {
		return fmt.Errorf("不能同时指定Account和AccountLike参数")
	}
	if queryParamsPtr.StrictAccountMatch && queryParamsPtr.AccountLike != "" {
		return fmt.Errorf("StrictAccountMatch模式下不能使用AccountLike")
	}
	if !queryParamsPtr.StrictAccountMatch && queryParamsPtr.Account != "" {
		return fmt.Errorf("非StrictAccountMatch模式下必须指定AccountLike")
	}
	return nil
}

// 验证SQL语法
func validateSQL(query string) error {
	if strings.Contains(query, "WHERE  AND") {
		return fmt.Errorf("无效的WHERE条件")
	}
	if strings.Contains(query, "WHERE") && strings.Contains(query, "GROUP BY") {
		if strings.Index(query, "WHERE") > strings.Index(query, "GROUP BY") {
			return fmt.Errorf("SQL语法错误: WHERE子句必须在GROUP BY之前")
		}
	}
	return nil
}

// 辅助函数：安全转义 SQL 字符串
func escapeSQLString(s string) string {
	// 只转义单引号，不处理反斜杠
	return strings.ReplaceAll(s, "'", "''")
}

// 修改 BeanReportAllPrices 函数
func BeanReportAllPrices(ledgerConfig *Config) []CommodityPrice {
	// 使用正确的 BQL 查询，不需要 FROM 子句
	output, err := queryByBQL(ledgerConfig,
		"SELECT date, 'price', currency, price WHERE price is not NULL")
	if err != nil {
		LogError(ledgerConfig.Mail, "Failed to query prices: "+err.Error())
		return nil
	}

	// 解析 CSV 输出
	reader := csv.NewReader(strings.NewReader(output))
	records, err := reader.ReadAll()
	if err != nil {
		LogError(ledgerConfig.Mail, "Failed to parse CSV: "+err.Error())
		return nil
	}

	// 将 [][]string 转换为 []string
	var lines []string
	if len(records) > 0 {
		// 跳过标题行
		for _, record := range records[1:] {
			lines = append(lines, strings.Join(record, " "))
		}
	}

	return newCommodityPriceListFromString(lines)
}

// 修改 parseResult 函数中的相关部分
// func parseCsvResult(output string, queryResultPtr interface{}, selectOne bool) error {
// 	queryResultPtrType := reflect.TypeOf(queryResultPtr)
// 	queryResultType := queryResultPtrType.Elem()

// 	if queryResultType.Kind() == reflect.Slice {
// 		queryResultType = queryResultType.Elem()
// 	}

// 	// 使用 csv 解析器处理输出
// 	reader := csv.NewReader(strings.NewReader(output))
// 	records, err := reader.ReadAll()
// 	if err != nil {
// 		return err
// 	}

// 	// 跳过标题行
// 	if len(records) > 0 {
// 		records = records[1:]
// 	}

// 	if selectOne && len(records) > 0 {
// 		records = records[:1]
// 	}

// 	l := make([]map[string]interface{}, 0)
// 	for _, record := range records {
// 		if len(record) == 0 {
// 			continue
// 		}

// 		temp := make(map[string]interface{})
// 		for i, val := range record {
// 			if i >= queryResultType.NumField() {
// 				continue
// 			}

// 			field := queryResultType.Field(i)
// 			jsonName := field.Tag.Get("json")
// 			if jsonName == "" {
// 				jsonName = field.Name
// 			}

// 			val = strings.TrimSpace(val)
// 			if val == "" {
// 				continue
// 			}

// 			switch field.Type.Kind() {
// 			case reflect.Int, reflect.Int32:
// 				if i, err := strconv.Atoi(val); err == nil {
// 					temp[jsonName] = i
// 				}
// 			case reflect.String:
// 				temp[jsonName] = val
// 			case reflect.Float32, reflect.Float64:
// 				if f, err := strconv.ParseFloat(val, 64); err == nil {
// 					temp[jsonName] = f
// 				}
// 			case reflect.Array, reflect.Slice:
// 				strArray := strings.Split(val, ",")
// 				notBlanks := make([]string, 0)
// 				for _, s := range strArray {
// 					if s = strings.TrimSpace(s); s != "" {
// 						notBlanks = append(notBlanks, s)
// 					}
// 				}
// 				if len(notBlanks) > 0 {
// 					temp[jsonName] = notBlanks
// 				}
// 			}
// 		}
// 		if len(temp) > 0 {
// 			l = append(l, temp)
// 		}
// 	}

// 	var jsonBytes []byte
// 	var jsonErr error // 修改变量名，避免重复声明
// 	if selectOne && len(l) > 0 {
// 		jsonBytes, jsonErr = json.Marshal(l[0])
// 	} else {
// 		jsonBytes, jsonErr = json.Marshal(l)
// 	}
// 	if jsonErr != nil {
// 		return jsonErr
// 	}
// 	err = json.Unmarshal(jsonBytes, queryResultPtr) // 使用外层的 err
// 	if err != nil {
// 		return err
// 	}
// 	return nil
// }

// 原v2版本格式数据导入函数
// 主解析函数 - 智能识别格式
func parseResult(output string, queryResultPtr interface{}, selectOne bool) error {

	lines := strings.Split(strings.TrimSpace(output), "\n")
	if len(lines) == 0 {
		return nil // 空输出
	}

	// 检测格式类型
	isCustomFormat := false
	for _, line := range lines {
		if strings.Contains(line, "\\") || strings.Contains(line, "'") {
			isCustomFormat = true
			break
		}
		if IsDebugMode() {
			log.Printf("line: %s", line)
			log.Println("isCustomFormat:", isCustomFormat)
		}
	}

	if isCustomFormat {
		if IsDebugMode() {
			log.Println("使用自定义分隔符//解析逻辑")
		}
		// 使用自定义分隔符解析逻辑
		return parseCustomFormat(output, queryResultPtr, selectOne)
	} else {
		if IsDebugMode() {
			log.Println("使用表格格式解析逻辑")
		}
		// 使用表格格式解析逻辑
		return parseTableFormat(output, queryResultPtr, selectOne)
	}
}

// 解析自定义分隔符格式（原v2格式）
func parseCustomFormat(output string, queryResultPtr interface{}, selectOne bool) error {
	queryResultPtrType := reflect.TypeOf(queryResultPtr)
	queryResultType := queryResultPtrType.Elem()

	if queryResultType.Kind() == reflect.Slice {
		queryResultType = queryResultType.Elem()
	}

	lines := strings.Split(output, "\n")

	// 跳过标题行（如果有）
	var dataLines []string
	if len(lines) >= 3 && strings.Contains(lines[1], "-") {
		dataLines = lines[2:] // 跳过前2行（标题和分隔线）
	} else {
		dataLines = lines // 没有标准标题格式
	}

	l := make([]map[string]interface{}, 0)
	for _, line := range dataLines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		values := strings.Split(line, "\\")

		// 安全地去除首尾空元素
		var cleanedValues []string
		for _, val := range values {
			trimmed := strings.TrimSpace(val)
			if trimmed != "" {
				cleanedValues = append(cleanedValues, trimmed)
			}
		}

		// 如果cleanedValues为空，跳过这行
		if len(cleanedValues) == 0 {
			continue
		}

		temp := make(map[string]interface{})
		for i, val := range cleanedValues {
			if i >= queryResultType.NumField() {
				break // 跳过多余的字段
			}

			field := queryResultType.Field(i)
			jsonName := field.Tag.Get("json")
			if jsonName == "" {
				jsonName = field.Name
			}

			val = strings.TrimSpace(val)
			if val == "" {
				continue
			}

			// 添加tags/payee字段的专门调试
			if jsonName == "tags" && IsDebugMode() {
				DebugLogWithContext("TAGS", "解析tags字段值: %s", val)
			}
			if jsonName == "payee" && IsDebugMode() {
				// DebugLogWithContext("PAYEE", "解析payee字段值: %s", val)
			}

			switch field.Type.Kind() {
			case reflect.Int, reflect.Int32:
				if intVal, err := strconv.Atoi(val); err != nil {
					handleError(err, fmt.Sprintf("解析整数值 '%s' 失败", val))
				} else {
					temp[jsonName] = intVal
				}
			case reflect.String, reflect.Struct:
				temp[jsonName] = val
			case reflect.Array, reflect.Slice:
				strArray := strings.Split(val, ",")
				notBlanks := make([]string, 0)
				for _, s := range strArray {
					if trimmed := strings.TrimSpace(s); trimmed != "" {
						notBlanks = append(notBlanks, trimmed)
					}
				}
				if len(notBlanks) > 0 {
					temp[jsonName] = notBlanks
				}
			default:
				if IsDebugMode() {
					panic(fmt.Sprintf("Unsupported field type: %s", field.Type.Kind()))
				}
			}
		}

		if len(temp) > 0 {
			l = append(l, temp)
		}
	}

	return marshalAndUnmarshal(l, queryResultPtr, selectOne)
}

// 解析表格格式（bean-query默认格式）
func parseTableFormat(output string, queryResultPtr interface{}, selectOne bool) error {
	queryResultPtrType := reflect.TypeOf(queryResultPtr)
	queryResultType := queryResultPtrType.Elem()

	if queryResultType.Kind() == reflect.Slice {
		queryResultType = queryResultType.Elem()
	}

	lines := strings.Split(strings.TrimSpace(output), "\n")

	// 检测并跳过标题行和分隔线
	var dataLines []string
	if len(lines) >= 3 && strings.Contains(lines[1], "-") {
		dataLines = lines[2:] // 跳过前2行
	} else if len(lines) >= 2 && strings.Contains(lines[0], "|") {
		dataLines = lines[1:] // 跳过标题行
	} else {
		dataLines = lines // 没有标准标题
	}

	l := make([]map[string]interface{}, 0)
	for _, line := range dataLines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		// 按 | 分割表格格式
		values := strings.Split(line, "|")
		var cleanedValues []string
		for _, val := range values {
			trimmed := strings.TrimSpace(val)
			if trimmed != "" {
				cleanedValues = append(cleanedValues, trimmed)
			}
		}

		if len(cleanedValues) == 0 {
			continue
		}

		temp := make(map[string]interface{})
		for i, val := range cleanedValues {
			if i >= queryResultType.NumField() {
				break
			}

			field := queryResultType.Field(i)
			jsonName := field.Tag.Get("json")
			if jsonName == "" {
				jsonName = field.Name
			}

			val = strings.TrimSpace(val)
			if val == "" {
				continue
			}

			switch field.Type.Kind() {
			case reflect.Int, reflect.Int32:
				if intVal, err := strconv.Atoi(val); err != nil {
					handleError(err, fmt.Sprintf("解析整数值 '%s' 失败", val))
				} else {
					temp[jsonName] = intVal
				}
			case reflect.String, reflect.Struct:
				temp[jsonName] = val
			case reflect.Float32, reflect.Float64:
				if floatVal, err := strconv.ParseFloat(val, 64); err != nil {
					handleError(err, fmt.Sprintf("解析浮点数值 '%s' 失败", val))
				} else {
					temp[jsonName] = floatVal
				}
			case reflect.Array, reflect.Slice:
				strArray := strings.Split(val, ",")
				notBlanks := make([]string, 0)
				for _, s := range strArray {
					if trimmed := strings.TrimSpace(s); trimmed != "" {
						notBlanks = append(notBlanks, trimmed)
					}
				}
				if len(notBlanks) > 0 {
					temp[jsonName] = notBlanks
				}
			default:
				if IsDebugMode() {
					panic(fmt.Sprintf("Unsupported field type: %s", field.Type.Kind()))
				}
			}
		}

		if len(temp) > 0 {
			l = append(l, temp)
		}
	}

	return marshalAndUnmarshal(l, queryResultPtr, selectOne)
}

// 通用的JSON序列化和反序列化
// 通用的JSON序列化和反序列化
func marshalAndUnmarshal(data []map[string]interface{}, queryResultPtr interface{}, selectOne bool) error {
	if len(data) == 0 {
		// 对于空结果，设置默认值
		if selectOne {
			if IsDebugMode() {
				panic("selectOne 查询没有找到结果")
			}
			return fmt.Errorf("selectOne 查询没有找到结果")
		}
		// 对于切片，返回空切片是合理的
	}

	var jsonBytes []byte
	var err error

	if selectOne {
		if len(data) == 0 {
			if IsDebugMode() {
				panic("selectOne 查询没有找到结果")
			}
			return fmt.Errorf("selectOne 查询没有找到结果")
		}
		jsonBytes, err = json.Marshal(data[0])
	} else {
		jsonBytes, err = json.Marshal(data)
	}

	if err != nil {
		handleError(err, "JSON 序列化失败")
		return err
	}

	err = json.Unmarshal(jsonBytes, queryResultPtr)
	if err != nil {
		handleError(err, "JSON 反序列化失败")
		return err
	}

	return nil
}

// 直接调用v3版本的bean-query命令，返回beancount专用表格格式
func queryByBQL(ledgerConfig *Config, bql string) (string, error) {
	beanFilePath := ledgerConfig.DataPath + "/index.bean"
	LogInfo(ledgerConfig.Mail, fmt.Sprintf("[BQLExecution] 查询语句: %s", bql))

	// 获取虚拟环境执行器
	executor := GetVenvExecutor()
	if executor == nil {
		// 降级方案：使用原来的逻辑但修复路径
		return queryByBQLFallback(beanFilePath, bql)
	}

	// 使用虚拟环境工具执行 bean-query
	output, err := executor.BeanQueryStdout(beanFilePath, bql)
	if err != nil {
		errorMsg := fmt.Sprintf("bean-query执行失败 - 错误详情: %v", err)
		LogError(ledgerConfig.Mail, errorMsg)
		return "", fmt.Errorf("bean-query 执行失败: %v", err)
	}
	return string(output), nil
}

// 降级方案，确保即使虚拟环境工具有问题也能工作
func queryByBQLFallback(beanFilePath, bql string) (string, error) {
	var cmdPath string
	if runtime.GOOS == "windows" {
		cmdPath = "/workspace/.env_beancount-v3/Scripts/bean-query.exe"
	} else {
		cmdPath = "/workspace/.env_beancount-v3/bin/bean-query"
	}

	// 检查文件是否存在
	if _, err := os.Stat(cmdPath); os.IsNotExist(err) {
		return "", fmt.Errorf("bean-query 未找到: %s", cmdPath)
	}

	cmd := exec.Command(cmdPath, beanFilePath, bql)
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("bean-query 执行错误: %v", err)
	}
	return string(output), nil
}

func assertQueryResultIsPointer(queryResult interface{}) {
	k := reflect.TypeOf(queryResult).Kind()
	if k != reflect.Ptr {
		panic("QueryResult 类型必须是指针，当前是 " + k.String())
	}
}

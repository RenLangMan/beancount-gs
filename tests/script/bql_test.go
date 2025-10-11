package script_test

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"testing"
	"time"

	"cnb.cool/ysundy/bean/beancount-gs/script"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

// 测试QueryParams的HasConditions方法
func TestQueryParams_判断是否有查询条件(t *testing.T) {
	tests := []struct {
		name   string
		params script.QueryParams
		want   bool
	}{
		{
			name:   "空参数",
			params: script.QueryParams{},
			want:   false,
		},
		{
			name: "有年份参数",
			params: script.QueryParams{
				Year: 2023,
			},
			want: true,
		},
		{
			name: "有月份参数",
			params: script.QueryParams{
				Month: 12,
			},
			want: true,
		},
		{
			name: "有账户参数",
			params: script.QueryParams{
				Account: "Assets",
			},
			want: true,
		},
		{
			name: "有账户模糊匹配参数",
			params: script.QueryParams{
				AccountLike: "Assets",
			},
			want: true,
		},
		{
			name: "有标签参数",
			params: script.QueryParams{
				Tag: "food",
			},
			want: true,
		},
		{
			name: "有ID参数",
			params: script.QueryParams{
				ID: "123",
			},
			want: true,
		},
		{
			name: "有货币参数",
			params: script.QueryParams{
				Currency: "USD",
			},
			want: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.want, tt.params.HasConditions())
		})
	}
}

// 测试GetQueryParams方法
func TestGetQueryParams_获取查询参数(t *testing.T) {
	// 设置测试账本配置
	ledgerConfig := script.Config{
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

	testConfig := ledgerConfig

	tests := []struct {
		name    string
		query   url.Values
		want    script.QueryParams
		wantErr bool
	}{
		{
			name:  "默认值",
			query: url.Values{},
			want: script.QueryParams{
				FromYear:           time.Now().Year(),
				FromMonth:          int(time.Now().Month()) - 1,
				Year:               time.Now().Year(),
				Month:              int(time.Now().Month()),
				MinDate:            fmt.Sprintf("%04d-%02d-01", time.Now().Year(), time.Now().Month()-1),
				MaxDate:            fmt.Sprintf("%04d-%02d-31", time.Now().Year(), time.Now().Month()),
				StrictAccountMatch: true,
				OrderBy:            "date desc",
				Limit:              100,
				Where:              true,
			},
		},
		{
			name: "有效的年月参数",
			query: url.Values{
				"year":  {"2023"},
				"month": {"12"},
			},
			want: script.QueryParams{
				FromYear:           2023,
				FromMonth:          12,
				Year:               2023,
				Month:              12,
				MinDate:            "2023-12-01",
				MaxDate:            "2023-12-31",
				StrictAccountMatch: true,
				OrderBy:            "date desc",
				Limit:              100,
				Where:              true,
			},
		},
		{
			name: "无效的月份参数",
			query: url.Values{
				"month": {"13"},
			},
			want: script.QueryParams{
				FromYear:           2025,
				FromMonth:          9,
				Year:               2025,
				Month:              10,
				MinDate:            "2025-09-01",
				MaxDate:            "2025-10-31",
				StrictAccountMatch: true,
				OrderBy:            "date desc",
				Limit:              100,
				Where:              true,
			},
		},
		{
			name: "日期范围参数",
			query: url.Values{
				"fromYear":  {"2023"},
				"fromMonth": {"6"},
				"year":      {"2024"},
				"month":     {"3"},
			},
			want: script.QueryParams{
				FromYear:           2023,
				FromMonth:          6,
				Year:               2024,
				Month:              3,
				MinDate:            "2023-06-01",
				MaxDate:            "2024-03-31",
				StrictAccountMatch: true,
				OrderBy:            "date desc",
				Limit:              100,
				Where:              true,
			},
		},
		{
			name: "账户和标签参数",
			query: url.Values{
				"account": {"Assets:Cash"},
				"tag":     {"expense"},
			},
			want: script.QueryParams{
				FromYear:           2025,
				FromMonth:          9,
				Year:               2025,
				Month:              10,
				MinDate:            "2025-09-01",
				MaxDate:            "2025-10-31",
				Account:            "Assets:Cash",
				Tag:                "expense",
				StrictAccountMatch: true,
				OrderBy:            "date desc",
				Limit:              100,
				Where:              true,
			},
		},
		{
			name: "限制和排序参数",
			query: url.Values{

				"limit":   {"50"},
				"orderBy": {"amount desc"},
				"groupBy": {"account"},
			},
			want: script.QueryParams{
				FromYear:           2025,
				FromMonth:          9,
				Year:               2025,
				Month:              10,
				MinDate:            "2025-09-01",
				MaxDate:            "2025-10-31",
				Limit:              50,
				OrderBy:            "amount desc",
				GroupBy:            "account",
				StrictAccountMatch: true,
				Where:              true,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// 创建测试请求
			req, _ := http.NewRequest("GET", "/?"+tt.query.Encode(), nil)
			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)
			c.Request = req
			c.Set("ledgerConfig", &testConfig)

			got, err := script.GetQueryParams(c)
			if (err != nil) != tt.wantErr {
				t.Errorf("GetQueryParams() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			// 打印获取的QueryParams
			jsonData, _ := json.MarshalIndent(got, "", "  ")
			fmt.Printf("\n=== 测试用例 [%s] 获取的QueryParams ===\n", tt.name)
			fmt.Println(string(jsonData))
			fmt.Println("=====================================")

			// 比较主要字段
			assert.Equal(t, tt.want.Year, got.Year)
			assert.Equal(t, tt.want.Month, got.Month)
			assert.Equal(t, tt.want.FromYear, got.FromYear)
			assert.Equal(t, tt.want.FromMonth, got.FromMonth)
			assert.Equal(t, tt.want.Year, got.Year)
			assert.Equal(t, tt.want.Month, got.Month)
			assert.Equal(t, tt.want.Account, got.Account)
			assert.Equal(t, tt.want.AccountLike, got.AccountLike)
			assert.Equal(t, tt.want.Tag, got.Tag)
			assert.Equal(t, tt.want.OrderBy, got.OrderBy)
			assert.Equal(t, tt.want.GroupBy, got.GroupBy)
			assert.Equal(t, tt.want.Limit, got.Limit)
			assert.Equal(t, tt.want.StrictAccountMatch, got.StrictAccountMatch)
			assert.Equal(t, tt.want.Where, got.Where)

			// 对于日期范围，比较字符串格式
			if tt.want.MinDate != "" {
				assert.Equal(t, tt.want.MinDate, got.MinDate)
			}
			if tt.want.MaxDate != "" {
				assert.Equal(t, tt.want.MaxDate, got.MaxDate)
			}
		})
	}
}

// 测试无效参数情况
func TestGetQueryParams_无效参数(t *testing.T) {
	// 模拟 ledgerConfig
	ledgerConfig := script.Config{
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

	testConfig := ledgerConfig

	tests := []struct {
		name  string
		query url.Values
	}{
		{
			name: "未定义年份",
			query: url.Values{
				"year": {"undefined"},
			},
		},
		{
			name: "空月份",
			query: url.Values{
				"month": {"null"},
			},
		},
		{
			name: "无效年份",
			query: url.Values{
				"year": {"abc"},
			},
		},
		{
			name: "无效月份",
			query: url.Values{
				"month": {"13"},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req, _ := http.NewRequest("GET", "/?"+tt.query.Encode(), nil)
			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)
			c.Request = req
			c.Set("ledgerConfig", &testConfig)

			params, err := script.GetQueryParams(c)
			assert.NoError(t, err)

			// 打印获取的QueryParams
			jsonData, _ := json.MarshalIndent(params, "", "  ")
			fmt.Printf("\n=== 测试用例 [%s] 获取的QueryParams ===\n", tt.name)
			fmt.Println(string(jsonData))
			fmt.Println("=====================================")

			assert.Equal(t, time.Now().Year(), params.Year)
			assert.Equal(t, int(time.Now().Month()), params.Month)
		})
	}
}

// 测试日期范围计算
func TestGetQueryParams_日期范围计算(t *testing.T) {
	// 模拟 ledgerConfig
	ledgerConfig := script.Config{
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

	testConfig := ledgerConfig

	now := time.Now()
	currentYear := now.Year()
	currentMonth := int(now.Month())

	tests := []struct {
		name      string
		query     url.Values
		wantFrom  time.Time
		wantTo    time.Time
		wantYear  int
		wantMonth int
		wantFromY int
		wantFromM int
	}{
		{
			name:      "当前年月",
			query:     url.Values{"year": {strconv.Itoa(currentYear)}, "month": {strconv.Itoa(currentMonth)}},
			wantFrom:  time.Date(currentYear, time.Month(currentMonth), 1, 0, 0, 0, 0, time.Local),
			wantTo:    time.Date(currentYear, time.Month(currentMonth), 1, 0, 0, 0, 0, time.Local).AddDate(0, 1, -1),
			wantYear:  currentYear,
			wantMonth: currentMonth,
			wantFromY: currentYear,
			wantFromM: currentMonth,
		},
		{
			name:      "全年范围",
			query:     url.Values{"year": {"2023"}},
			wantFrom:  time.Date(2023, 1, 1, 0, 0, 0, 0, time.Local),
			wantTo:    time.Date(2023, 12, 31, 0, 0, 0, 0, time.Local),
			wantYear:  2023,
			wantMonth: 12,
			wantFromY: 2023,
			wantFromM: 1,
		},
		{
			name:      "跨年范围",
			query:     url.Values{"FromYear": {"2023"}, "FromMonth": {"11"}, "endYear": {"2024"}, "endMonth": {"2"}},
			wantFrom:  time.Date(2023, 11, 1, 0, 0, 0, 0, time.Local),
			wantTo:    time.Date(2024, 3, 1, 0, 0, 0, 0, time.Local).Add(-time.Second),
			wantYear:  0,
			wantMonth: 0,
			wantFromY: 2023,
			wantFromM: 11,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req, _ := http.NewRequest("GET", "/?"+tt.query.Encode(), nil)
			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)
			c.Request = req
			c.Set("ledgerConfig", &testConfig)

			params, err := script.GetQueryParams(c)
			assert.NoError(t, err)

			// 打印获取的QueryParams
			jsonData, _ := json.MarshalIndent(params, "", "  ")
			fmt.Printf("\n=== 测试用例 [%s] 获取的QueryParams ===\n", tt.name)
			fmt.Println(string(jsonData))
			fmt.Println("=====================================")

			assert.Equal(t, tt.wantYear, params.Year)
			assert.Equal(t, tt.wantMonth, params.Month)
			assert.Equal(t, tt.wantFromY, params.FromYear)
			assert.Equal(t, tt.wantFromM, params.FromMonth)

			if !tt.wantFrom.IsZero() {
				parsedMinDate, err := time.Parse("2006-01-02", params.MinDate)
				assert.NoError(t, err)
				assert.Equal(t, tt.wantFrom.Year(), parsedMinDate.Year())
				assert.Equal(t, tt.wantFrom.Month(), parsedMinDate.Month())
				assert.Equal(t, tt.wantFrom.Day(), parsedMinDate.Day())
			}

			if !tt.wantTo.IsZero() {
				parsedMaxDate, err := time.Parse("2006-01-02", params.MaxDate)
				assert.NoError(t, err)
				assert.Equal(t, tt.wantTo.Year(), parsedMaxDate.Year())
				assert.Equal(t, tt.wantTo.Month(), parsedMaxDate.Month())
				assert.Equal(t, tt.wantTo.Day(), parsedMaxDate.Day())
			}
		})
	}
}

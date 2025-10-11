package modules

import (
	"errors"
)

// Importer 定义所有导入器必须实现的接口
type Importer interface {
	// Import 执行导入过程，将CSV文件转换为Beancount格式
	Import(csvPath, rulesPath, outputPath string) error

	// GetSupportedExtensions 返回支持的扩展名列表
	GetSupportedExtensions() []string

	// Detect 检测文件是否可以被此导入器处理
	Detect(filePath string) bool
}

// Rules 包含所有导入规则
type Rules struct {
	PaymentRules      []PaymentRule
	CounterpartyRules []CounterpartyRule
}

// PaymentRule 定义了支付方式匹配规则
type PaymentRule struct {
	PaymentMethod   string
	TransactionType string
	DebitAccounts   []string
	CreditAccounts  []string
}

// CounterpartyRule 定义了交易对手匹配规则
type CounterpartyRule struct {
	Pattern   string
	Category  string
	Payee     string
	Narration string
}

// 辅助函数检测文件类型
func IsWechatCSV(filePath string) bool {
	// 实现微信CSV的检测逻辑
	return true
}

// 通用错误定义
var (
	ErrUnsupportedFileType = errors.New("不支持的文件类型")
	ErrInvalidCSVFormat    = errors.New("CSV格式无效")
	ErrRuleFileNotFound    = errors.New("规则文件未找到")
)

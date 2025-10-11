package alipay

import (
	"encoding/csv"
	"fmt"
	"os"
	"strings"
	"time"

	"cnb.cool/ysundy/bean/beancount-gs/importer/modules/common"
	"gopkg.in/yaml.v3"
)

// Deduplicator 用于检测和防止重复交易
type Deduplicator struct {
	seenTransactions map[string]time.Time
}

// NewDeduplicator 创建新的去重器实例
func NewDeduplicator() *Deduplicator {
	return &Deduplicator{
		seenTransactions: make(map[string]time.Time),
	}
}

// AlipayImporter 实现支付宝CSV导入器
type AlipayImporter struct {
	deduplicator *Deduplicator
}

// NewAlipayImporter 创建新的支付宝导入器实例
func NewAlipayImporter() *AlipayImporter {
	return &AlipayImporter{
		deduplicator: NewDeduplicator(),
	}
}

// Import 实现支付宝CSV导入
func (ai *AlipayImporter) Import(csvPath, rulesPath, outputPath string) error {
	// 加载规则文件
	rules, err := loadRules(rulesPath)
	if err != nil {
		return fmt.Errorf("加载规则文件失败: %v", err)
	}

	// 打开CSV文件
	file, err := os.Open(csvPath)
	if err != nil {
		return fmt.Errorf("打开CSV文件失败: %v", err)
	}
	defer file.Close()

	// 创建CSV reader
	reader := csv.NewReader(file)
	reader.FieldsPerRecord = -1 // 允许可变字段数

	// 创建输出文件
	outputFile, err := os.Create(outputPath)
	if err != nil {
		return fmt.Errorf("创建输出文件失败: %v", err)
	}
	defer outputFile.Close()

	// 解析CSV并生成Beancount条目
	lineCount := 0
	successCount := 0

	for {
		record, err := reader.Read()
		if err != nil {
			break // 文件结束
		}

		lineCount++
		if lineCount == 1 || len(record) < 8 {
			continue // 跳过标题行和空行
		}

		// 解析CSV字段
		transactionTime := strings.TrimSpace(record[0])
		transactionType := strings.TrimSpace(record[1])
		counterparty := strings.TrimSpace(record[2])
		description := strings.TrimSpace(record[4])
		amount := cleanAmount(strings.TrimSpace(record[6]))
		paymentMethod := strings.TrimSpace(record[7])

		// 匹配支付规则
		paymentRule := common.MatchPaymentRule(rules, paymentMethod, transactionType)
		if paymentRule == nil {
			continue
		}

		// 匹配对方规则
		counterpartyRule := common.MatchCounterpartyRule(rules, counterparty, description, transactionType)
		if counterpartyRule == nil {
			continue
		}

		// 生成Beancount条目
		entry := common.GenerateBeancountEntry(
			transactionTime,
			transactionType,
			counterparty,
			description,
			amount,
			paymentRule,
			counterpartyRule,
		)

		// 写入输出文件
		if _, err := outputFile.WriteString(entry + "\n\n"); err != nil {
			continue
		}

		successCount++
	}

	fmt.Printf("处理完成: 成功转换 %d/%d 条记录\n", successCount, lineCount-1)
	return nil
}

// GetSupportedExtensions 返回支持的扩展名
func (ai *AlipayImporter) GetSupportedExtensions() []string {
	return []string{".csv"}
}

// Detect 检测是否是支付宝CSV
func (ai *AlipayImporter) Detect(filePath string) bool {
	return IsAlipayCSV(filePath)
}

// 以下为辅助函数实现...

func loadRules(filePath string) (*common.Rules, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	var rules common.Rules
	if err := yaml.Unmarshal(data, &rules); err != nil {
		return nil, err
	}
	return &rules, nil
}

func cleanAmount(amount string) string {
	amount = strings.ReplaceAll(amount, ",", "")
	amount = strings.ReplaceAll(amount, " ", "")
	amount = strings.TrimPrefix(amount, "¥")
	return amount
}

// IsAlipayCSV 检测文件是否为支付宝CSV格式
func IsAlipayCSV(filePath string) bool {
	// 检查文件扩展名
	if !strings.HasSuffix(strings.ToLower(filePath), ".csv") {
		return false
	}

	// 尝试读取文件第一行检查特征
	file, err := os.Open(filePath)
	if err != nil {
		return false
	}
	defer file.Close()

	reader := csv.NewReader(file)
	headers, err := reader.Read()
	if err != nil {
		return false
	}

	// 检查是否包含支付宝特有的列
	requiredColumns := []string{"交易号", "商家订单号", "交易创建时间"}
	for _, col := range requiredColumns {
		found := false
		for _, header := range headers {
			if header == col {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	return true
}

// 其他辅助函数...

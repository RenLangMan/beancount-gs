package wechat

import (
	"encoding/csv"
	"fmt"
	"os"
	"strings"

	"cnb.cool/ysundy/bean/beancount-gs/importer/modules"
	"cnb.cool/ysundy/bean/beancount-gs/importer/modules/common"
	"cnb.cool/ysundy/bean/beancount-gs/importer/modules/deduplicate"
	"gopkg.in/yaml.v3"
)

// WechatImporter 实现微信支付CSV导入器
type WechatImporter struct {
	deduplicator *deduplicate.Deduplicator
}

// NewWechatImporter 创建新的微信支付导入器实例
func NewWechatImporter() *WechatImporter {
	return &WechatImporter{
		deduplicator: deduplicate.NewDeduplicator(),
	}
}

// Import 实现微信支付CSV导入
func (wi *WechatImporter) Import(csvPath, rulesPath, outputPath string) error {
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

		// 解析微信支付特定字段
		transactionTime := strings.TrimSpace(record[0])
		transactionType := strings.TrimSpace(record[1])
		counterparty := strings.TrimSpace(record[2])
		description := strings.TrimSpace(record[3])
		amount := cleanAmount(strings.TrimSpace(record[5]))
		paymentMethod := "微信支付" // 微信支付没有单独的支付方式字段

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
func (wi *WechatImporter) GetSupportedExtensions() []string {
	return []string{".csv"}
}

// Detect 检测是否是微信支付CSV
func (wi *WechatImporter) Detect(filePath string) bool {
	return modules.IsWechatCSV(filePath)
}

// 辅助函数...

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

// 其他微信支付特定的辅助函数...

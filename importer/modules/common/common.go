package common

import (
	"fmt"
	"os"
	"strings"

	"gopkg.in/yaml.v3"
)

// Rules 定义支付规则和对方规则
type Rules struct {
	PaymentRules      []PaymentRule      `yaml:"payment_rules"`
	CounterpartyRules []CounterpartyRule `yaml:"counterparty_rules"`
}

// PaymentRule 定义支付方式规则
type PaymentRule struct {
	PaymentMethod   string   `yaml:"payment_method"`
	TransactionType string   `yaml:"transaction_type"`
	DebitAccounts   []string `yaml:"debit_accounts"`
	CreditAccounts  []string `yaml:"credit_accounts"`
}

// CounterpartyRule 定义交易对手规则
type CounterpartyRule struct {
	Pattern  string `yaml:"pattern"`
	Category string `yaml:"category"`
}

// LoadRules 从YAML文件加载规则
func LoadRules(filePath string) (*Rules, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	var rules Rules
	if err := yaml.Unmarshal(data, &rules); err != nil {
		return nil, err
	}
	return &rules, nil
}

// MatchPaymentRule 匹配支付方式规则
func MatchPaymentRule(rules *Rules, paymentMethod, transactionType string) *PaymentRule {
	for _, rule := range rules.PaymentRules {
		if rule.PaymentMethod == paymentMethod && rule.TransactionType == transactionType {
			return &rule
		}
	}
	return nil
}

// MatchCounterpartyRule 匹配交易对手规则
func MatchCounterpartyRule(rules *Rules, counterparty, description, transactionType string) *CounterpartyRule {
	for _, rule := range rules.CounterpartyRules {
		if strings.Contains(counterparty, rule.Pattern) ||
			strings.Contains(description, rule.Pattern) {
			return &rule
		}
	}
	return nil
}

// GenerateBeancountEntry 生成Beancount格式的账目条目
func GenerateBeancountEntry(
	dateTime string,
	transactionType string,
	payee string,
	narration string,
	amount string,
	paymentRule *PaymentRule,
	counterpartyRule *CounterpartyRule,
) string {
	// 解析日期时间
	date := strings.Split(dateTime, " ")[0]

	// 生成账目条目
	entry := fmt.Sprintf(`%s * "%s" "%s"`, date, payee, narration)

	// 添加借方账户
	for _, account := range paymentRule.DebitAccounts {
		entry += fmt.Sprintf("\n  %-40s %s CNY", account, amount)
	}

	// 添加贷方账户
	for _, account := range paymentRule.CreditAccounts {
		entry += fmt.Sprintf("\n  %-40s -%s CNY", account, amount)
	}

	// 添加分类标签
	if counterpartyRule.Category != "" {
		entry += fmt.Sprintf("\n  category: \"%s\"", counterpartyRule.Category)
	}

	return entry
}

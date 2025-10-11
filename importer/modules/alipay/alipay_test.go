package alipay

import (
	"os"
	"path/filepath"
	"testing"

	"cnb.cool/ysundy/bean/beancount-gs/importer/modules/common"
)

func TestIsAlipayCSV(t *testing.T) {
	tests := []struct {
		name     string
		filename string
		content  string
		want     bool
	}{
		{
			name:     "标准支付宝文件名",
			filename: "alipay_record_20230101.csv",
			content:  "支付宝交易记录",
			want:     true,
		},
		{
			name:     "非标准文件名但包含支付宝内容",
			filename: "transaction.csv",
			content:  "支付宝（中国）网络技术有限公司",
			want:     true,
		},
		{
			name:     "非支付宝文件",
			filename: "other.csv",
			content:  "其他交易记录",
			want:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// 创建临时文件
			tmpDir := t.TempDir()
			filePath := filepath.Join(tmpDir, tt.filename)
			if err := os.WriteFile(filePath, []byte(tt.content), 0644); err != nil {
				t.Fatalf("创建测试文件失败: %v", err)
			}

			got := IsAlipayCSV(filePath)
			if got != tt.want {
				t.Errorf("IsAlipayCSV() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestMatchPaymentRule(t *testing.T) {
	rules := &common.Rules{
		PaymentRules: []common.PaymentRule{
			{
				PaymentMethod:   "余额",
				TransactionType: "消费",
			},
			{
				PaymentMethod:   "花呗",
				TransactionType: "还款",
			},
		},
	}

	tests := []struct {
		name            string
		paymentMethod   string
		transactionType string
		wantFound       bool
	}{
		{"匹配余额消费", "余额", "消费", true},
		{"匹配花呗还款", "花呗", "还款", true},
		{"不匹配", "银行卡", "转账", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := common.MatchPaymentRule(rules, tt.paymentMethod, tt.transactionType)
			if (got != nil) != tt.wantFound {
				t.Errorf("matchPaymentRule() got = %v, wantFound %v", got, tt.wantFound)
			}
		})
	}
}

func TestGenerateBeancountEntry(t *testing.T) {
	paymentRule := &common.PaymentRule{
		DebitAccounts:  []string{"Expenses:Food"},
		CreditAccounts: []string{"Assets:Alipay"},
	}

	counterpartyRule := &common.CounterpartyRule{
		Category: "餐饮",
	}

	entry := common.GenerateBeancountEntry(
		"2023-01-01 12:00:00",
		"消费",
		"测试商家",
		"午餐",
		"100.00",
		paymentRule,
		counterpartyRule,
	)

	expected := `2023-01-01 * "测试商家" "午餐"
  Expenses:Food                          100.00 CNY
  Assets:Alipay                          -100.00 CNY
  category: "餐饮"
`

	if entry != expected {
		t.Errorf("generateBeancountEntry() = %v, want %v", entry, expected)
	}
}

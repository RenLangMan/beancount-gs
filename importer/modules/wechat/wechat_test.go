package wechat

import (
	"os"
	"path/filepath"
	"testing"

	"cnb.cool/ysundy/bean/beancount-gs/importer/modules/common"
)

func TestIsWechatCSV(t *testing.T) {
	tests := []struct {
		name     string
		filename string
		content  string
		want     bool
	}{
		{
			name:     "标准微信支付文件名",
			filename: "微信支付账单20230101.csv",
			content:  "微信支付交易明细",
			want:     true,
		},
		{
			name:     "非标准文件名但包含微信支付内容",
			filename: "transaction.csv",
			content:  "微信支付商户平台",
			want:     true,
		},
		{
			name:     "非微信支付文件",
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

			importer := NewWechatImporter()
			got := importer.Detect(filePath)
			if got != tt.want {
				t.Errorf("IsWechatCSV() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestMatchPaymentRule(t *testing.T) {
	rules := &common.Rules{
		PaymentRules: []common.PaymentRule{
			{
				PaymentMethod:   "微信支付",
				TransactionType: "消费",
			},
			{
				PaymentMethod:   "微信支付",
				TransactionType: "转账",
			},
		},
	}

	tests := []struct {
		name            string
		paymentMethod   string
		transactionType string
		wantFound       bool
	}{
		{"匹配微信支付消费", "微信支付", "消费", true},
		{"匹配微信支付转账", "微信支付", "转账", true},
		{"不匹配", "银行卡", "还款", false},
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
		DebitAccounts:  []string{"Expenses:Shopping"},
		CreditAccounts: []string{"Assets:Wechat"},
	}

	counterpartyRule := &common.CounterpartyRule{
		Category: "购物",
	}

	entry := common.GenerateBeancountEntry(
		"2023-01-01 12:00:00",
		"消费",
		"测试商家",
		"购物",
		"200.00",
		paymentRule,
		counterpartyRule,
	)

	expected := `2023-01-01 * "测试商家" "购物"
  Expenses:Shopping                     200.00 CNY
  Assets:Wechat                         -200.00 CNY
  category: "购物"
`

	if entry != expected {
		t.Errorf("generateBeancountEntry() = %v, want %v", entry, expected)
	}
}

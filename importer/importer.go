package importer

import (
	"fmt"
	"os"
	"path/filepath"

	"cnb.cool/ysundy/bean/beancount-gs/importer/modules"
	"cnb.cool/ysundy/bean/beancount-gs/importer/modules/alipay"
	"cnb.cool/ysundy/bean/beancount-gs/importer/modules/wechat"
)

// Import 执行导入操作
func Import(csvPath, rulesPath, outputPath string) error {
	// 参数校验
	if csvPath == "" || rulesPath == "" || outputPath == "" {
		return fmt.Errorf("所有路径参数都不能为空")
	}

	// 检查输入文件是否存在
	if _, err := os.Stat(csvPath); os.IsNotExist(err) {
		return fmt.Errorf("CSV文件不存在: %s", csvPath)
	}

	// 检查规则文件是否存在
	if _, err := os.Stat(rulesPath); os.IsNotExist(err) {
		return fmt.Errorf("规则文件不存在: %s", rulesPath)
	}

	// 检查输出目录是否可写
	outputDir := filepath.Dir(outputPath)
	if info, err := os.Stat(outputDir); err != nil || !info.IsDir() {
		return fmt.Errorf("输出目录不可写: %s", outputDir)
	}

	// 检测文件类型并选择导入器
	var importer modules.Importer
	alipayImporter := alipay.NewAlipayImporter()
	wechatImporter := wechat.NewWechatImporter()

	switch {
	case alipayImporter.Detect(csvPath):
		importer = alipayImporter
	case wechatImporter.Detect(csvPath):
		importer = wechatImporter
	default:
		return fmt.Errorf("无法识别的文件类型: %s", filepath.Base(csvPath))
	}

	// 执行导入
	if err := importer.Import(csvPath, rulesPath, outputPath); err != nil {
		return fmt.Errorf("导入失败: %v", err)
	}

	return nil
}

# 106-import.go

## 文件概述
`import.go` 是 beancount-gs 项目中负责账单导入的服务文件。该文件实现了从支付宝、微信支付、工商银行和农业银行等平台导入交易记录的功能，是项目中数据导入的核心组件。

## 主要功能
1. **支付宝账单导入**：支持浏览器版和手机版支付宝账单导入
2. **微信支付账单导入**：支持微信支付账单导入
3. **工商银行账单导入**：支持工商银行账单导入
4. **农业银行账单导入**：支持农业银行账单导入
5. **数据格式化**：统一格式化导入的交易数据

## 关键组件

### 导入函数
- `ImportAliPayCSV(c *gin.Context)`：导入支付宝账单
  - 支持浏览器版和手机版两种格式
  - 调用 `importBrowserAliPayCSV` 和 `importMobileAliPayCSV` 处理不同格式
- `ImportWxPayCSV(c *gin.Context)`：导入微信支付账单
- `ImportICBCCSV(c *gin.Context)`：导入工商银行账单
- `ImportABCCSV(c *gin.Context)`：导入农业银行账单

### 辅助函数
- `importBrowserAliPayCSV()`：处理浏览器版支付宝账单
- `importMobileAliPayCSV()`：处理手机版支付宝账单
- `formatStr()`：格式化字符串，去除空白和制表符

### 数据结构
- `Transaction`：交易记录结构体
  - `Id`：交易ID
  - `Date`：交易日期
  - `Payee`：交易对方
  - `Narration`：交易说明
  - `Number`：交易金额
  - `Account`：账户类型（Income/Expenses）
  - `Currency`：货币类型
  - `CurrencySymbol`：货币符号

## 技术特点
- 使用 Gin 框架处理文件上传
- 支持 CSV 格式解析
- 处理 GBK 编码的支付宝账单
- 自动识别收入和支出
- 统一格式化交易数据
- 实现了日志记录和错误处理

## 应用场景
- 从支付宝导入交易记录
- 从微信支付导入交易记录
- 从工商银行导入交易记录
- 从农业银行导入交易记录
- 统一不同来源的交易数据格式

## 注意事项
- 不同平台的账单格式不同
- 支付宝浏览器版和手机版账单格式有差异
- 日期格式需要统一处理
- 金额需要正确解析
- 编码问题需要特别注意（如支付宝使用GBK编码）
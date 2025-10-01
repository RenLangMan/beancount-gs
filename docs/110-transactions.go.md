# 110-transactions.go

## 文件概述
`transactions.go` 是 beancount-gs 项目中负责交易管理的核心服务文件。该文件实现了交易的增删改查、模板管理、批量操作等功能，是项目中交易处理的核心组件。

## 主要功能
1. **交易查询**：按条件查询交易记录
2. **交易操作**：添加、修改、删除交易
3. **批量处理**：支持批量添加交易
4. **模板管理**：交易模板的增删查
5. **辅助功能**：查询收款人、可用年月等

## 关键组件

### 数据结构
- `Transaction`：交易记录结构
- `TransactionForm`：交易表单
- `TransactionEntryForm`：交易条目
- `TransactionTemplate`：交易模板
- `TransactionQuery`：交易查询参数

### 核心函数
- `QueryTransactions()`：查询交易记录
- `AddTransactions()`：添加交易
- `UpdateTransactionRawTextById()`：更新交易原始文本
- `DeleteTransactionById()`：删除交易
- `QueryTransactionTemplates()`：查询交易模板
- `AddTransactionTemplate()`：添加交易模板
- `DeleteTransactionTemplate()`：删除交易模板

### 辅助函数
- `getTransactionDateRange()`：获取交易时间范围
- `saveTransaction()`：保存交易到文件
- `updateTransaction()`：更新交易内容
- `getBeanFilePathByTransactionId()`：根据交易ID获取文件路径
- `getLedgerTransactionTemplates()`：获取交易模板

## 技术特点
- 使用 Gin 框架处理 HTTP 请求
- 通过 BQL 查询账本数据
- 支持多币种交易处理
- 实现交易平衡检查
- 提供完整的错误处理和日志记录
- 支持交易模板管理

## 应用场景
- 展示交易记录列表
- 添加新交易
- 修改现有交易
- 删除交易
- 管理交易模板
- 批量导入交易
- 查询收款人信息
- 获取可用年月数据

## 注意事项
- 交易必须保持平衡
- 多币种交易需要正确处理汇率
- 文件操作需要权限检查
- 大文件操作可能影响性能
- 交易ID需要唯一
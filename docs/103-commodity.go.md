# 103-commodity.go

## 文件概述
`commodity.go` 是 beancount-gs 项目中负责商品价格管理的服务文件。该文件实现了商品价格同步和货币查询功能，是项目中商品和货币管理的核心组件。

## 主要功能
1. **商品价格同步**：将商品价格同步到账本文件中
2. **货币查询**：查询所有货币及其当前汇率

## 关键组件

### 同步商品价格
- `SyncCommodityPrice(c *gin.Context)`：同步商品价格到账本文件
  - 使用 `SyncCommodityPriceForm` 结构体接收请求参数
  - 将价格信息追加到价格文件中
  - 刷新货币缓存

### 查询货币
- `QueryAllCurrencies(c *gin.Context)`：查询所有货币及其当前汇率
  - 调用 `script.RefreshLedgerCurrency` 获取最新货币信息

### 数据结构
- `SyncCommodityPriceForm`：同步商品价格表单
  - `Commodity`：商品名称
  - `Date`：价格日期
  - `Price`：价格数值

## 技术特点
- 使用 Gin 框架处理 HTTP 请求
- 通过文件操作将价格信息持久化
- 实现了货币缓存刷新机制
- 提供了完整的错误处理和响应机制

## 应用场景
- 同步商品价格到账本
- 查询货币列表和汇率
- 更新货币缓存

## 注意事项
- 商品价格同步需要正确的账本配置
- 价格日期需要符合特定格式
- 货币查询会刷新缓存，可能影响性能
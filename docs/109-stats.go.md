# 109-stats.go

## 文件概述
`stats.go` 是 beancount-gs 项目中负责统计功能的服务文件。该文件实现了多种财务统计功能，包括月度统计、账户趋势、桑基图数据生成等，是项目中统计分析的核心组件。

## 主要功能
1. **月度统计**：计算每月收入、支出和结余
2. **账户趋势**：分析账户金额随时间的变化趋势
3. **桑基图数据**：生成账户间资金流动的桑基图数据
4. **账户百分比**：计算各账户金额占比
5. **收款人统计**：分析收款人交易数据
6. **商品价格**：查询商品价格历史

## 关键组件

### 统计函数
- `MonthsList()`：获取账本中所有交易记录的月份列表
- `StatsTotal()`：计算账本中各主要账户类型的总额统计
- `StatsAccountPercent()`：计算账户金额占比统计
- `StatsAccountTrend()`：获取账户金额趋势数据
- `StatsAccountBalance()`：获取账户每日余额数据
- `StatsAccountSankey()`：生成账户资金流向桑基图数据
- `StatsMonthTotal()`：获取月度收支统计数据
- `StatsMonthCalendar()`：获取指定月份的日历统计数据
- `StatsPayee()`：获取收款人统计数据
- `StatsCommodityPrice()`：获取商品价格数据

### 辅助函数
- `parseAmountAndCurrency()`：解析金额和货币字符串
- `aggregateAccountPercentList()`：聚合重复账户的金额
- `buildSankeyResult()`：构建桑基图数据结构
- `hasCycle()`：检测桑基图连接中的循环引用
- `breakCycleAndAddNode()`：打破桑基图中的循环引用

### 数据结构
- `YearMonth`：年份和月份组合
- `StatsResult`：统计查询结果
- `AccountPercentResult`：账户百分比结果
- `AccountTrendResult`：账户趋势数据
- `AccountBalanceResult`：账户余额数据
- `AccountSankeyResult`：桑基图数据结构
- `MonthTotal`：月度统计数据
- `StatsCalendarResult`：日历统计数据
- `StatsPayeeResult`：收款人统计数据

## 技术特点
- 使用 Gin 框架处理 HTTP 请求
- 通过 BQL 查询获取账本数据
- 使用 decimal 包处理高精度金额计算
- 支持多币种自动转换
- 提供完整的错误处理和日志记录
- 实现复杂的数据分析和可视化功能

## 应用场景
- 展示月度收支统计
- 分析账户金额变化趋势
- 可视化账户间资金流动
- 计算账户金额占比
- 分析收款人交易数据
- 查询商品价格历史

## 注意事项
- 金额计算使用 decimal 保证精度
- 桑基图数据处理循环引用
- 多币种统计自动转换到运营货币
- 查询参数需要正确绑定
- 大数据量查询可能性能较低
# 003 - 规则分析模块 (rule_analyzer.py)

## 功能概述

`rule_analyzer.py` 是规则处理系统的规则分析模块，负责分析交易数据并自动生成分类规则，包括支付方式规则和交易对手规则。

## 主要类和方法

### RuleAnalyzer 类

规则分析器，提供交易数据分析和规则生成功能。

#### 初始化方法

```python
def __init__(self, db_file: str, logger: Optional[logging.Logger] = None)
```

- `db_file`: 数据库文件路径
- `logger`: 可选的自定义日志记录器

#### 主要方法

1. `analyze_rules(incremental: bool = False) -> bool`
   - 分析交易数据并生成规则
   - `incremental`: 是否增量分析（True表示保留旧规则，False表示重置）
   - 返回True表示成功，False表示失败

## 规则类型

### 1. 支付方式规则 (PaymentRule)

根据账户自动生成的规则，用于处理特定类型的收支。

属性：

- `name`: 规则名称（自动生成，格式为"auto_账户名"）
- `payment_method`: 支付方式（固定为"自动识别"）
- `default_amount`: 默认金额
- `example_count`: 示例数量
- `transaction_type`: 交易类型（"收入"或"支出"）
- `debit_accounts`: 借方账户列表
- `credit_accounts`: 贷方账户列表

### 2. 交易对手规则 (CounterpartyRule)

根据交易对方和描述生成的规则，用于自动分类特定交易。

属性：

- `name`: 规则名称（格式为"对方机构_描述"或"对方机构_default"）
- `counterparty`: 交易对方机构
- `description`: 交易描述
- `category`: 自动分类
- `account`: 目标账户
- `example_count`: 示例数量

## 分类逻辑

模块使用以下策略自动分类交易：

1. **账户名匹配**：
   - 使用`CATEGORY_MAP`字典匹配账户名中的关键词
   - 例如："food"或"restaurant"会分类为"餐饮美食"

2. **描述关键词匹配**：
   - 使用`DESC_KEYWORDS`字典匹配交易描述中的关键词
   - 例如：描述中包含"外卖"会分类为"餐饮美食"

3. **账户路径匹配**：
   - 对于形如"Expenses:Food:Dinner"的账户，会检查冒号后的部分

4. **默认分类**：
   - 无法匹配时会分类为"其他"

## 使用示例

```python
from rule_analyzer import RuleAnalyzer
import logging

# 初始化日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("RuleAnalyzerExample")

# 创建规则分析器
analyzer = RuleAnalyzer("rules.db", logger)

# 执行规则分析（全量模式）
if analyzer.analyze_rules(incremental=False):
    print("规则分析成功")
else:
    print("规则分析失败")

# 执行增量分析（保留旧规则）
if analyzer.analyze_rules(incremental=True):
    print("增量规则分析成功")
else:
    print("增量规则分析失败")
```

## 注意事项

1. 需要先有交易数据才能进行分析（通常先运行rule_extractor.py）
2. 全量分析会停用不再使用的旧规则
3. 增量分析会保留旧规则，只添加新规则
4. 错误会记录到日志中
5. 分类映射和关键词映射可以在代码中自定义

# 005 - 规则导出模块 (rule_exporter.py)

## 功能概述

`rule_exporter.py` 是规则处理系统的规则导出模块，负责将数据库中的规则导出为YAML或JSON格式文件，便于后续使用或分享。

## 主要类和方法

### RuleExporter 类

规则导出器，提供规则导出功能。

#### 初始化方法

```python
def __init__(self, ledger_dir: str, db_file: str, logger: Optional[logging.Logger] = None)
```

- `ledger_dir`: beancount账本目录
- `db_file`: 数据库文件路径
- `logger`: 可选的自定义日志记录器

#### 主要方法

1. `generate_yaml_rules(output_file: str, only_active: bool = True) -> bool`
   - 导出YAML格式规则文件
   - `output_file`: 输出文件路径（相对于账本目录下的importer子目录）
   - `only_active`: 是否只导出活跃规则（默认True）
   - 返回True表示成功，False表示失败

2. `generate_json_rules(output_file: str, only_active: bool = True) -> bool`
   - 导出JSON格式规则文件（可选功能）
   - 参数同上

## 输出文件格式

### YAML格式示例

```yaml
meta:
  generated_at: "2025-10-02T18:37:43.123456"
  active_rules_only: true
  payment_rule_count: 12
  counterparty_rule_count: 8
payment_rules:
  - name: "auto_支付宝"
    payment_method: "自动识别"
    default_amount: 0.0
    example_count: 5
    transaction_type: "支出"
    debit_accounts: ["Assets:Alipay"]
    credit_accounts: ["Expenses:Food"]
counterparty_rules:
  - name: "星巴克_default"
    counterparty: "星巴克"
    description: "default"
    category: "餐饮美食"
    account: "Expenses:Food:Coffee"
    example_count: 3
```

### JSON格式示例

```json
{
  "meta": {
    "generated_at": "2025-10-02T18:37:43.123456",
    "active_rules_only": true,
    "payment_rule_count": 12,
    "counterparty_rule_count": 8
  },
  "payment_rules": [
    {
      "name": "auto_支付宝",
      "payment_method": "自动识别",
      "default_amount": 0.0,
      "example_count": 5,
      "transaction_type": "支出",
      "debit_accounts": ["Assets:Alipay"],
      "credit_accounts": ["Expenses:Food"]
    }
  ],
  "counterparty_rules": [
    {
      "name": "星巴克_default",
      "counterparty": "星巴克",
      "description": "default",
      "category": "餐饮美食",
      "account": "Expenses:Food:Coffee",
      "example_count": 3
    }
  ]
}
```

## 使用示例

### 导出YAML规则文件

```python
from rule_exporter import RuleExporter
import logging

# 初始化日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("RuleExporterExample")

# 创建规则导出器
exporter = RuleExporter(
    ledger_dir="/path/to/beancount/files",
    db_file="rules.db",
    logger=logger
)

# 导出YAML规则文件（仅活跃规则）
if exporter.generate_yaml_rules("output_rules.yaml"):
    print("YAML规则导出成功")
else:
    print("YAML规则导出失败")

# 导出所有规则（包括非活跃规则）
if exporter.generate_yaml_rules("all_rules.yaml", only_active=False):
    print("所有规则导出成功")
else:
    print("所有规则导出失败")
```

### 导出JSON规则文件

```python
# 导出JSON规则文件
if exporter.generate_json_rules("rules.json"):
    print("JSON规则导出成功")
else:
    print("JSON规则导出失败")
```

## 元数据结构

导出的规则文件包含以下元数据：

- `generated_at`: 生成时间(ISO格式)
- `active_rules_only`: 是否只包含活跃规则
- `payment_rule_count`: 支付规则数量
- `counterparty_rule_count`: 交易对方规则数量

## 注意事项

1. 需要先有规则数据才能导出（通常先运行rule_analyzer.py）
2. 默认只导出活跃规则（is_active=1）
3. 输出文件会保存在账本目录下的importer子目录
4. 错误会记录到日志中
5. YAML格式更适合人类阅读，JSON格式更适合程序处理

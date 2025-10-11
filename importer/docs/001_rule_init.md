# 001 - 数据库初始化模块 (rule_init.py)

## 功能概述

`rule_init.py` 是规则处理系统的数据库初始化模块，负责创建和维护SQLite数据库的表结构、索引和视图。

## 主要类和方法

### DatabaseInitializer 类

数据库初始化器，提供数据库初始化功能。

#### 初始化方法

```python
def __init__(self, db_file: str, logger: Optional[logging.Logger] = None)
```

- `db_file`: 数据库文件路径
- `logger`: 可选的自定义日志记录器

#### 主要方法

1. `init_database() -> bool`
   - 初始化整个数据库结构
   - 返回True表示成功，False表示失败

2. `ensure_tables_exist()`
   - 确保所有需要的表都存在

## 数据库结构

### 主要表

1. `transactions` - 原始交易表
2. `rules` - 规则表
3. `beancount_entries` - beancount entries表
4. `entry_meta` - entry元数据表
5. `entry_postings` - entry postings表
6. `analysis_results` - 分析结果表

### 视图

1. `account_transaction_count` - 账户交易统计
2. `transaction_by_id` - 按ID统计交易
3. `rule_statistics` - 规则统计信息

## 使用示例

```python
from rule_init import DatabaseInitializer
import logging

# 初始化日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("DatabaseInitExample")

# 初始化数据库
initializer = DatabaseInitializer("rules.db", logger)
if initializer.init_database():
    print("数据库初始化成功")
else:
    print("数据库初始化失败")
```

## 注意事项

1. 该模块使用SQLite作为数据库引擎
2. 所有表都使用IF NOT EXISTS语法，不会覆盖现有表
3. 数据库操作会自动提交事务
4. 错误会记录到日志中

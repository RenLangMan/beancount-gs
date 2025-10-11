# 002 - 数据提取模块 (rule_extractor.py)

## 功能概述

`rule_extractor.py` 是规则处理系统的数据提取模块，负责从beancount账本文件中提取交易数据并存储到SQLite数据库中。

## 依赖项

- beancount (可选，但需要安装才能加载账本文件)
- Python 3.6+

## 主要类和方法

### DataExtractor 类

数据提取器，提供从beancount账本提取交易数据的功能。

#### 初始化方法

```python
def __init__(self, ledger_dir: str, db_file: str, logger: Optional[logging.Logger] = None)
```

- `ledger_dir`: beancount账本文件所在目录
- `db_file`: 数据库文件路径
- `logger`: 可选的自定义日志记录器

#### 主要方法

1. `load_beancount_files() -> bool`
   - 加载指定目录下的beancount账本文件
   - 返回True表示成功，False表示失败

2. `extract_transactions() -> bool`
   - 将加载的交易数据提取到数据库
   - 返回True表示成功，False表示失败

3. `get_loaded_entries_count() -> int`
   - 获取已加载的条目数量

## 使用示例

```python
from rule_extractor import DataExtractor
import logging

# 初始化日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("DataExtractorExample")

# 创建数据提取器
extractor = DataExtractor(
    ledger_dir="/path/to/beancount/files",
    db_file="rules.db",
    logger=logger
)

# 加载beancount文件
if extractor.load_beancount_files():
    print(f"成功加载 {extractor.get_loaded_entries_count()} 个条目")
    
    # 提取交易数据到数据库
    if extractor.extract_transactions():
        print("交易数据提取成功")
    else:
        print("交易数据提取失败")
else:
    print("beancount文件加载失败")
```

## 数据存储结构

提取的数据将存储到以下数据库表中：

1. `beancount_entries` - 存储交易条目基本信息
2. `entry_meta` - 存储交易条目的元数据
3. `entry_postings` - 存储交易的分录数据

## 注意事项

1. 需要先安装beancount库才能加载账本文件
2. 模块会自动查找目录下的`main.bean`、`*.beancount`或`index.bean`文件作为主文件
3. 每次提取会清空现有的`beancount_entries`、`entry_meta`和`entry_postings`表
4. 错误会记录到日志中

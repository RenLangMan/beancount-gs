# 004 - 规则生成器主模块 (rule_generator.py)

## 功能概述

`rule_generator.py` 是规则处理系统的主入口模块，负责协调整个规则处理流程，包括数据库初始化、数据提取、规则分析和规则导出四个主要步骤。

## 主要功能

### 四步执行流程

1. **初始化数据库** (`--init`)
   - 创建SQLite数据库和表结构
2. **加载并提取数据** (`--load-extract`)
   - 从beancount账本加载交易数据
   - 提取交易数据到数据库
3. **分析数据生成规则** (`--analyze`)
   - 分析交易数据并生成分类规则
4. **生成规则文件** (`--generate`)
   - 将规则导出为YAML格式文件

## 命令行使用说明

### 必选参数

- `--ledger-id <ID>`: 指定账本ID (必选)

### 操作流程参数

- `--init`: 执行步骤1 - 初始化数据库
- `--load-extract`: 执行步骤2 - 加载账本并提取交易数据
- `--analyze`: 执行步骤3 - 分析交易数据生成规则
- `--generate [FILE]`: 执行步骤4 - 生成YAML规则文件(默认: rules.yaml)

### 辅助参数

- `--debug`: 启用调试模式
- `--help`: 显示帮助信息

## 使用示例

### 完整流程执行

```bash
python /workspace/importer/rule_generator.py  --ledger-id 3978d009748ef54ad6ef7bf851bd55491b1fe6bb --init --load-extract --analyze --generate
```

### 分步执行

1. 初始化数据库:

   ```bash
   python /workspace/importer/rule_generator.py  --ledger-id 3978d009748ef54ad6ef7bf851bd55491b1fe6bb --init
   ```

2. 加载并提取数据:

   ```bash
   python /workspace/importer/rule_generator.py --ledger-id 3978d009748ef54ad6ef7bf851bd55491b1fe6bb --load-extract
   ```

3. 分析规则:

   ```bash
   python /workspace/importer/rule_generator.py --ledger-id 3978d009748ef54ad6ef7bf851bd55491b1fe6bb --analyze
   ```

4. 生成规则文件:

   ```bash
   python /workspace/importer/rule_generator.py --ledger-id 3978d009748ef54ad6ef7bf851bd55491b1fe6bb --generate my_rules.yaml
   ```

## 模块结构

### RuleGenerator 类

协调整个规则处理流程的主类。

#### 初始化方法

```python
def __init__(self, ledger_dir: str = ".", db_file: Optional[str] = None)
```

- `ledger_dir`: beancount账本目录
- `db_file`: 数据库文件路径（默认为`ledger_dir/importer/account_rules.db`）

#### 主要方法

1. `init_database() -> bool`
   - 初始化数据库（步骤1）

2. `load_and_extract() -> bool`
   - 加载账本并提取数据（步骤2）

3. `analyze_rules() -> bool`
   - 分析规则（步骤3）

4. `generate_rules(output_file: str) -> bool`
   - 生成规则文件（步骤4）

## 日志和配置

- 日志文件默认存储在`ledger_dir/importer/logs/rule_generator.log`
- 账本配置从`data/beancount/ledger_config.json`读取
- 调试模式可通过`--debug`参数启用

## 注意事项

1. 必须提供`--ledger-id`参数
2. 步骤之间有依赖关系，建议按顺序执行
3. 数据库文件默认存储在账本目录下的`importer`子目录
4. 错误信息会记录到日志文件和标准输出

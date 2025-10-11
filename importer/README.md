# Beancount 支付宝/微信支付导入器

一个将支付宝和微信支付账单转换为Beancount格式的工具。

## 功能特性

- 支持支付宝和微信支付的CSV账单导入
- 基于规则的交易分类
- 自动去重处理
- 生成符合Beancount格式的账本文件

## 安装

1. 确保已安装Go 1.16+
2. 克隆本仓库
3. 构建项目:

```bash
go build -o importer
```

## 使用说明

### 基本用法

```bash
./importer -csv alipay_record.csv -rules rules.yaml -output output.bean
```

### 参数说明

- `-csv`: 支付宝或微信支付的CSV账单文件路径
- `-rules`: 规则配置文件路径
- `-output`: 生成的Beancount文件路径

## 规则文件配置

规则文件使用YAML格式，示例见[example_rules.yaml](example_rules.yaml)。

### 支付规则

定义如何根据支付方式和交易类型匹配账户:

```yaml
payment_rules:
  - name: "支付宝余额消费"
    payment_method: "余额"
    transaction_type: "消费"
    debit_accounts: ["Expenses:Food"]
    credit_accounts: ["Assets:Alipay"]
```

### 对方规则

定义如何根据对方名称和描述匹配分类:

```yaml
counterparty_rules:
  - name: "餐饮商家"
    counterparty: "餐厅"
    description: "餐饮"
    category: "餐饮"
    account: "Expenses:Food"
```

## 开发

### 运行测试

```bash
go test ./...
```

### 添加新导入器

1. 在`modules`目录下创建新包
2. 实现`Importer`接口
3. 添加检测函数(如`IsXXXCSV`)
4. 编写测试用例

## 贡献

欢迎提交Issue和Pull Request。

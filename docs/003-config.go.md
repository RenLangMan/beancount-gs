# 003-config.go

## 文件概述
`config.go` 是 beancount-gs 项目中负责配置管理的核心文件。该文件实现了服务器配置、账本配置、账户配置和货币配置的加载、更新和管理功能，是项目配置系统的核心组件。

## 主要功能
1. **服务器配置管理**：加载、更新和获取服务器全局配置
2. **账本配置管理**：管理多个账本的配置信息
3. **账户管理**：加载和管理账户信息
4. **货币管理**：支持多币种配置和汇率更新
5. **虚拟环境管理**：管理 beancount 虚拟环境的路径和执行器

## 关键组件

### 全局变量
- `serverSecret`：服务器密钥
- `serverConfig`：服务器配置
- `serverCurrencies`：支持的货币列表
- `ledgerConfigMap`：账本配置映射
- `ledgerAccountsMap`：账本账户映射
- `ledgerAccountTypesMap`：账本账户类型映射
- `ledgerCurrencyMap`：账本货币映射
- `whiteList`：白名单列表
- `venvPath`：虚拟环境路径
- `venvExecutor`：虚拟环境执行器

### 结构体
- `Config`：配置结构体，包含账本ID、邮箱、标题、数据路径等字段
- `Account`：账户结构体，包含账户名称、开始日期、货币等字段
- `AccountCurrency`：账户货币结构体
- `AccountPosition`：账户持仓结构体
- `AccountType`：账户类型结构体
- `LedgerCurrency`：账本货币结构体
- `CommodityPrice`：商品价格结构体

### 主要函数
- **服务器配置**：
  - `GetServerConfig()`：获取服务器配置
  - `LoadServerConfig()`：加载服务器配置
  - `UpdateServerConfig()`：更新服务器配置
  - `IsDebugMode()`：获取调试模式状态
  - `SetDebugMode()`：设置调试模式

- **账本配置**：
  - `GetLedgerConfigMap()`：获取账本配置映射
  - `GetLedgerConfig()`：获取指定账本配置
  - `GetLedgerConfigByMail()`：通过邮箱获取账本配置
  - `GetLedgerConfigFromContext()`：从上下文获取账本配置
  - `LoadLedgerConfigMap()`：加载账本配置映射
  - `WriteLedgerConfigMap()`：写入账本配置映射

- **账户管理**：
  - `GetLedgerAccounts()`：获取账本账户列表
  - `GetLedgerAccount()`：获取指定账户
  - `UpdateLedgerAccounts()`：更新账本账户列表
  - `ClearLedgerAccounts()`：清除账本账户缓存
  - `LoadLedgerAccounts()`：加载账本账户
  - `GetAccountType()`：获取账户类型
  - `GetAccountPrefix()`：获取账户前缀
  - `GetAccountName()`：获取账户名称
  - `GetAccountIconName()`：获取账户图标名称

- **账户类型管理**：
  - `GetLedgerAccountTypes()`：获取账本账户类型映射
  - `UpdateLedgerAccountTypes()`：更新账本账户类型映射
  - `ClearLedgerAccountTypes()`：清除账本账户类型缓存
  - `LoadLedgerAccountTypesMap()`：加载账本账户类型映射

- **货币管理**：
  - `LoadServerCurrencyMap()`：加载服务器货币映射
  - `LoadLedgerCurrencyMap()`：加载账本货币映射
  - `GetLedgerCurrency()`：获取账本货币列表
  - `GetLedgerCurrencyMap()`：获取账本货币映射
  - `RefreshLedgerCurrency()`：刷新账本货币汇率
  - `GetCommoditySymbol()`：获取商品符号
  - `GetServerCommoditySymbol()`：获取服务器商品符号

- **虚拟环境管理**：
  - `SetVenvPath()`：设置虚拟环境路径
  - `GetVenvPath()`：获取虚拟环境路径
  - `SetVenvExecutor()`：设置虚拟环境执行器
  - `GetVenvExecutor()`：获取虚拟环境执行器

- **日志和调试**：
  - `DebugLog()`：输出调试日志
  - `DebugLogWithContext()`：输出带上下文的调试日志
  - `WarnLogWithContext()`：输出带上下文的警告日志

### 辅助函数
- `GenerateServerSecret()`：生成服务器密钥
- `EqualServerSecret()`：比较服务器密钥
- `IsInWhiteList()`：检查是否在白名单中
- `handleCompatible()`：处理兼容性问题
- `newCommodityPriceListFromString()`：从字符串创建商品价格列表

## 技术特点
- 使用 JSON 格式存储配置信息
- 支持多账本、多币种管理
- 实现了配置的缓存机制，提高访问效率
- 使用互斥锁保证并发安全
- 支持调试模式和日志记录
- 提供了完整的账户和货币管理功能
- 支持虚拟环境的管理和执行

## 注意事项
- 配置文件路径需要正确设置
- 账本配置需要定期刷新以获取最新汇率
- 虚拟环境路径需要正确配置以确保 beancount 命令能够正常执行
- 白名单功能用于控制账本访问权限
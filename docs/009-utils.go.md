# 009-utils.go

## 文件概述
`utils.go` 是 beancount-gs 项目中负责提供各种实用功能的工具文件。该文件包含了一系列辅助函数，用于处理随机字符串生成、IP地址获取、日期处理、编码转换等常见任务，是项目中功能多样化的工具集合。

## 主要功能
1. **命令检查**：检查系统命令是否存在
2. **IP地址获取**：获取本地非回环IP地址
3. **随机字符串生成**：生成指定长度的随机字符串
4. **日期处理**：日期字符串转时间戳、获取两个日期中的最大值
5. **编码转换**：GBK编码转UTF-8编码
6. **月份提取**：从日期字符串中提取月份

## 关键组件

### 命令检查函数
- `checkCommandExists(command string) bool`：检查系统命令是否存在

### 网络相关函数
- `GetIpAddress() string`：获取本地非回环IP地址

### 随机字符串生成
- `RandChar(size int) string`：生成指定长度的随机字符串

### 日期处理函数
- `getTimeStamp(str_date string) Timestamp`：日期字符串转为时间戳
- `getMaxDate(str_date1 string, str_date2 string) string`：获取两个日期中的最大值

### 编码转换函数
- `ConvertGBKToUTF8(gbkStr string) (string, error)`：将GBK编码的字符串转换为UTF-8编码

### 月份处理函数
- `GetMonth(date string) (string, error)`：从日期字符串中提取月份

## 技术特点
- 使用Go标准库的`net`、`time`、`math/rand`等包
- 支持Windows系统的GBK编码转换
- 实现了高效的随机字符串生成算法
- 提供了日期处理的实用函数
- 使用`golang.org/x/text/encoding/simplifiedchinese`包处理中文编码转换
- 实现了错误处理和日志记录

## 应用场景
- 生成随机密钥或令牌
- 获取服务器IP地址
- 处理中文编码问题
- 比较和转换日期
- 检查系统命令是否可用
- 从日期中提取月份信息

## 注意事项
- `ConvertGBKToUTF8`函数仅在Windows系统下有效
- 随机字符串生成使用当前时间作为种子
- 日期处理函数需要特定格式的输入
- IP地址获取可能返回空字符串
- 命令检查仅适用于简单的命令验证
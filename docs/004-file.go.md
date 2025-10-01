# 004-file.go

## 文件概述
`file.go` 是 beancount-gs 项目中负责文件操作的工具文件。该文件提供了一系列函数用于文件的读取、写入、创建、复制、目录管理以及文本处理等操作，是项目中文件系统交互的核心组件。

## 主要功能
1. **文件基本操作**：检查文件存在、读取文件、写入文件、追加文件内容
2. **文件创建管理**：创建文件、创建目录、复制文件和目录
3. **文本处理**：查找和删除特定文本行、处理多行文本、清理字符串
4. **行操作**：删除指定行范围、插入多行文本

## 关键组件

### 文件基本操作函数
- `FileIfExist(filePath string) bool`：检查文件是否存在
- `ReadFile(filePath string) ([]byte, error)`：读取文件内容
- `WriteFile(filePath string, content string) error`：写入文件内容
- `AppendFileInNewLine(filePath string, content string) error`：在文件末尾追加新行
- `DeleteLinesWithText(filePath string, textToDelete string) error`：删除包含特定文本的行

### 文件创建管理函数
- `CreateFile(filePath string) error`：创建文件，如果目录不存在则创建目录
- `CreateFileIfNotExist(filePath string) error`：如果文件不存在则创建
- `CopyFile(sourceFilePath string, targetFilePath string) error`：复制文件
- `CopyDir(sourceDir string, targetDir string) error`：复制目录及其内容
- `MkDir(dirPath string) error`：创建目录
- `EnsureDirExists(path string) error`：确保目录存在，不存在则创建
- `WriteFileWithDir(filename string, data string) error`：写入文件，确保目录存在

### 文本处理函数
- `FindConsecutiveMultilineTextInFile(filePath string, multilineLines []string) (startLine, endLine int, err error)`：查找文件中连续多行文本片段的开始和结束行号
- `CleanString(str string) string`：清理字符串，去除空白和特殊字符
- `getAccountWithNumber(str string) string`：使用正则表达式提取账户和金额信息
- `IsComment(line string) bool`：检查行是否为注释

### 行操作函数
- `RemoveLines(filePath string, startLineNo, endLineNo int) ([]string, error)`：删除指定行范围的内容
- `InsertLines(lines []string, startLineNo int, newLines []string) ([]string, error)`：在指定行号插入多行文本
- `WriteToFile(filePath string, lines []string) error`：将行数组写回文件

## 技术特点
- 使用 Go 标准库的 `os`、`io/ioutil`、`bufio` 等包进行文件操作
- 实现了完整的文件读写、创建、复制功能
- 提供了目录操作和管理功能
- 支持文本处理和行操作
- 使用正则表达式进行文本匹配和提取
- 实现了日志记录，记录文件操作的成功和失败
- 提供了错误处理机制

## 应用场景
- 读取和写入配置文件
- 创建和管理账本文件
- 复制模板文件到新账本
- 处理 beancount 文本格式的账本文件
- 查找和修改特定交易记录
- 插入新的交易记录
- 删除过期或无效的交易记录
- 确保目录结构正确

## 注意事项
- 文件路径需要正确设置
- 文件操作可能会失败，需要正确处理错误
- 文本处理函数针对 beancount 格式进行了优化
- 复制目录时需要确保源目录存在
- 写入文件时会覆盖原有内容，需要谨慎使用
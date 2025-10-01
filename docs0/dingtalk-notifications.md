# 钉钉通知脚本使用说明

## 功能概述
`dingtalk_notify.sh` 是一个用于发送钉钉通知的Shell脚本，专为beancount-gs项目定制。它支持多种通知类型，包括构建状态、数据同步、报表生成等，并提供了丰富的Markdown格式化选项。

## 安装与配置

1. **脚本位置**
   - 脚本位于项目根目录的`.scripts`文件夹中：`/.scripts/dingtalk_notify.sh`

2. **设置执行权限**
   ```bash
   chmod +x /.scripts/dingtalk_notify.sh
   ```

3. **钉钉机器人配置**
   - 在钉钉群中创建自定义机器人
   - 获取Webhook地址和签名密钥

## 环境变量配置

### 必需变量
| 变量名 | 描述 | 示例 |
|--------|------|------|
| `DINGTALK_WEBHOOK` | 钉钉机器人Webhook地址 | `https://oapi.dingtalk.com/robot/send?access_token=xxx` |
| `DINGTALK_SECRET` | 钉钉机器人签名密钥(可选) | `SECxxxx` |

### 可选变量
| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `NOTIFICATION_TYPE` | 通知类型 | `default` |
| `NOTIFICATION_STATUS` | 通知状态 | `success` |
| `DINGTALK_AT_MOBILES` | 要@的手机号(多个用分号分隔) | - |
| `SEND_NOTIFICATION` | 是否发送通知 | `true` |
| `DEBUG_MODE` | 启用调试输出 | `false` |
| `SILENT_MODE` | 静默模式(不输出信息) | `false` |

## 通知类型说明

### 可用通知类型
1. **`build_start`** - 构建开始通知
2. **`build_complete`** - 构建完成通知
3. **`sync`** - 数据同步通知
4. **`report_generation`** - 报表生成通知
5. **`data_import`** - 数据导入通知
6. **`account_update`** - 账户更新通知
7. **`gs_sync`** - Google Sheets同步通知

## 使用示例

### 基本用法
```bash
export DINGTALK_WEBHOOK="your_webhook_url"
export NOTIFICATION_TYPE="sync"
/.scripts/dingtalk_notify.sh
```

### 同步成功通知
```bash
export DINGTALK_WEBHOOK="your_webhook_url"
export NOTIFICATION_TYPE="sync"
export NOTIFICATION_STATUS="success"
export TARGET_REPO_NAME="Gitee/beancount-gs"
export TARGET_GIT_BRANCH="feat-beanquery-cnb/dev"
export TARGET_REPO_URL="https://gitee.com/xxx"
/.scripts/dingtalk_notify.sh
```

### 报表生成失败通知
```bash
export DINGTALK_WEBHOOK="your_webhook_url"
export NOTIFICATION_TYPE="report_generation"
export NOTIFICATION_STATUS="failure"
export REPORT_TYPE="月度财务报表"
export REPORT_PERIOD="2023年9月"
/.scripts/dingtalk_notify.sh
```

## 集成到CI/CD

在`.cnb.yml`中的示例集成：
```yaml
script: |
  # ...同步操作代码...
  
  if [ -n "$DINGTALK_WEBHOOK" ]; then
    export NOTIFICATION_TYPE="sync"
    export NOTIFICATION_STATUS="success"
    export TARGET_REPO_NAME="Gitee/beancount-gs"
    export TARGET_GIT_BRANCH="feat-beanquery-cnb/dev"
    /.scripts/dingtalk_notify.sh
  fi
```

## 调试与故障排查

1. **启用调试模式**
   ```bash
   export DEBUG_MODE=true
   /.scripts/dingtalk_notify.sh
   ```

2. **常见问题**
   - **通知未发送**：检查`DINGTALK_WEBHOOK`是否正确
   - **签名错误**：确认`DINGTALK_SECRET`与钉钉机器人配置匹配
   - **格式问题**：检查特殊字符是否被正确转义

3. **查看日志**
   - 脚本会输出详细的执行日志
   - 在CI/CD环境中查看构建日志

## 通知模板定制

如需修改通知内容，可以编辑脚本中的对应模板部分。每个通知类型都有专门的Markdown模板函数。

> 注意：修改脚本后请测试所有通知类型以确保兼容性。
# Beancount 菜单系统说明

## 菜单层次

1. **主菜单 (`beancount_main.sh`)**
   - 提供主要功能入口，包括账本操作、Git 操作和通知设置。
   - 依赖以下模块：
     - `beancount_functions.sh`：账本功能函数库。
     - `beancount_git.sh`：Git 操作函数库。
     - `beancount_notify.sh`：通知功能函数库。
     - `beancount_env.sh`：环境配置函数库。

2. **账本操作 (`beancount_functions.sh`)**
   - 提供账本检查、报表生成和交易导入等功能。
   - 依赖环境变量配置（通过 `beancount_env.sh`）。

3. **Git 操作 (`beancount_git.sh`)**
   - 提供 Git 仓库克隆、快速推送、拉取和状态检查等功能。
   - 依赖全局 Git 配置和路径设置（通过 `beancount_env.sh`）。

4. **通知功能 (`beancount_notify.sh`)**
   - 提供钉钉通知功能。
   - 依赖外部 Webhook URL 和网络连接。

5. **环境配置 (`beancount_env.sh`)**
   - 提供多平台路径配置和环境清理功能。
   - 支持 Linux 和 Windows 平台。

## 依赖函数说明

### 主菜单 (`beancount_main.sh`)

- `load_modules`：加载所有功能模块。
- `detect_platform`：检测当前运行平台。

### 账本操作 (`beancount_functions.sh`)

- `print_info` / `print_success` / `print_warning` / `print_error`：日志打印函数。
- `setup_paths`：配置平台路径。
- `clean_environment`：清理环境。

### Git 操作 (`beancount_git.sh`)

- `setup_git_config`：设置 Git 全局配置。
- `git_clone_repo`：克隆仓库。
- `git_quick_push`：快速推送更改。

### 通知功能 (`beancount_notify.sh`)

- `send_dingtalk_notification`：发送钉钉通知。

### 环境配置 (`beancount_env.sh`)

- `setup_paths`：配置多平台路径。

## 使用说明

1. 运行 `beancount_main.sh` 启动主菜单。
2. 根据菜单选项选择功能模块。
3. 各模块功能独立，但依赖环境配置和全局函数库。

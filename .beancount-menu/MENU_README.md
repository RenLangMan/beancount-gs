# beancount-菜单系统说明

## 1. **主菜单 (`beancount_main.sh`)**

- **功能**：提供主要功能入口，包括账本操作、Git 操作和通知设置。
- **依赖模块**：
  - `beancount_functions.sh`：账本功能函数库。
  - `beancount_git.sh`：Git 操作函数库。
  - `beancount_notify.sh`：通知功能函数库。
  - `beancount_env.sh`：环境配置函数库。
- **核心函数**：
  - `load_modules`：加载所有功能模块。
  - `detect_platform`：检测当前运行平台。
  - `show_main_menu`：显示主菜单选项。
  - `handle_menu_selection`：处理菜单选择。

## 2. **账本操作 (`beancount_functions.sh`)**

- **功能**：提供账本检查、报表生成和交易导入等功能。
- **依赖环境变量**：通过 `beancount_env.sh` 配置。
- **核心函数**：
  - `print_info` / `print_success` / `print_warning` / `print_error`：日志打印函数。
  - `setup_paths`：配置平台路径。
  - `clean_environment`：清理环境。
  - `setup_environment_fast` / `setup_environment_clean`：快速或完整环境设置。
  - `create_virtualenv`：创建虚拟环境。
  - `install_dependencies`：安装 Python 依赖。

## 3. **Git 操作 (`beancount_git.sh`)**

- **功能**：提供 Git 仓库克隆、快速推送、拉取和状态检查等功能。
- **依赖全局 Git 配置**：通过 `beancount_env.sh` 设置。
- **核心函数**：
  - `setup_git_config`：设置 Git 全局配置。
  - `git_clone_repo`：克隆仓库。
  - `git_quick_push`：快速推送更改。
  - `git_status`：查看状态。
  - `git_pull`：拉取更新。
  - `git_custom_commit`：自定义提交。
  - `git_branch_management`：分支管理。

## 4. **通知功能 (`beancount_notify.sh`)**

- **功能**：提供钉钉通知功能。
- **依赖外部 Webhook URL** 和网络连接。
- **核心函数**：
  - `send_dingtalk_notification`：发送钉钉通知。

## 5. **环境配置 (`beancount_env.sh`)**

- **功能**：提供多平台路径配置和环境清理功能。
- **支持平台**：Linux 和 Windows。
- **核心函数**：
  - `setup_paths`：配置多平台路径。
  - `environment_diagnosis`：环境诊断。
  - `environment_repair_tool`：环境修复工具。
  - `environment_backup` / `environment_restore`：环境备份与恢复。
  - `environment_cleanup`：环境清理。

---

### 使用说明

1. 运行 `beancount_main.sh` 启动主菜单。
2. 根据菜单选项选择功能模块。
3. 各模块功能独立，但依赖环境配置和全局函数库。

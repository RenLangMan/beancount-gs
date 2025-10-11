

###
 # @Author: liangzai450
 # @Date: 2025-10-05 16:18:41
 # @LastEditors: liangzai450
 # @LastEditTime: 2025-10-05 22:51:05
 # @FilePath: \\beancount-gs\\.beancount-menu\\beancount_notify.sh
 # @Description: #!/bin/bash

# 通知功能函数库 - Beancount 跨平台管理

# 通知配置
NOTIFY_CONFIG_FILE="$SCRIPT_DIR/.notify_config"
DINGTALK_CONFIG_FILE="$SCRIPT_DIR/.dingtalk_config"

# 初始化通知配置
init_notify_config() {
    print_info "初始化通知配置..."
    
    # 创建默认配置目录
    mkdir -p "$(dirname "$NOTIFY_CONFIG_FILE")"
    mkdir -p "$(dirname "$DINGTALK_CONFIG_FILE")"
    
    # 设置默认配置
    if [ ! -f "$NOTIFY_CONFIG_FILE" ]; then
        cat > "$NOTIFY_CONFIG_FILE" << EOF
# Beancount 通知配置
NOTIFICATION_ENABLED=true
DEFAULT_NOTIFICATION_TYPE=markdown
LOG_LEVEL=INFO
MAX_MESSAGE_LENGTH=5000
EOF
        print_success "创建默认通知配置"
    fi
    
    # 加载配置
    source "$NOTIFY_CONFIG_FILE"
    print_success "通知配置加载完成"
}

# 强制显示关键错误
show_critical_error() {
    echo -e "\033[31m[CRITICAL]\033[0m $@" >&2
    exit 1
}

# ======================= 调试控制 =======================
DEBUG_MODE=${DEBUG_MODE:-false}
SILENT_MODE=${SILENT_MODE:-false}

debug_echo() {
    if [ "$SILENT_MODE" = "true" ]; then
        return 0
    fi
    if [ "$DEBUG_MODE" = "true" ]; then
        echo -e "\033[36m[DEBUG]\033[0m $@" >&2
    fi
    return 0
}

info_echo() {
    # 总是显示，不受 SILENT_MODE 影响
    echo -e "\033[32m[INFO]\033[0m $@"
    return 0
}

error_echo() {
    # 总是显示，不受 SILENT_MODE 影响
    echo -e "\033[31m[ERROR]\033[0m $@" >&2
    return 0
}

# ======================= 钉钉发送函数 =======================
send_dingtalk_message() {
    local webhook="$1"
    local secret="$2"
    local content="$3"
    local c_type="$4"
    local at_mobiles="$5"
    local is_at_all="$6"
    
    # 检查参数
    if [ -z "$webhook" ] || [ -z "$content" ]; then
        error_echo "❌ 缺少必要参数: webhook 或 content"
        return 1
    fi
    
    debug_echo "发送参数: type=$c_type, at=$at_mobiles, isAtAll=$is_at_all"
    debug_echo "内容长度: ${#content} 字符"
    
    # 生成签名函数
    generate_sign() {
        local secret="$1"
        local timestamp=$(date +%s%3N)
        local string_to_sign="${timestamp}\n${secret}"
        
        # 使用 openssl 生成 HMAC-SHA256 签名
        local sign=$(echo -en "$string_to_sign" | openssl dgst -sha256 -hmac "$secret" -binary | base64)
        # URL 编码
        local sign_url_encoded=$(echo -n "$sign" | sed 's/+/%2B/g; s/\//%2F/g; s/=/%3D/g')
        
        echo "$timestamp $sign_url_encoded"
    }
    
    # 格式化@手机号
    format_at_mobiles() {
        local at_mobiles="$1"
        if [ -n "$at_mobiles" ]; then
            # 将分号分隔转换为JSON数组格式
            echo "$at_mobiles" | tr ';' '\n' | grep -v '^$' | sed 's/^/"/;s/$/"/' | tr '\n' ',' | sed 's/,$//'
        else
            echo ""
        fi
    }
    
    # 构建消息体 - 使用 jq 确保正确的 JSON 格式
    build_message() {
        local content="$1"
        local c_type="$2"
        local at_mobiles="$3"
        local is_at_all="$4"
        
        # 使用 jq 构建正确的 JSON
        case "$c_type" in
            "text")
                jq -n \
                  --arg content "$content" \
                  --argjson at_mobiles "[$at_mobiles]" \
                  --argjson is_at_all "$is_at_all" \
                  '{
                    msgtype: "text",
                    text: {
                        content: $content
                    },
                    at: {
                        atMobiles: $at_mobiles,
                        isAtAll: $is_at_all
                    }
                }'
                ;;
            "markdown")
                jq -n \
                  --arg content "$content" \
                  --argjson at_mobiles "[$at_mobiles]" \
                  --argjson is_at_all "$is_at_all" \
                  '{
                    msgtype: "markdown",
                    markdown: {
                        title: "Beancount-GS通知",
                        text: $content
                    },
                    at: {
                        atMobiles: $at_mobiles,
                        isAtAll: $is_at_all
                    }
                }'
                ;;
            *)
                error_echo "不支持的 message type: $c_type"
                return 1
                ;;
        esac
    }
    
    # 主发送逻辑
    local formatted_at=$(format_at_mobiles "$at_mobiles")
    local message=$(build_message "$content" "$c_type" "$formatted_at" "$is_at_all")
    
    if [ "$DEBUG_MODE" = "true" ]; then
        debug_echo "消息体:"
        echo "$message" | jq .
        debug_echo "消息体长度: ${#message} 字符"
    fi
    
    # 如果有密钥，生成签名URL
    local final_url="$webhook"
    if [ -n "$secret" ]; then
        read timestamp sign <<< $(generate_sign "$secret")
        local separator="?"
        if [[ "$webhook" == *"?"* ]]; then
            separator="&"
        fi
        final_url="${webhook}${separator}timestamp=${timestamp}&sign=${sign}"
        
        debug_echo "带签名URL: $final_url"
    fi
    
    # 发送请求 - 添加详细的调试信息
    info_echo "正在发送钉钉通知..."
    
    if [ "$DEBUG_MODE" = "true" ]; then
        debug_echo "curl 命令:"
        debug_echo "curl -X POST '$final_url' -H 'Content-Type: application/json' -d '$message'"
    fi
    
    # 使用临时文件确保 JSON 格式正确
    local temp_file=$(mktemp)
    echo "$message" > "$temp_file"
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$final_url" \
        -H "Content-Type: application/json" \
        --data-binary "@$temp_file" 2>/dev/null)
    
    # 清理临时文件
    rm -f "$temp_file"
    
    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | sed '$d')
    
    if [ "$DEBUG_MODE" = "true" ]; then
        debug_echo "HTTP 状态码: $http_code"
        debug_echo "响应体: $response_body"
    fi
    
    if [ "$http_code" -eq 200 ]; then
        local errcode=$(echo "$response_body" | jq -r '.errcode' 2>/dev/null || echo "unknown")
        if [ "$errcode" -eq 0 ]; then
            info_echo "✅ 钉钉通知发送成功!"
            return 0
        else
            error_echo "❌ 钉钉API错误: $response_body"
            return 1
        fi
    else
        error_echo "❌ HTTP错误: $http_code"
        error_echo "响应: $response_body"
        return 1
    fi
}

# 时间格式化函数
format_duration_smart() {
    local seconds=$1
    (( seconds = seconds > 0 ? seconds : 0 ))
    
    local hours=$((seconds/3600))
    local mins=$((seconds%3600/60))
    local secs=$((seconds%60))
    
    if (( hours > 0 )); then
        printf "%d小时%02d分钟%02d秒" "$hours" "$mins" "$secs"
    elif (( mins > 0 )); then
        printf "%d分钟%02d秒" "$mins" "$secs"
    else
        printf "%d秒" "$secs"
    fi
}

# 根据不同的通知类型生成不同的内容模板
generate_notification_content() {
    local notification_type="${1:-build}"
    local status="${2:-success}"
    local additional_info="${3:-}"
    
    # 设置默认环境变量（用于独立运行）
    CNB_BUILD_ID=${CNB_BUILD_ID:-"build-$(date +%s)"}
    CNB_REPO_NAME=${CNB_REPO_NAME:-"beancount-ledger"}
    CNB_BRANCH=${CNB_BRANCH:-"main"}
    CNB_COMMIT_SHORT=${CNB_COMMIT_SHORT:-"$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"}
    CNB_COMMIT_MESSAGE_TITLE=${CNB_COMMIT_MESSAGE_TITLE:-"自动构建"}
    CNB_COMMITTER=${CNB_COMMITTER:-"$(git config user.name 2>/dev/null || echo "Beancount User")"}
    CNB_COMMITTER_EMAIL=${CNB_COMMITTER_EMAIL:-"$(git config user.email 2>/dev/null || echo "beancount@example.com")"}
    CNB_BUILD_WEB_URL=${CNB_BUILD_WEB_URL:-"https://cnb.cool"}
    CNB_REPO_URL_HTTPS=${CNB_REPO_URL_HTTPS:-"https://cnb.cool/ysundy/bean/example-beanbook"}
    
    # 计算构建耗时（如果提供了开始时间）
    local build_duration=""
    if [ -n "$CNB_BUILD_START_TIME" ]; then
        local start_ts=$(date -d "${CNB_BUILD_START_TIME}" +%s 2>/dev/null || date +%s)
        local end_ts=$(date +%s)
        local duration_seconds=$((end_ts - start_ts))
        build_duration=$(format_duration_smart $duration_seconds)
    fi
    
    local start_time=$(TZ='Asia/Shanghai' date -d "${CNB_BUILD_START_TIME:-now}" '+%Y-%m-%d %H:%M:%S')
    
    local status_icon="✅"
    local status_text="成功"
    local status_color="green"
    
    if [ "$status" != "success" ]; then
        status_icon="❌"
        status_text="失败"
        status_color="red"
    fi
    
    case "$notification_type" in
        "build_start")
            cat <<EOF
# 🚀 Beancount-GS构建开始

## 📋 构建信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 提交: ${CNB_COMMIT_SHORT}  
- 提交信息: ${CNB_COMMIT_MESSAGE_TITLE}  
- 提交者: ${CNB_COMMITTER}  
- 开始时间: ${start_time}  

## 🔗 相关链接
- [查看构建详情](${CNB_BUILD_WEB_URL})  
- [查看代码仓库](${CNB_REPO_URL_HTTPS})  

---  
*构建已启动，请等待完成通知*  
EOF
            ;;
            
        "build_complete")
            cat <<EOF
# ${status_icon} Beancount-GS构建${status_text}

## 📋 构建信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 提交: ${CNB_COMMIT_SHORT}  
- 提交信息: ${CNB_COMMIT_MESSAGE_TITLE}  
- 提交者: ${CNB_COMMITTER}  
- 开始时间: ${start_time}  
${build_duration:+- 构建耗时: ${build_duration}  }
- 构建状态: <font color="${status_color}">${status_text}</font>  
${additional_info:+- 附加信息: ${additional_info}  }

## 🔗 相关链接
- [查看构建详情](${CNB_BUILD_WEB_URL})  
- [查看代码仓库](${CNB_REPO_URL_HTTPS})  

---  
*此消息由Beancount-GS自动构建系统生成*  
EOF
            ;;
            
        "service_start")
            cat <<EOF
# 🚀 Beancount-GS服务启动

## 📋 服务信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 启动时间: $(date '+%Y-%m-%d %H:%M:%S')  
- 服务状态: <font color="green">已启动</font>  

## 🌐 访问信息
- Web界面: http://localhost:10000  
- 管理界面: http://localhost:10000/admin  

${additional_info:+- 启动详情: ${additional_info}  }

---  
*服务已成功启动*  
EOF
            ;;
            
        "service_stop")
            cat <<EOF
# 🛑 Beancount-GS服务停止

## 📋 服务信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 停止时间: $(date '+%Y-%m-%d %H:%M:%S')  
- 服务状态: <font color="orange">已停止</font>  

${additional_info:+- 停止详情: ${additional_info}  }

---  
*服务已安全停止*  
EOF
            ;;
            
        "error_alert")
            cat <<EOF
# 🚨 Beancount 系统告警

## ⚠️ 告警信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 告警时间: $(date '+%Y-%m-%d %H:%M:%S')  
- 错误类型: ${status}  
- 错误详情: ${additional_info}  

## 🛠️ 建议操作
1. 检查系统日志
2. 验证配置文件
3. 检查依赖状态

---  
*请及时处理此告警*  
EOF
            ;;
            
        "backup_complete")
            cat <<EOF
# 💾 数据备份完成

## 📋 备份信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 备份时间: $(date '+%Y-%m-%d %H:%M:%S')  
- 备份状态: <font color="${status_color}">${status_text}</font>  

## 📊 备份详情
${additional_info}

---  
*数据备份已完成*  
EOF
            ;;
            
        *)
            cat <<EOF
# 📢 Beancount 系统通知

## 📋 基本信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 时间: $(date '+%Y-%m-%d %H:%M:%S')  
- 类型: ${notification_type}  
- 状态: <font color="${status_color}">${status_text}</font>  

## 📝 通知详情
${additional_info:-无附加信息}

---  
*此消息由Beancount管理系统自动生成*  
EOF
            ;;
    esac
}

# 发送构建通知
send_build_notification() {
    local notification_type="$1"
    local status="$2"
    local additional_info="$3"
    
    if [ "$NOTIFICATION_ENABLED" != "true" ]; then
        print_info "通知功能已禁用"
        return 0
    fi
    
    # 加载钉钉配置
    if [ -f "$DINGTALK_CONFIG_FILE" ]; then
        source "$DINGTALK_CONFIG_FILE"
    else
        print_warning "钉钉配置不存在，跳过通知"
        return 0
    fi
    
    if [ -z "$DINGTALK_WEBHOOK" ]; then
        print_warning "钉钉 Webhook 未设置，跳过通知"
        return 0
    fi
    
    # 生成通知内容
    local content=$(generate_notification_content "$notification_type" "$status" "$additional_info")
    
    # 转义特殊字符
    content=$(echo "$content" | sed -e 's/"/\\"/g' -e 's/\\n/\\\\n/g')
    
    # 发送通知
    print_info "发送 $notification_type 通知..."
    send_dingtalk_message \
        "$DINGTALK_WEBHOOK" \
        "$DINGTALK_SECRET" \
        "$content" \
        "markdown" \
        "$DINGTALK_AT_MOBILES" \
        "false"
}

# 快速通知发送
quick_notification() {
    print_info "快速通知发送"
    
    echo ""
    print_menu "选择通知类型:"
    echo "1. 构建开始"
    echo "2. 构建成功"
    echo "3. 构建失败"
    echo "4. 服务启动"
    echo "5. 服务停止"
    echo "6. 错误告警"
    echo "7. 备份完成"
    echo "8. 自定义消息"
    
    read -p "请选择 [1-8]: " notify_choice
    
    local notification_type=""
    local status="success"
    local additional_info=""
    
    case "$notify_choice" in
        1)
            notification_type="build_start"
            ;;
        2)
            notification_type="build_complete"
            status="success"
            ;;
        3)
            notification_type="build_complete"
            status="failed"
            ;;
        4)
            notification_type="service_start"
            ;;
        5)
            notification_type="service_stop"
            ;;
        6)
            notification_type="error_alert"
            status="error"
            ;;
        7)
            notification_type="backup_complete"
            ;;
        8)
            read -p "请输入通知标题: " custom_title
            read -p "请输入通知内容: " custom_content
            notification_type="custom"
            additional_info="**$custom_title**\n\n$custom_content"
            ;;
        *)
            print_error "无效选择"
            return 1
            ;;
    esac
    
    if [ "$notify_choice" -ne 8 ]; then
        read -p "请输入附加信息 (可选): " additional_info
    fi
    
    send_build_notification "$notification_type" "$status" "$additional_info"
}

# 钉钉配置管理
manage_dingtalk_config() {
    print_info "钉钉配置管理"
    
    # 检查现有配置
    local current_webhook=""
    local current_secret=""
    local current_at_mobiles=""
    
    if [ -f "$DINGTALK_CONFIG_FILE" ]; then
        source "$DINGTALK_CONFIG_FILE"
        current_webhook="$DINGTALK_WEBHOOK"
        current_secret="$DINGTALK_SECRET"
        current_at_mobiles="$DINGTALK_AT_MOBILES"
    fi
    
    echo ""
    print_menu "当前配置:"
    echo "  Webhook: ${current_webhook:-未设置}"
    echo "  Secret: ${current_secret:-未设置}"
    echo "  @手机号: ${current_at_mobiles:-未设置}"
    echo ""
    
    while true; do
        echo "1. 设置 Webhook"
        echo "2. 设置 Secret"
        echo "3. 设置 @手机号 (分号分隔)"
        echo "4. 测试配置"
        echo "5. 显示配置"
        echo "6. 清除配置"
        echo "7. 返回"
        
        read -p "请选择 [1-7]: " config_choice
        
        case "$config_choice" in
            1)
                read -p "请输入钉钉 Webhook URL: " webhook
                if [ -n "$webhook" ]; then
                    DINGTALK_WEBHOOK="$webhook"
                    save_dingtalk_config
                fi
                ;;
            2)
                read -p "请输入钉钉 Secret: " secret
                DINGTALK_SECRET="$secret"
                save_dingtalk_config
                ;;
            3)
                read -p "请输入要@的手机号 (分号分隔): " at_mobiles
                DINGTALK_AT_MOBILES="$at_mobiles"
                save_dingtalk_config
                ;;
            4)
                test_dingtalk_config
                ;;
            5)
                show_dingtalk_config
                ;;
            6)
                clear_dingtalk_config
                ;;
            7)
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
        
        echo ""
    done
}

# 保存钉钉配置
save_dingtalk_config() {
    cat > "$DINGTALK_CONFIG_FILE" << EOF
# 钉钉通知配置
DINGTALK_WEBHOOK="${DINGTALK_WEBHOOK}"
DINGTALK_SECRET="${DINGTALK_SECRET}"
DINGTALK_AT_MOBILES="${DINGTALK_AT_MOBILES}"
EOF
    print_success "钉钉配置已保存"
}

# 显示钉钉配置
show_dingtalk_config() {
    if [ -f "$DINGTALK_CONFIG_FILE" ]; then
        print_info "钉钉配置:"
        cat "$DINGTALK_CONFIG_FILE"
    else
        print_warning "钉钉配置不存在"
    fi
}

# 清除钉钉配置
clear_dingtalk_config() {
    if [ -f "$DINGTALK_CONFIG_FILE" ]; then
        rm -f "$DINGTALK_CONFIG_FILE"
        print_success "钉钉配置已清除"
    else
        print_info "钉钉配置不存在"
    fi
}

# 测试钉钉配置
test_dingtalk_config() {
    if [ ! -f "$DINGTALK_CONFIG_FILE" ]; then
        print_error "钉钉配置不存在，请先设置"
        return 1
    fi
    
    source "$DINGTALK_CONFIG_FILE"
    
    if [ -z "$DINGTALK_WEBHOOK" ]; then
        print_error "Webhook 未设置"
        return 1
    fi
    
    print_info "发送测试消息..."
    
    local test_content="**测试消息**\n\n这是一条来自 Beancount 管理系统的测试消息。\n\n时间: $(date '+%Y-%m-%d %H:%M:%S')\n状态: ✅ 测试成功"
    
    send_dingtalk_message \
        "$DINGTALK_WEBHOOK" \
        "$DINGTALK_SECRET" \
        "$test_content" \
        "markdown" \
        "$DINGTALK_AT_MOBILES" \
        "false"
}

# 初始化通知模块
initialize_notify_module() {
    print_info "初始化通知模块..."
    init_notify_config
    print_success "通知模块初始化完成"
}

# 自动初始化
initialize_notify_module
 # Copyright (c) 2025 by ${git_name_email}, All Rights Reserved. 
 # ==============================================
### 


#!/bin/bash
set -eo pipefail

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

# ======================= 主脚本 =======================
# 设置统一编码环境
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# 检查必要环境变量
required_vars=(
    CNB_BUILD_ID CNB_REPO_NAME
    CNB_BUILD_START_TIME CNB_COMMIT_MESSAGE_TITLE
    CNB_REPO_URL_HTTPS CNB_BUILD_WEB_URL
    CNB_BRANCH CNB_COMMIT_SHORT CNB_COMMIT
    CNB_COMMITTER CNB_COMMITTER_EMAIL
    CNB_CPUS CNB_MEMORY CNB_RUNNER_IP
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        show_critical_error "❌ 缺失必要环境变量: $var"
    fi
done

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

# 计算构建耗时
start_ts=$(date -d "${CNB_BUILD_START_TIME}" +%s)
end_ts=$(date +%s)
duration_seconds=$((end_ts - start_ts))
build_duration=$(format_duration_smart $duration_seconds)

# 格式化开始时间
start_time=$(TZ='Asia/Shanghai' date -d "${CNB_BUILD_START_TIME}" '+%Y-%m-%d %H:%M:%S')

# 根据不同的通知类型生成不同的内容模板
generate_notification_content() {
    local notification_type="${1:-build}"
    local status="${2:-success}"
    
    case "$notification_type" in
        "build_start")
            # 构建开始通知模板
            cat <<EOF
# 🚀 Beancount-GS构建开始

## 📋 构建信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 提交: [${CNB_COMMIT_SHORT}](${CNB_REPO_URL_HTTPS}/commit/${CNB_COMMIT})  
- 提交信息: ${CNB_COMMIT_MESSAGE_TITLE}  
- 提交者: [${CNB_COMMITTER}](${CNB_COMMITTER_EMAIL})  
- 开始时间: ${start_time}  

## 🔗 相关链接
- [查看构建详情](${CNB_BUILD_WEB_URL})  
- [查看代码仓库](${CNB_REPO_URL_HTTPS})  

## 📊 构建资源
- CPU: ${CNB_CPUS}  
- 内存: ${CNB_MEMORY} GB  
- 运行节点: ${CNB_RUNNER_IP}  

---  
*构建已启动，请等待完成通知*  
EOF
            ;;
            
        "build_complete")
            # 构建完成通知模板
            local status_icon="✅"
            local status_text="成功"
            local status_color="green"
            
            if [ "$status" != "success" ]; then
                status_icon="❌"
                status_text="失败"
                status_color="red"
            fi
            
            cat <<EOF
# ${status_icon} Beancount-GS构建${status_text}

## 📋 构建信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 提交: [${CNB_COMMIT_SHORT}](${CNB_REPO_URL_HTTPS}/commit/${CNB_COMMIT})  
- 提交信息: ${CNB_COMMIT_MESSAGE_TITLE}  
- 提交者: [${CNB_COMMITTER}](${CNB_COMMITTER_EMAIL})  
- 开始时间: ${start_time}  
- 构建耗时: ${build_duration}  
- 构建状态: <font color="${status_color}">${status_text}</font>  

## 🔗 相关链接
- [查看构建详情](${CNB_BUILD_WEB_URL})  
- [查看代码仓库](${CNB_REPO_URL_HTTPS})  
${SHEET_URL:+- [访问Google表格](${SHEET_URL})  }

## 📊 构建资源
- CPU: ${CNB_CPUS}  
- 内存: ${CNB_MEMORY} GB  
- 运行节点: ${CNB_RUNNER_IP}  

---  
*此消息由Beancount-GS自动构建系统生成*  
EOF
            ;;
            
        "sync")
            # 同步通知模板
            local status_icon="🔄"
            local status_text="成功"
            local status_color="green"
            
            if [ "$status" != "success" ]; then
                status_icon="❌"
                status_text="失败"
                status_color="red"
            fi
            
            cat <<EOF
# ${status_icon} 账本数据同步${status_text}

## 📋 同步信息
- 项目: ${CNB_REPO_NAME}  
- 源分支: ${CNB_BRANCH}  
- 目标仓库: ${TARGET_REPO_NAME:-未指定}  
- 目标分支: ${TARGET_GIT_BRANCH:-master}  
- 同步时间: $(date '+%Y-%m-%d %H:%M:%S')  
- 同步状态: <font color="${status_color}">${status_text}</font>  

## 🔗 相关链接
- [查看构建详情](${CNB_BUILD_WEB_URL})  
- [查看源仓库](${CNB_REPO_URL_HTTPS})  
${TARGET_REPO_URL:+- [查看目标仓库](${TARGET_REPO_URL})  }

---  
*此消息由Beancount-GS数据同步系统生成*  
EOF
            ;;
            
        "report_generation")
            # 报表生成通知模板
            local status_icon="📊"
            local status_text="成功"
            local status_color="green"
            
            if [ "$status" != "success" ]; then
                status_icon="❌"
                status_text="失败"
                status_color="red"
            fi
            
            cat <<EOF
# ${status_icon} Beancount报表生成${status_text}

## 📋 报表信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 报表类型: ${REPORT_TYPE:-财务报表}  
- 报表周期: ${REPORT_PERIOD:-月度}  
- 生成时间: $(date '+%Y-%m-%d %H:%M:%S')  
- 生成状态: <font color="${status_color}">${status_text}</font>  

## 📈 报表详情
${REPORT_SUMMARY:+- 摘要: ${REPORT_SUMMARY}  }
${REPORT_START_DATE:+- 起始日期: ${REPORT_START_DATE}  }
${REPORT_END_DATE:+- 结束日期: ${REPORT_END_DATE}  }

## 🔗 相关链接
- [查看构建详情](${CNB_BUILD_WEB_URL})  
${REPORT_URL:+- [查看报表](${REPORT_URL})  }
${SHEET_URL:+- [访问Google表格](${SHEET_URL})  }

---  
*此消息由Beancount-GS报表生成系统自动生成*  
EOF
            ;;
            
        "data_import")
            # 数据导入通知模板
            local status_icon="📥"
            local status_text="成功"
            local status_color="green"
            
            if [ "$status" != "success" ]; then
                status_icon="❌"
                status_text="失败"
                status_color="red"
            fi
            
            cat <<EOF
# ${status_icon} Beancount数据导入${status_text}

## 📋 导入信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 数据源: ${DATA_SOURCE:-未指定}  
- 导入时间: $(date '+%Y-%m-%d %H:%M:%S')  
- 导入状态: <font color="${status_color}">${status_text}</font>  

## 📊 导入统计
${IMPORT_COUNT:+- 导入记录数: ${IMPORT_COUNT}  }
${IMPORT_AMOUNT:+- 导入金额: ${IMPORT_AMOUNT}  }
${IMPORT_START_DATE:+- 起始日期: ${IMPORT_START_DATE}  }
${IMPORT_END_DATE:+- 结束日期: ${IMPORT_END_DATE}  }

## 🔗 相关链接
- [查看构建详情](${CNB_BUILD_WEB_URL})  
${SHEET_URL:+- [访问Google表格](${SHEET_URL})  }

---  
*此消息由Beancount-GS数据导入系统自动生成*  
EOF
            ;;
            
        "account_update")
            # 账户更新通知模板
            local status_icon="📝"
            local status_text="成功"
            local status_color="green"
            
            if [ "$status" != "success" ]; then
                status_icon="❌"
                status_text="失败"
                status_color="red"
            fi
            
            cat <<EOF
# ${status_icon} Beancount账户更新${status_text}

## 📋 更新信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 更新时间: $(date '+%Y-%m-%d %H:%M:%S')  
- 更新状态: <font color="${status_color}">${status_text}</font>  

## 📊 更新详情
${ACCOUNT_ADDED:+- 新增账户: ${ACCOUNT_ADDED}  }
${ACCOUNT_MODIFIED:+- 修改账户: ${ACCOUNT_MODIFIED}  }
${ACCOUNT_CLOSED:+- 关闭账户: ${ACCOUNT_CLOSED}  }

## 🔗 相关链接
- [查看构建详情](${CNB_BUILD_WEB_URL})  
- [查看代码仓库](${CNB_REPO_URL_HTTPS})  
${SHEET_URL:+- [访问Google表格](${SHEET_URL})  }

---  
*此消息由Beancount-GS账户管理系统自动生成*  
EOF
            ;;
            
        "gs_sync")
            # Google Sheets同步通知模板
            local status_icon="🔄"
            local status_text="成功"
            local status_color="green"
            
            if [ "$status" != "success" ]; then
                status_icon="❌"
                status_text="失败"
                status_color="red"
            fi
            
            cat <<EOF
# ${status_icon} Google Sheets同步${status_text}

## 📋 同步信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 同步方向: ${SYNC_DIRECTION:-双向同步}  
- 同步时间: $(date '+%Y-%m-%d %H:%M:%S')  
- 同步状态: <font color="${status_color}">${status_text}</font>  

## 📊 同步统计
${SYNC_ADDED:+- 新增记录: ${SYNC_ADDED}  }
${SYNC_MODIFIED:+- 修改记录: ${SYNC_MODIFIED}  }
${SYNC_DELETED:+- 删除记录: ${SYNC_DELETED}  }

## 🔗 相关链接
- [查看构建详情](${CNB_BUILD_WEB_URL})  
${SHEET_URL:+- [访问Google表格](${SHEET_URL})  }

---  
*此消息由Beancount-GS表格同步系统自动生成*  
EOF
            ;;
            
        *)
            # 默认通知模板
            cat <<EOF
# 📢 Beancount-GS系统通知

## 📋 基本信息
- 项目: ${CNB_REPO_NAME}  
- 分支: ${CNB_BRANCH}  
- 提交: [${CNB_COMMIT_SHORT}](${CNB_REPO_URL_HTTPS}/commit/${CNB_COMMIT})  
- 提交信息: ${CNB_COMMIT_MESSAGE_TITLE}  
- 提交者: [${CNB_COMMITTER}](${CNB_COMMITTER_EMAIL})  
- 时间: $(date '+%Y-%m-%d %H:%M:%S')  

## 🔗 相关链接
- [查看构建详情](${CNB_BUILD_WEB_URL})  
- [查看代码仓库](${CNB_REPO_URL_HTTPS})  
${SHEET_URL:+- [访问Google表格](${SHEET_URL})  }

---  
*此消息由Beancount-GS自动通知系统生成*  
EOF
            ;;
    esac
}

# 获取通知类型和状态
NOTIFICATION_TYPE="${NOTIFICATION_TYPE:-default}"
NOTIFICATION_STATUS="${NOTIFICATION_STATUS:-success}"

# 生成 Markdown 内容
MARKDOWN_CONTENT=$(generate_notification_content "$NOTIFICATION_TYPE" "$NOTIFICATION_STATUS")

# 处理特殊字符（确保在钉钉中正确显示）
MARKDOWN_CONTENT=$(echo "$MARKDOWN_CONTENT" | sed -e 's/\*/\\*/g' -e 's/_/\\_/g' -e 's/`/\\`/g')

# 设置AT人员（使用分号分隔）
at_mobiles=""
if [ "${CNB_PULL_REQUEST_LIKE}" = "true" ] && [ -n "${CNB_PULL_REQUEST_PROPOSER}" ]; then
    at_mobiles="${CNB_PULL_REQUEST_PROPOSER};${DINGTALK_AT_MOBILES}"
else
    at_mobiles="${DINGTALK_AT_MOBILES}"
fi

# 移除多余的分号
at_mobiles=$(echo "$at_mobiles" | sed 's/^;//;s/;$//')

# 调试信息
info_echo "✅ 通知内容生成成功"
if [ "$DEBUG_MODE" = "true" ]; then
    debug_echo "内容预览:"
    debug_echo "========================================="
    echo "$MARKDOWN_CONTENT"
    debug_echo "========================================="
fi

# 如果提供了钉钉配置，则发送消息
if [ -n "${DINGTALK_WEBHOOK}" ] && [ "${SEND_NOTIFICATION:-true}" = "true" ]; then
    info_echo "检测到钉钉配置，开始发送通知..."
    send_dingtalk_message \
        "${DINGTALK_WEBHOOK}" \
        "${DINGTALK_SECRET}" \
        "${MARKDOWN_CONTENT}" \
        "markdown" \
        "${at_mobiles}" \
        "false"
else
    info_echo "未检测到钉钉配置或通知被禁用，跳过发送"
    info_echo "DINGTALK_WEBHOOK: ${DINGTALK_WEBHOOK:-未设置}"
    info_echo "SEND_NOTIFICATION: ${SEND_NOTIFICATION:-true}"
fi
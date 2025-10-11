#!/bin/bash

# Git操作函数库 - Beancount 跨平台管理

# Git配置和初始化
setup_git_config() {
    print_info "设置 Git 配置..."
    
    # 设置用户名和邮箱（如果未设置）
    if [ -z "$(git config --global user.name)" ]; then
        git config --global user.name "Beancount User"
        print_info "设置 Git 用户名"
    fi
    
    if [ -z "$(git config --global user.email)" ]; then
        git config --global user.email "beancount@example.com"
        print_info "设置 Git 邮箱"
    fi
    
    # 设置推荐的全局配置
    print_info "设置推荐的 Git 配置..."
    
    # 自动设置远程跟踪分支
    git config --global push.autoSetupRemote true
    print_success "设置 push.autoSetupRemote = true"
    
    # 使用 merge 而不是 rebase
    git config --global pull.rebase false
    print_success "设置 pull.rebase = false"
    
    # 设置默认分支为 main
    git config --global init.defaultBranch main
    print_success "设置 init.defaultBranch = main"
    
    # 其他有用的配置
    git config --global core.autocrlf input
    print_success "设置 core.autocrlf = input (跨平台兼容)"
    
    git config --global core.editor "code --wait"
    print_success "设置 VSCode 为默认编辑器"
    
    git config --global credential.helper store
    print_success "设置凭证存储"
    
    # 显示当前配置
    echo ""
    print_menu "当前 Git 配置:"
    echo "  user.name: $(git config --global user.name)"
    echo "  user.email: $(git config --global user.email)"
    echo "  push.autoSetupRemote: $(git config --global push.autoSetupRemote)"
    echo "  pull.rebase: $(git config --global pull.rebase)"
    echo "  init.defaultBranch: $(git config --global init.defaultBranch)"
    
    print_success "Git 配置完成"
}

# 设置 Git 别名
setup_git_aliases() {
    print_info "设置 Git 快捷命令..."
    
    # 基础别名
    alias gp='git add . && git commit -m "Update beancount files" && git push'
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gpl='git pull'
    alias gco='git checkout'
    alias gb='git branch'
    alias gl='git log --oneline -10'
    alias gd='git diff'
    alias gds='git diff --staged'
    
    # 高级别名
    alias gcl='git clone'
    alias gfp='git fetch && git pull'
    alias grh='git reset --hard'
    alias grs='git reset --soft HEAD~1'
    alias gst='git stash'
    alias gstp='git stash pop'
    alias glg='git log --graph --oneline --all'
    alias gclean='git clean -fd && git reset --hard'
    
    # Beancount 特定别名
    alias bean-gp='git add . && git commit -m "Update beancount ledger" && git push'
    alias bean-status='git status --porcelain | grep -E "\.(bean|beancount)$"'
    alias bean-diff='git diff --name-only | grep -E "\.(bean|beancount)$"'
    alias bean-log='git log --oneline --since="1 week ago" -- "*.bean"'
    alias bean-add='git add *.bean'
    
    # 冲突解决别名
    alias gconflict='git diff --name-only --diff-filter=U'
    alias gresolve='git add'
    alias gcontinue='git rebase --continue || git merge --continue'
    
    # 分支操作别名
    alias gbd='git branch -d'
    alias gbD='git branch -D'
    alias gbm='git branch -m'
    alias gba='git branch -a'
    
    print_success "Git 别名设置完成"
    
    # 显示可用的别名
    show_git_aliases
}

# 显示 Git 别名
show_git_aliases() {
    # 在函数内部定义颜色变量，确保在 Git Bash 中可用
    
    echo ""
    echo -e "  📚 可用 Git 别名:  "
    echo ""
    
    echo -e "🔵 基础操作:"
    echo "    gp      - 快速推送 (add + commit + push)"
    echo "    gs      - 状态检查"
    echo "    ga      - 添加文件"
    echo "    gc      - 提交更改"
    echo "    gpl     - 拉取更新"
    echo "    gco     - 切换分支"
    echo "    gb      - 分支管理"
    echo "    gl      - 查看最近提交"
    echo "    gd      - 查看差异"
    echo "    gds     - 查看暂存区差异"
    
    echo ""
    echo "🟡 高级操作:"
    echo "    gcl     - 克隆仓库"
    echo "    gfp     - 获取并拉取"
    echo "    grh     - 硬重置"
    echo "    grs     - 软重置 (撤销上次提交)"
    echo "    gst     - 储藏更改"
    echo "    gstp    - 应用储藏"
    echo "    glg     - 图形化日志"
    echo "    gclean   - 清理未跟踪文件"
    
    echo ""
    echo "🟢 Beancount 专用:"
    echo "    bean-gp       - Beancount 快速推送"
    echo "    bean-status   - 检查 Beancount 文件状态"
    echo "    bean-diff     - 显示 Beancount 文件差异"
    echo "    bean-log      - 查看 Beancount 文件最近提交"
    echo "    bean-add      - 添加所有 Beancount 文件"
    
    echo ""
    echo "🔴 冲突解决:"
    echo "    gconflict    - 显示冲突文件"
    echo "    gresolve     - 标记冲突已解决"
    echo "    gcontinue    - 继续 rebase/merge"
    
    echo ""
    echo "🟣 分支管理:"
    echo "    gbd     - 删除分支"
    echo "    gbD     - 强制删除分支"
    echo "    gbm     - 重命名分支"
    echo "    gba     - 显示所有分支"
    
    echo ""
    echo "💡 提示: 使用   githelp   命令随时查看此帮助"
    echo ""
}

# 克隆仓库
git_clone_repo() {
    local repo_url=""
    local target_dir=""
    local branch=""
    
    print_info "Git 仓库克隆"
    
    # 获取用户输入
    read -p "请输入仓库URL [默认: https://cnb.cool/ysundy/bean/example-beanbook]: " repo_url
    repo_url=${repo_url:-"https://cnb.cool/ysundy/bean/example-beanbook"}
    
    read -p "请输入目标目录 [默认: $BEANCOUNT_REPO]: " target_dir
    target_dir=${target_dir:-"$BEANCOUNT_REPO"}
    
    read -p "请输入分支 [默认: 3978d009748ef54ad6ef7bf851bd55491b1fe6bb]: " branch
    branch=${branch:-"3978d009748ef54ad6ef7bf851bd55491b1fe6bb"}
    
    echo ""
    print_info "克隆配置:"
    echo "  仓库: $repo_url"
    echo "  目录: $target_dir"
    echo "  分支: $branch"
    echo ""
    
    # 检查目录是否已存在
    if [ -d "$target_dir" ]; then
        print_warning "目标目录已存在: $target_dir"
        read -p "是否删除并重新克隆? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "操作已取消"
            return 0
        fi
        print_info "删除现有目录..."
        rm -rf "$target_dir"
    fi
    
    # 创建父目录
    local parent_dir=$(dirname "$target_dir")
    mkdir -p "$parent_dir" || {
        print_error "无法创建目录: $parent_dir"
        return 1
    }
    
    # 执行克隆
    print_info "开始克隆仓库..."
    
    if [ -n "$branch" ] && [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
        git clone -b "$branch" "$repo_url" "$target_dir"
    else
        git clone "$repo_url" "$target_dir"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "仓库克隆成功"
        
        # 显示仓库信息
        cd "$target_dir" || return 1
        echo ""
        print_info "仓库信息:"
        echo "  位置: $target_dir"
        echo "  分支: $(git branch --show-current)"
        echo "  提交: $(git log --oneline -1)"
        
        return 0
    else
        print_error "仓库克隆失败"
        return 1
    fi
}

# 快速推送更改
git_quick_push() {
    local repo_path=""
    local commit_msg=""
    
    print_info "快速推送更改"
    
    # 自动选择 Git 仓库
    if ! select_git_repository; then
        return 1
    fi
    
    # 切换到仓库目录
    cd "$repo_path" || {
        print_error "无法进入仓库目录: $repo_path"
        return 1
    }
    
    # 检查是否是 Git 仓库
    if [ ! -d ".git" ]; then
        print_error "不是 Git 仓库: $repo_path"
        return 1
    fi
    
    # 检查是否有更改
    if [ -z "$(git status --porcelain)" ]; then
        print_warning "没有需要提交的更改"
        return 0
    fi
    
    # 显示更改
    echo ""
    print_info "检测到以下更改:"
    git status --short
    
    # 生成提交信息
    local push_count_file="$SCRIPT_DIR/.push_count"
    if [ -f "$push_count_file" ]; then
        local push_count=$(cat "$push_count_file")
        push_count=$((push_count + 1))
    else
        local push_count=1
    fi
    echo "$push_count" > "$push_count_file"
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local branch=$(git branch --show-current)
    
    # 检测更改类型
    local changes=$(git status --porcelain)
    local commit_prefix="beancount"
    
    if echo "$changes" | grep -q "month/.*\.bean"; then
        commit_msg="$commit_prefix: 更新月度账本 - $timestamp"
    elif echo "$changes" | grep -q "\.bean"; then
        commit_msg="$commit_prefix: 更新账本文件 - $timestamp"
    elif echo "$changes" | grep -q "importer/"; then
        commit_msg="$commit_prefix: 更新导入规则 - $timestamp"
    elif echo "$changes" | grep -q "config/"; then
        commit_msg="$commit_prefix: 更新配置文件 - $timestamp"
    else
        commit_msg="$commit_prefix: 第${push_count}次推送 - $timestamp"
    fi
    
    # 确认提交信息
    echo ""
    read -p "提交信息 [默认: $commit_msg]: " user_commit_msg
    commit_msg=${user_commit_msg:-"$commit_msg"}
    
    echo ""
    print_info "执行推送操作:"
    echo "  仓库: $repo_path"
    echo "  分支: $branch"
    echo "  提交: $commit_msg"
    echo ""
    
    # 执行 Git 操作
    print_info "1. 添加文件..."
    git add . || {
        print_error "git add 失败"
        return 1
    }
    
    print_info "2. 提交更改..."
    git commit -m "$commit_msg" || {
        print_error "git commit 失败"
        return 1
    }
    
    print_info "3. 推送到远程..."
    git push || {
        print_error "git push 失败"
        return 1
    }
    
    print_success "推送完成!"
    echo "  第 $push_count 次推送"
    echo "  时间: $timestamp"
    echo "  分支: $branch"
    echo "  提交: $(git log --oneline -1)"
}

# 查看状态
git_status() {
    local repo_path=""
    
    print_info "Git 状态检查"
    
    # 自动选择 Git 仓库
    if ! select_git_repository; then
        return 1
    fi
    
    # 切换到仓库目录
    cd "$repo_path" || {
        print_error "无法进入仓库目录: $repo_path"
        return 1
    }
    
    # 检查是否是 Git 仓库
    if [ ! -d ".git" ]; then
        print_error "不是 Git 仓库: $repo_path"
        return 1
    fi
    
    echo ""
    print_menu "=== 仓库信息 ==="
    echo "位置: $(pwd)"
    echo "分支: $(git branch --show-current)"
    echo "远程: $(git remote get-url origin 2>/dev/null || echo '未设置')"
    
    echo ""
    print_menu "=== 状态概览 ==="
    git status --short
    
    echo ""
    print_menu "=== Beancount 文件状态 ==="
    local bean_files=$(git status --porcelain | grep -E "\.(bean|beancount)$" || echo "无更改")
    if [ "$bean_files" != "无更改" ]; then
        echo "$bean_files"
    else
        echo "无 Beancount 文件更改"
    fi
    
    echo ""
    print_menu "=== 最近提交 ==="
    git log --oneline -5
    
    # 显示分支信息
    echo ""
    print_menu "=== 分支信息 ==="
    git branch -v
}

# 拉取更新
git_pull() {
    local repo_path=""
    
    print_info "拉取远程更新"
    
    # 自动选择 Git 仓库
    if ! select_git_repository; then
        return 1
    fi
    
    # 切换到仓库目录
    cd "$repo_path" || {
        print_error "无法进入仓库目录: $repo_path"
        return 1
    }
    
    # 检查是否是 Git 仓库
    if [ ! -d ".git" ]; then
        print_error "不是 Git 仓库: $repo_path"
        return 1
    fi
    
    local branch=$(git branch --show-current)
    local remote=$(git remote get-url origin 2>/dev/null)
    
    echo ""
    print_info "拉取配置:"
    echo "  仓库: $repo_path"
    echo "  分支: $branch"
    echo "  远程: ${remote:-'未设置'}"
    
    if [ -z "$remote" ]; then
        print_error "未设置远程仓库，无法拉取"
        return 1
    fi
    
    # 检查本地是否有未提交的更改
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "检测到未提交的更改"
        git status --short
        
        read -p "是否先暂存更改? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add . && git commit -m "暂存更改: $(date +"%Y-%m-%d %H:%M:%S")"
        fi
    fi
    
    # 执行拉取
    print_info "执行拉取操作..."
    git pull
    
    if [ $? -eq 0 ]; then
        print_success "拉取完成"
        
        # 显示更新信息
        local latest_commit=$(git log --oneline -1)
        echo ""
        print_info "最新提交: $latest_commit"
    else
        print_error "拉取失败，可能存在冲突"
        return 1
    fi
}

# 自定义提交
git_custom_commit() {
    local repo_path=""
    local commit_msg=""
    local files_to_add=""
    
    print_info "自定义提交"
    
    # 自动选择 Git 仓库
    if ! select_git_repository; then
        return 1
    fi
    
    # 切换到仓库目录
    cd "$repo_path" || {
        print_error "无法进入仓库目录: $repo_path"
        return 1
    }
    
    # 检查是否是 Git 仓库
    if [ ! -d ".git" ]; then
        print_error "不是 Git 仓库: $repo_path"
        return 1
    fi
    
    # 显示当前状态
    echo ""
    print_info "当前状态:"
    git status --short
    
    # 选择要添加的文件
    echo ""
    print_menu "选择要添加的文件:"
    echo "1. 所有文件"
    echo "2. 仅 Beancount 文件 (.bean)"
    echo "3. 仅配置文件"
    echo "4. 手动选择文件"
    echo "5. 取消"
    
    read -p "请选择 [1-5]: " add_choice
    
    case "$add_choice" in
        1)
            files_to_add="."
            print_info "添加所有文件"
            ;;
        2)
            files_to_add="*.bean"
            print_info "添加 Beancount 文件"
            ;;
        3)
            files_to_add="config/ importer/"
            print_info "添加配置和导入文件"
            ;;
        4)
            echo ""
            print_info "当前更改的文件:"
            git status --short
            read -p "请输入要添加的文件路径 (空格分隔): " files_to_add
            ;;
        5)
            print_info "操作取消"
            return 0
            ;;
        *)
            print_error "无效选择"
            return 1
            ;;
    esac
    
    # 添加文件
    if [ -n "$files_to_add" ]; then
        git add $files_to_add || {
            print_error "添加文件失败"
            return 1
        }
        print_success "文件添加完成"
    fi
    
    # 输入提交信息
    echo ""
    read -p "请输入提交信息: " commit_msg
    
    if [ -z "$commit_msg" ]; then
        print_error "提交信息不能为空"
        return 1
    fi
    
    # 执行提交
    git commit -m "$commit_msg"
    
    if [ $? -eq 0 ]; then
        print_success "提交完成"
        
        # 询问是否推送
        read -p "是否推送到远程? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            git push && print_success "推送完成" || print_error "推送失败"
        fi
    else
        print_error "提交失败"
        return 1
    fi
}

# 分支管理
git_branch_management() {
    local repo_path=""
    
    print_info "分支管理"
    
    # 自动选择 Git 仓库
    if ! select_git_repository; then
        return 1
    fi
    
    cd "$repo_path" || return 1
    
    while true; do
        echo ""
        print_menu "=== 分支管理 ==="
        echo "当前分支: $(git branch --show-current)"
        echo ""
        echo "1. 查看所有分支"
        echo "2. 创建新分支"
        echo "3. 切换分支"
        echo "4. 合并分支"
        echo "5. 删除分支"
        echo "6. 返回主菜单"
        
        read -p "请选择 [1-6]: " branch_choice
        
        case "$branch_choice" in
            1)
                echo ""
                git branch -av
                ;;
            2)
                read -p "请输入新分支名: " new_branch
                if [ -n "$new_branch" ]; then
                    git checkout -b "$new_branch"
                fi
                ;;
            3)
                read -p "请输入要切换的分支名: " switch_branch
                if [ -n "$switch_branch" ]; then
                    git checkout "$switch_branch"
                fi
                ;;
            4)
                read -p "请输入要合并的分支名: " merge_branch
                if [ -n "$merge_branch" ]; then
                    git merge "$merge_branch"
                fi
                ;;
            5)
                read -p "请输入要删除的分支名: " delete_branch
                if [ -n "$delete_branch" ]; then
                    git branch -d "$delete_branch"
                fi
                ;;
            6)
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
        
        read -p "按回车继续..."
    done
}


# Git 仓库管理
manage_git_repositories() {
    print_info "Git 仓库管理"
    
    while true; do
        echo ""
        print_menu "Git 仓库管理"
        echo "1. 扫描项目中的 Git 仓库"
        echo "2. 设置默认仓库"
        echo "3. 查看当前仓库信息"
        echo "4. 修复仓库路径"
        echo "5. 返回"
        
        read -p "请选择 [1-5]: " repo_choice
        
        case "$repo_choice" in
            1)
                scan_git_repositories
                ;;
            2)
                set_default_git_repository
                ;;
            3)
                show_current_repo_info
                ;;
            4)
                repair_repo_paths
                ;;
            5)
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
        
        read -p "按回车继续..."
    done
}

# 扫描项目中的 Git 仓库
scan_git_repositories() {
    print_info "扫描项目中的 Git 仓库..."
    
    local found_repos=()
    
    # 在项目目录中查找所有 .git 目录 (使用PROJECT_DIR)
    while IFS= read -r -d '' git_dir; do
        local repo_dir=$(dirname "$git_dir")
        found_repos+=("$repo_dir")
        print_success "发现仓库: $repo_dir"
    done < <(find "$PROJECT_DIR" -name ".git" -type d -print0 2>/dev/null)
    
    if [ ${#found_repos[@]} -eq 0 ]; then
        print_warning "未找到任何 Git 仓库"
    else
        print_success "共发现 ${#found_repos[@]} 个 Git 仓库"
        
        # 保存到配置文件
        save_repo_list "${found_repos[@]}"
    fi
}

# 保存仓库列表
save_repo_list() {
    local repo_file="$SCRIPT_DIR/.git_repositories"
    # 确保使用正确的路径分隔符
    repo_file="${repo_file//\\//}"
    
    cat > "$repo_file" << EOF
# Beancount Git 仓库列表
# 自动生成于: $(date)
EOF
    
    for repo in "$@"; do
        echo "REPO_PATH=$repo" >> "$repo_file"
    done
    
    print_success "仓库列表已保存: $repo_file"
}

# 设置默认仓库
set_default_git_repository() {
    print_info "设置默认 Git 仓库"
    
    local repo_file="$SCRIPT_DIR/.git_repositories"
    
    if [ ! -f "$repo_file" ]; then
        print_warning "未发现仓库列表，请先扫描仓库"
        return 1
    fi
    
    # 读取仓库列表
    local repos=()
    while IFS='=' read -r key value; do
        if [ "$key" = "REPO_PATH" ] && [ -d "$value/.git" ]; then
            repos+=("$value")
        fi
    done < "$repo_file"
    
    if [ ${#repos[@]} -eq 0 ]; then
        print_warning "未找到可用的 Git 仓库"
        return 1
    fi
    
    echo ""
    print_menu "选择默认 Git 仓库:"
    for i in "${!repos[@]}"; do
        echo "  $((i+1)). ${repos[$i]}"
    done
    
    read -p "请选择 [1-${#repos[@]}]: " default_choice
    
    if [ "$default_choice" -ge 1 ] && [ "$default_choice" -le ${#repos[@]} ]; then
        local selected_repo="${repos[$((default_choice-1))]}"
        echo "DEFAULT_GIT_REPO=$selected_repo" >> "$repo_file"
        print_success "已设置默认仓库: $selected_repo"
        export BEANCOUNT_REPO="$selected_repo"
    else
        print_error "无效选择"
    fi
}

# 显示当前仓库信息
show_current_repo_info() {
    if select_git_repository; then
        echo ""
        print_menu "当前 Git 仓库信息:"
        echo "  路径: $(pwd)"
        echo "  分支: $(git branch --show-current)"
        echo "  远程: $(git remote get-url origin 2>/dev/null || echo '未设置')"
        echo "  状态: $(git status --short | wc -l) 个更改"
        
        # 显示最近的提交
        echo ""
        print_menu "最近提交:"
        git log --oneline -3 2>/dev/null || echo "  无法获取提交历史"
    fi
}

# 修复仓库路径
repair_repo_paths() {
    print_info "修复 Git 仓库路径"
    
    # 检查当前配置的仓库是否存在
    if [ -n "$BEANCOUNT_REPO" ] && [ ! -d "$BEANCOUNT_REPO/.git" ]; then
        print_warning "配置的仓库不存在: $BEANCOUNT_REPO"
        read -p "是否删除此配置? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 从配置文件中移除
            local repo_file="$SCRIPT_DIR/.git_repositories"
            if [ -f "$repo_file" ]; then
                grep -v "DEFAULT_GIT_REPO=$BEANCOUNT_REPO" "$repo_file" > "${repo_file}.tmp"
                mv "${repo_file}.tmp" "$repo_file"
            fi
            print_success "已移除无效仓库配置"
        fi
    fi
    
    # 重新扫描仓库
    scan_git_repositories
}


# 仓库初始化
git_init_repo() {
    local repo_path=""
    
    print_info "初始化 Git 仓库"
    
    read -p "请输入要初始化的目录 [默认: 当前目录]: " repo_path
    repo_path=${repo_path:-"."}
    
    if [ ! -d "$repo_path" ]; then
        print_error "目录不存在: $repo_path"
        return 1
    fi
    
    cd "$repo_path" || return 1
    
    if [ -d ".git" ]; then
        print_warning "该目录已经是 Git 仓库"
        return 0
    fi
    
    git init
    print_success "Git 仓库初始化完成"
    
    # 询问是否添加远程仓库
    read -p "是否添加远程仓库? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "请输入远程仓库URL: " remote_url
        if [ -n "$remote_url" ]; then
            git remote add origin "$remote_url"
            print_success "远程仓库添加完成"
        fi
    fi
}

# 冲突解决助手
git_conflict_helper() {
    print_info "Git 冲突解决助手"
    
    echo ""
    print_menu "冲突解决步骤:"
    echo "1. 查看冲突文件:   git status  "
    echo "2. 打开冲突文件，查找 <<<<<<<, =======, >>>>>>> 标记"
    echo "3. 手动解决冲突，删除标记"
    echo "4. 添加已解决的文件:   git add <file>  "
    echo "5. 完成解决:   git commit  "
    echo ""
    
    # 检查当前是否有冲突
    if git status 2>/dev/null | grep -q "both modified"; then
        print_warning "检测到未解决的冲突!"
        echo ""
        git status --short | grep -E "UU|AA"
        echo ""
        read -p "是否尝试自动标记冲突文件? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git diff --name-only --diff-filter=U
        fi
    else
        print_success "未检测到冲突"
    fi
}

# 备份仓库
git_backup_repo() {
    local repo_path=""
    local backup_dir=""
    
    print_info "Git 仓库备份"
    
    if [ -d "$BEANCOUNT_REPO" ] && [ -d "$BEANCOUNT_REPO/.git" ]; then
        repo_path="$BEANCOUNT_REPO"
    else
        read -p "请输入要备份的仓库路径: " repo_path
    fi
    
    if [ ! -d "$repo_path" ] || [ ! -d "$repo_path/.git" ]; then
        print_error "不是有效的 Git 仓库: $repo_path"
        return 1
    fi
    
    local repo_name=$(basename "$repo_path")
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_dir="${repo_path}_backup_${timestamp}"
    
    print_info "备份配置:"
    echo "  源仓库: $repo_path"
    echo "  备份到: $backup_dir"
    
    # 创建备份
    cp -r "$repo_path" "$backup_dir"
    
    if [ $? -eq 0 ]; then
        print_success "备份完成: $backup_dir"
        
        # 显示备份大小
        local backup_size=$(du -sh "$backup_dir" | cut -f1)
        echo "备份大小: $backup_size"
    else
        print_error "备份失败"
        return 1
    fi
}

# Git 统计信息
git_statistics() {
    local repo_path=""
    
    print_info "Git 统计信息"
    
    if [ -d "$BEANCOUNT_REPO" ] && [ -d "$BEANCOUNT_REPO/.git" ]; then
        repo_path="$BEANCOUNT_REPO"
    else
        read -p "请输入仓库路径 [默认: 当前目录]: " repo_path
        repo_path=${repo_path:-"."}
    fi
    
    cd "$repo_path" || return 1
    
    echo ""
    print_menu "=== 基本统计 ==="
    echo "总提交数: $(git rev-list --count HEAD)"
    echo "分支数: $(git branch | wc -l | tr -d ' ')"
    echo "贡献者数: $(git shortlog -s -n | wc -l)"
    
    echo ""
    print_menu "=== 贡献者统计 ==="
    git shortlog -s -n | head -10
    
    echo ""
    print_menu "=== 文件统计 ==="
    echo "Beancount 文件数: $(find . -name "*.bean" | wc -l | tr -d ' ')"
    echo "Python 文件数: $(find . -name "*.py" | wc -l | tr -d ' ')"
    echo "总文件数: $(git ls-files | wc -l | tr -d ' ')"
    
    echo ""
    print_menu "=== 最近活动 ==="
    git log --oneline --since="1 month ago" | wc -l | xargs echo "近一个月提交数:"
    git log --oneline --since="1 week ago" | wc -l | xargs echo "近一周提交数:"
}


# Git 配置管理
manage_git_config() {
    print_info "Git 配置管理"
    
    while true; do
        echo ""
        print_menu "当前 Git 配置:"
        echo "1. 用户名: $(git config --global user.name || echo '未设置')"
        echo "2. 邮箱: $(git config --global user.email || echo '未设置')"
        echo "3. 自动设置远程分支: $(git config --global push.autoSetupRemote || echo '未设置')"
        echo "4. 拉取策略: $(git config --global pull.rebase || echo '未设置')"
        echo "5. 默认分支: $(git config --global init.defaultBranch || echo '未设置')"
        echo "6. 查看所有配置"
        echo "7. 显示 Git 别名"
        echo "8. 重置为推荐配置"
        echo "9. 返回"
        
        read -p "请选择 [1-9]: " config_choice
        
        case "$config_choice" in
            1)
                read -p "请输入 Git 用户名: " git_username
                if [ -n "$git_username" ]; then
                    git config --global user.name "$git_username"
                    print_success "用户名设置成功"
                fi
                ;;
            2)
                read -p "请输入 Git 邮箱: " git_email
                if [ -n "$git_email" ]; then
                    git config --global user.email "$git_email"
                    print_success "邮箱设置成功"
                fi
                ;;
            3)
                current_auto_setup=$(git config --global push.autoSetupRemote || echo "false")
                if [ "$current_auto_setup" = "true" ]; then
                    git config --global push.autoSetupRemote false
                    print_warning "已禁用自动设置远程分支"
                else
                    git config --global push.autoSetupRemote true
                    print_success "已启用自动设置远程分支"
                fi
                ;;
            4)
                current_pull_rebase=$(git config --global pull.rebase || echo "false")
                if [ "$current_pull_rebase" = "true" ]; then
                    git config --global pull.rebase false
                    print_success "已设置拉取策略为 merge"
                else
                    git config --global pull.rebase true
                    print_warning "已设置拉取策略为 rebase"
                fi
                ;;
            5)
                read -p "请输入默认分支名称 [默认: main]: " default_branch
                default_branch=${default_branch:-"main"}
                git config --global init.defaultBranch "$default_branch"
                print_success "默认分支设置为: $default_branch"
                ;;
            6)
                show_git_config
                ;;
            7)
                show_git_aliases
                ;;
            8)
                setup_recommended_git_config
                ;;
            9)
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
        
        echo ""
    done
}

# 显示所有 Git 配置
show_git_config() {
    print_info "Git 全局配置:"
    git config --global --list
    
    echo ""
    print_info "当前仓库配置:"
    if [ -d ".git" ]; then
        git config --list
    else
        echo "不在 Git 仓库中"
    fi
}

# 设置推荐的 Git 配置
setup_recommended_git_config() {
    print_info "设置推荐的 Git 配置..."
    
    # 用户信息
    if [ -z "$(git config --global user.name)" ]; then
        git config --global user.name "Beancount User"
    fi
    
    if [ -z "$(git config --global user.email)" ]; then
        git config --global user.email "beancount@example.com"
    fi
    
    # 核心配置
    git config --global push.autoSetupRemote true
    git config --global pull.rebase false
    git config --global init.defaultBranch main
    git config --global core.autocrlf input
    git config --global core.editor "code --wait"
    git config --global credential.helper store
    
    # 别名配置
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    
    print_success "推荐配置设置完成"
    show_git_config
}

# 智能 Git 仓库检测
find_git_repository() {
    local current_dir="$1"
    local search_dir="${2:-$PROJECT_DIR}"
    
    # 如果当前目录就是 Git 仓库，直接返回
    if [ -d "$current_dir/.git" ]; then
        echo "$current_dir"
        return 0
    fi
    
    # 在项目目录中查找 Git 仓库
    if [ -d "$search_dir/.git" ]; then
        echo "$search_dir"
        return 0
    fi
    
    # 查找 Beancount 仓库
    if [ -d "$BEANCOUNT_REPO/.git" ]; then
        echo "$BEANCOUNT_REPO"
        return 0
    fi
    
    # 在父目录中查找
    local parent_dir="$current_dir"
    while [ "$parent_dir" != "/" ]; do
        if [ -d "$parent_dir/.git" ]; then
            echo "$parent_dir"
            return 0
        fi
        parent_dir=$(dirname "$parent_dir")
    done
    
    return 1
}

# 安全的 Git 仓库切换
safe_cd_to_git_repo() {
    local target_dir="${1:-$PROJECT_DIR}"
    
    # 尝试切换到目标目录
    cd "$target_dir" 2>/dev/null || {
        print_error "无法切换到目录: $target_dir"
        return 1
    }
    
    # 查找 Git 仓库
    local git_repo=$(find_git_repository "$(pwd)")
    
    if [ -n "$git_repo" ] && [ "$git_repo" != "$(pwd)" ]; then
        print_info "切换到 Git 仓库: $git_repo"
        cd "$git_repo" || return 1
    fi
    
    # 最终检查
    if [ ! -d ".git" ]; then
        print_error "未找到 Git 仓库"
        echo "当前目录: $(pwd)"
        echo "请选择正确的 Git 仓库路径"
        return 1
    fi
    
    return 0
}

# 选择 Git 仓库
select_git_repository() {
    local repo_path=""
    
    # 可用的仓库列表
    local available_repos=()
    
    # 检查默认的 Beancount 仓库
    if [ -n "$BEANCOUNT_REPO" ] && [ -d "$BEANCOUNT_REPO/.git" ]; then
        available_repos+=("$BEANCOUNT_REPO")
    fi
    
    # 检查项目目录 (使用PROJECT_DIR)
    if [ -d "$PROJECT_DIR/.git" ]; then
        available_repos+=("$PROJECT_DIR")
    fi
    
    # 检查当前目录
    if [ -d ".git" ]; then
        available_repos+=("$(pwd)")
    fi
    
    # 如果没有找到仓库，让用户输入
    if [ ${#available_repos[@]} -eq 0 ]; then
        print_warning "未找到 Git 仓库"
        read -p "请输入 Git 仓库路径: " repo_path
        if [ -z "$repo_path" ] || [ ! -d "$repo_path/.git" ]; then
            print_error "不是有效的 Git 仓库: $repo_path"
            return 1
        fi
    elif [ ${#available_repos[@]} -eq 1 ]; then
        # 只有一个仓库，直接使用
        repo_path="${available_repos[0]}"
        print_info "使用仓库: $repo_path"
    else
        # 多个仓库，让用户选择
        echo ""
        print_menu "发现多个 Git 仓库:"
        for i in "${!available_repos[@]}"; do
            echo "  $((i+1)). ${available_repos[$i]}"
        done
        echo "  $(( ${#available_repos[@]} + 1 )). 手动输入路径"
        
        read -p "请选择仓库 [1-${#available_repos[@]}]: " repo_choice
        
        if [ "$repo_choice" -eq $((${#available_repos[@]} + 1)) ]; then
            read -p "请输入 Git 仓库路径: " repo_path
        elif [ "$repo_choice" -ge 1 ] && [ "$repo_choice" -le ${#available_repos[@]} ]; then
            repo_path="${available_repos[$((repo_choice-1))]}"
        else
            print_error "无效选择"
            return 1
        fi
    fi
    
    # 切换到仓库目录
    safe_cd_to_git_repo "$repo_path"
}


# 添加文件到上次提交
git_add_to_last_commit() {
    print_info "添加文件到上次提交"

    # 自动选择 Git 仓库
    if ! select_git_repository; then
        return 1
    fi

    # 显示最近一次提交
    echo ""
    print_info "最近一次提交:"
    git log -1 --oneline
    
    # 显示未跟踪和已修改的文件
    echo ""
    print_info "未跟踪的文件:"
    git status --porcelain | grep "^??" | cut -c4-
    
    echo ""
    print_info "已修改未暂存的文件:"
    git status --porcelain | grep "^ M" | cut -c4-
    
    echo ""
    read -p "请输入要添加到上次提交的文件路径 (空格分隔多个文件): " files_to_add
    
    if [ -z "$files_to_add" ]; then
        print_error "未选择任何文件"
        return 1
    fi
    
    # 添加文件到暂存区
    print_info "添加文件到暂存区..."
    git add $files_to_add
    
    if [ $? -eq 0 ]; then
        print_success "文件添加成功"
        
        # 修改上次提交
        print_info "修改上次提交..."
        git commit --amend --no-edit
        
        if [ $? -eq 0 ]; then
            print_success "文件已成功添加到上次提交"
            echo ""
            print_info "更新后的提交:"
            git log -1 --oneline
        else
            print_error "修改提交失败"
            return 1
        fi
    else
        print_error "文件添加失败"
        return 1
    fi
}


# 安全强制推送 (更新版本)
git_safe_force_push() {
    print_info "安全强制推送 (--force-with-lease)"
    
    # 自动选择 Git 仓库
    if ! select_git_repository; then
        return 1
    fi
    
    local current_branch=$(git branch --show-current)
    local remote=$(git remote get-url origin 2>/dev/null)
    
    if [ -z "$remote" ]; then
        print_error "未设置远程仓库"
        return 1
    fi
    
    echo ""
    print_warning "⚠️  安全强制推送警告"
    echo "========================================"
    echo "当前分支: $current_branch"
    echo "远程仓库: $remote"
    echo ""
    echo "这将用本地提交覆盖远程提交"
    echo "但会检查是否有其他人推送了新的提交"
    echo "========================================"
    
    # 显示本地和远程的差异
    echo ""
    print_info "检查本地和远程差异..."
    
    # 获取远程更新
    git fetch origin
    
    # 显示本地和远程的提交差异
    local ahead=$(git rev-list --count origin/$current_branch..$current_branch 2>/dev/null || echo "0")
    local behind=$(git rev-list --count $current_branch..origin/$current_branch 2>/dev/null || echo "0")
    
    echo ""
    print_menu "分支状态:"
    echo "  本地领先远程: $ahead 个提交"
    echo "  本地落后远程: $behind 个提交"
    
    if [ "$behind" -gt 0 ]; then
        print_warning "远程有 $behind 个新提交！"
        echo ""
        print_info "远程的新提交:"
        git log --oneline $current_branch..origin/$current_branch 2>/dev/null || echo "无法获取远程提交"
        
        echo ""
        print_error "强制推送可能会覆盖其他人的工作！"
        echo ""
        read -p "是否继续? (输入 'YES' 确认): " confirmation
        if [ "$confirmation" != "YES" ]; then
            print_info "操作取消"
            return 0
        fi
    fi
    
    # 显示将要推送的提交
    echo ""
    print_info "将要推送的提交:"
    git log --oneline origin/$current_branch..$current_branch 2>/dev/null || 
    git log --oneline -5
    
    # 最终确认
    echo ""
    print_warning "最终确认"
    read -p "确定要执行 git push --force-with-lease? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "操作取消"
        return 0
    fi
    
    # 执行安全强制推送
    print_info "执行 git push --force-with-lease..."
    git push --force-with-lease
    
    if [ $? -eq 0 ]; then
        print_success "安全强制推送成功！"
        
        # 显示推送后的状态
        echo ""
        print_info "推送后状态:"
        git log --oneline -3
    else
        print_error "安全强制推送失败"
        echo ""
        print_info "可能的原因:"
        echo "  - 远程有新的提交未被获取"
        echo "  - 没有推送权限"
        echo "  - 网络连接问题"
        
        # 提供解决方案
        echo ""
        print_menu "建议操作:"
        echo "1. 运行: git fetch --all"
        echo "2. 检查: git log --oneline origin/$current_branch..$current_branch"
        echo "3. 如果需要合并，运行: git pull --rebase"
        echo "4. 然后重试强制推送"
    fi
}

# 强制推送场景助手
git_force_push_helper() {
    print_info "强制推送场景助手"
    
    while true; do
        echo ""
        print_menu "选择强制推送场景:"
        echo "1. 修改了上次提交 (commit --amend)"
        echo "2. 本地 rebase 后推送"
        echo "3. 本地重置后推送"
        echo "4. 清理提交历史后推送"
        echo "5. 普通安全强制推送"
        echo "6. 查看强制推送指南"
        echo "7. 返回"
        
        read -p "请选择 [1-7]: " scenario_choice
        
        case "$scenario_choice" in
            1)
                echo ""
                print_info "场景: 修改了上次提交"
                echo "适用情况:"
                echo "  - 添加了忘记的文件 (git commit --amend)"
                echo "  - 修改了提交信息"
                echo "  - 调整了提交内容"
                echo ""
                print_success "推荐命令: git push --force-with-lease"
                ;;
            2)
                echo ""
                print_info "场景: 本地 rebase 后推送"
                echo "适用情况:"
                echo "  - 整理了提交历史"
                echo "  - 合并了多个提交"
                echo "  - 修改了提交顺序"
                echo ""
                print_success "推荐命令: git push --force-with-lease"
                echo "前置步骤: git rebase -i <commit>"
                ;;
            3)
                echo ""
                print_info "场景: 本地重置后推送"
                echo "适用情况:"
                echo "  - 撤销了错误的提交"
                echo "  - 回退到之前的版本"
                echo "  - 丢弃了本地更改"
                echo ""
                print_success "推荐命令: git push --force-with-lease"
                echo "前置步骤: git reset --hard <commit>"
                ;;
            4)
                echo ""
                print_info "场景: 清理提交历史后推送"
                echo "适用情况:"
                echo "  - 删除了敏感信息"
                echo "  - 清理了大文件"
                echo "  - 重写了项目历史"
                echo ""
                print_warning "注意: 这会重写整个项目历史"
                print_success "推荐命令: git push --force-with-lease"
                ;;
            5)
                git_safe_force_push
                ;;
            6)
                show_force_push_guide
                ;;
            7)
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
        
        if [ "$scenario_choice" -ne 5 ] && [ "$scenario_choice" -ne 7 ]; then
            echo ""
            read -p "是否执行安全强制推送? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git_safe_force_push
            fi
        fi
        
        read -p "按回车继续..."
    done
}

# 显示强制推送指南
show_force_push_guide() {
    print_info "Git 强制推送安全指南"
    
    echo ""
    print_menu "📚 强制推送类型对比:"
    echo ""
    echo "🔵 git push --force-with-lease (推荐)"
    echo "   - 检查远程是否有新提交"
    echo "   - 如果有人推送了，会拒绝强制推送"
    echo "   - 最安全的强制推送方式"
    echo ""
    echo "🟡 git push --force"
    echo "   - 无条件覆盖远程分支"
    echo "   - 可能丢失其他人的工作"
    echo "   - 仅在确定需要时使用"
    echo ""
    echo "🔴 git push -f (简写)"
    echo "   - 同 --force，同样危险"
    echo ""
    
    echo ""
    print_menu "🚨 危险场景:"
    echo "  - 多人协作的分支"
    echo "  - 主分支 (main/master)"
    echo "  - 共享的功能分支"
    echo ""
    
    print_menu "✅ 安全实践:"
    echo "  1. 始终先使用 --force-with-lease"
    echo "  2. 推送前先 fetch 查看远程状态"
    echo "  3. 在个人分支上使用强制推送"
    echo "  4. 通知团队成员强制推送操作"
    echo "  5. 考虑使用备用分支而不是强制推送"
    echo ""
    
    print_menu "🛠️ 恢复方法:"
    echo "  # 如果强制推送出错，可以恢复:"
    echo "  git reflog"
    echo "  git reset --hard <commit-hash>"
    echo "  git push --force-with-lease"
}

# 添加到上次提交并强制推送
git_amend_and_force_push() {
    print_info "添加到上次提交并强制推送"
    
    # 检查当前状态
    if [ -z "$(git status --porcelain)" ]; then
        print_warning "没有需要提交的更改"
        return 0
    fi
    
    echo ""
    print_info "当前的更改:"
    git status --short
    
    # 选择要添加的文件
    echo ""
    read -p "是否添加所有更改到上次提交? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        read -p "请输入要添加的文件路径 (空格分隔): " files_to_add
        if [ -n "$files_to_add" ]; then
            git add $files_to_add
        else
            print_info "操作取消"
            return 0
        fi
    else
        git add .
    fi
    
    # 修改上次提交
    print_info "修改上次提交..."
    git commit --amend --no-edit
    
    if [ $? -eq 0 ]; then
        print_success "提交修改成功"
        
        # 执行安全强制推送
        echo ""
        git_safe_force_push
    else
        print_error "提交修改失败"
        return 1
    fi
}

# 初始化 Git 模块
initialize_git_module() {
    print_info "初始化 Git 模块..."
    setup_git_config
    setup_git_aliases
    print_success "Git 模块初始化完成"
}

# 自动初始化
initialize_git_module
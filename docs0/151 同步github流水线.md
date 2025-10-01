# 同步 GitHub 流水线

可以在 main 分支的 push 事件触发时执行同步到 GitHub 的步骤。以下是配置示例和说明：
配置思路

- 触发条件：在 .cnb.yml 中指定触发分支为 main，触发事件为 push（分支 push 时触发）。
- 同步步骤：通过 script 执行具体同步命令（如使用 Git 或 GitHub CLI 工具）。

示例配置

```yaml

main: # 指定触发分支为 main
  push: # 指定触发事件为 push（分支 push 时触发）
    - name: sync-to-github # 流水线名称
      stages:
        - name: sync-stage # 阶段名称
          jobs:
            - name: sync-job # 任务名称
              script: |
                # 这里编写同步到 GitHub 的具体命令
                # 示例：使用 git 推送（需确保 Runner 有权限）
                git config user.name "Your-GitHub-Username"
                git config user.email "<your-email@example.com>"
                git remote add sync-repo https://${GITHUB_TOKEN}@github.com/your-org/your-repo.git
                git push sync-repo main
              env:
                GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} # 从密钥管理中获取 GitHub Token（需提前配置）
```

关键说明

- 触发事件：push 事件会在 main 分支代码推送时自动触发流水线，适合执行同步操作。
- 同步命令：示例中使用 git 命令推送至目标仓库，需替换 your-org/your-repo.git 为实际目标仓库地址。若使用 GitHub CLI（gh），可替换为 gh repo sync 等命令。
- 权限配置：需通过环境变量（如 GITHUB_TOKEN）注入访问令牌，确保 Runner 有权限操作目标 GitHub 仓库（密钥需在云原生构建平台的安全设置中提前配置）。
- 多任务并行：若需要多个同步步骤（如同步不同仓库），可在 stages 下添加多个 jobs，平台会并行执行。

---

我的执行日志

// 添加远程仓库
git remote add gitee  <https://gitee.com/renlangman2/beancount-gs.git>
// 推送本地分支到远程仓库 需要输入账号和密码
git push gitee dev:feat-beanquery-cnb/dev

```bash
ℹ️ 可用的本地分支:
dev
请选择要推送的本地分支 [默认: dev]: 
ℹ️ 默认远程分支名: feat-beanquery-cnb/dev
是否使用此默认远程分支名? (y/n) [默认: y]: 
ℹ️ 使用默认远程分支名: feat-beanquery-cnb/dev
ℹ️ 开始同步CNB仓库到GitHub和Gitee...
----------------------------------------
ℹ️ 本地分支: dev
ℹ️ 远程分支: feat-beanquery-cnb/dev (不同名推送)
ℹ️ 跳过GitHub远程仓库配置
ℹ️ 添加Gitee远程仓库...
✅ Gitee远程仓库已添加
ℹ️ 当前配置的远程仓库:
gitee   https://gitee.com/renlangman2/beancount-gs.git (fetch)
gitee   https://gitee.com/renlangman2/beancount-gs.git (push)
origin  https://cnb.cool/ysundy/bean/beancount.git (fetch)
origin  https://cnb.cool/ysundy/bean/beancount.git (push)
ℹ️ 推送到Gitee...





root@5078873d40fc:/workspace# git push gitee dev:feat-beanquery-cnb/dev --force  # 强制推送cnb的dev分支到gitee的feat-beanquery-cnb/dev分支
Enumerating objects: 555, done.
Counting objects: 100% (555/555), done.
Delta compression using up to 8 threads
Compressing objects: 100% (434/434), done.
Writing objects: 100% (555/555), 3.53 MiB | 278.21 MiB/s, done.
Total 555 (delta 190), reused 385 (delta 97), pack-reused 0
remote: Resolving deltas: 100% (190/190), done.
remote: Powered by GITEE.COM [1.1.5]
remote: Set trace flag 9d40dab6
To https://gitee.com/renlangman2/beancount-gs.git
 + 2c18b17...c040e11 dev -> feat-beanquery-cnb/dev (forced update)


root@5078873d40fc:/workspace# 
```

/workspace/.scripts/sync_to_github_gitee.sh <https://gitee.com/renlangman2/beancount-gs.git>

```yaml
# dev 分支专用配置 在用
dev:
  # includes:
  #   - /workspace/.cnb/pipeline.yml
  push: # 指定触发事件为 push（分支 push 时触发）
    - name: sync-to-github # 流水线名称
      stages:
        - name: sync-stage # 阶段名称
          jobs:
            - name: sync-job # 任务名称
              imports: # 引入外部配置
                - https://cnb.cool/ysundy/secrets/-/blob/main/envs/gitee_auth.yml # 引入 Gitee 密钥配置
              env:
                GIT_USERNAME: ${{ secrets.GIT_USERNAME }} # 从密钥管理中获取 GitHub 用户名（需提前配置）
                GIT_ACCESS_TOKEN: ${{ secrets.GIT_ACCESS_TOKEN }} # 从密钥管理中获取 GitHub Token（需提前配置）
              script: |
                  # 配置Git用户信息
                  git config user.name "CNB-GitHub-Sync"
                  git config user.email "sync-bot@cnb.cool"
                  
                  # 检查是否已经设置了gitee远程库
                  if git remote | grep -q "gitee"; then
                      echo "Gitee remote already exists, updating URL..."
                      git remote set-url gitee https://$GIT_USERNAME:$GIT_ACCESS_TOKEN@gitee.com/renlangman2/beancount-gs.git
                  else
                      echo "Adding Gitee remote..."
                      git remote add gitee https://$GIT_USERNAME:$GIT_ACCESS_TOKEN@gitee.com/renlangman2/beancount-gs.git
                  fi
                  
                  # 显示所有远程仓库（用于调试）
                  echo "Remote repositories:"
                  git remote -v
                  
                  # 推送dev分支到Gitee的feat-beanquery-cnb/dev分支（简化版）
                  echo "Pushing to Gitee..."
                  git push gitee dev:feat-beanquery-cnb/dev
                  
                  echo "Sync completed successfully!"
```

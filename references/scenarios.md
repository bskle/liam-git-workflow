# Common Scenarios

## Create a production bug branch

Input:

```text
$liam-git-workflow
创建一个线上 bug 修复分支，修复 login 出现的网络问题
```

Expected classification:

- branch type: `hotfix/*`
- base: `main`
- suggested name: `hotfix/login-network-error`

## Create a normal bug branch

Input:

```text
$liam-git-workflow-create-branch
修复术语导入时的表头校验问题
```

Expected classification:

- branch type: `fix/*`
- base: `dev`

## Commit current changes

Input:

```text
$liam-git-workflow-commit
提交本次修改
```

Expected output:

- recommended commit type
- recommended scope
- 1 to 3 Chinese commit message candidates

## Finish a feature branch

Input:

```text
$liam-git-workflow-finish
我已经做完 feature/translator-batch-import，下一步怎么处理
```

Expected output:

- confirm merge target is `dev`
- remind about tests and PR summary

## Audit local policy

Input:

```text
$liam-git-workflow-sync-policy
检查我的 git 全局配置
```

Expected output:

- current config values
- drift from policy
- suggested commands to align

## Push 失败：受保护分支拒绝推送

Input:

```text
$liam-git-workflow
git push 失败了，提示 ! [remote rejected] feature/xxx -> feature/xxx (protected branch hook declined)
```

Expected classification:

1. problem category: 仓库策略拒绝（第 5 层诊断）
2. trigger signal: stderr 包含 "protected branch" 或 "remote rejected"
3. route to: `liam-git-workflow-remote-diagnose`
4. reference: `references/remote-diagnostics.md` -- 第 5 层「仓库策略与服务端规则」→ 受保护分支信号
5. suggested action: 创建 Pull Request 通过代码审查后合并，这是预期行为而非故障

## Pull 失败：HTTPS 认证凭据过期

Input:

```text
$liam-git-workflow
git pull 报错了，提示 fatal: Authentication failed for 'https://github.com/xxx/xxx.git/'
```

Expected classification:

1. problem category: 认证失败（第 3 层诊断）
2. trigger signal: stderr 包含 "fatal: Authentication failed"
3. route to: `liam-git-workflow-remote-diagnose`
4. reference: `references/remote-diagnostics.md` -- 第 3 层「认证与授权」→ 凭据过期信号
5. suggested action: 使用 `git credential reject` 清除旧凭据后重新执行 pull 触发认证弹窗

## Fetch 失败：DNS 无法解析 Git 服务域名

Input:

```text
$liam-git-workflow
git fetch 报错了，fatal: unable to access 'https://github.com/xxx/xxx.git/': Could not resolve host: github.com
```

Expected classification:

1. problem category: DNS 解析失败（第 4 层诊断）
2. trigger signal: stderr 包含 "Could not resolve host"
3. route to: `liam-git-workflow-remote-diagnose`
4. reference: `references/remote-diagnostics.md` -- 第 4 层「网络路径」→ DNS 解析失败信号
5. suggested action: 运行诊断脚本自动检查 DNS 配置 -- 脚本会通过 `Resolve-DnsName` 和 `.NET GetHostEntry()` 双通道验证 DNS 可用性

## ls-remote 失败：TCP 连接超时无法到达远程

Input:

```text
$liam-git-workflow
git ls-remote origin 一直超时，报 fatal: unable to access 'https://github.com/xxx/xxx.git/': Failed to connect to github.com port 443: Timed out
```

Expected classification:

1. problem category: 连接超时/拒绝（第 4 层诊断）
2. trigger signal: stderr 包含 "Failed to connect" 和 "Timed out"
3. route to: `liam-git-workflow-remote-diagnose`
4. reference: `references/remote-diagnostics.md` -- 第 4 层「网络路径」→ 连接超时信号
5. suggested action: 运行诊断脚本自动检查网络路径 -- 脚本会检查代理配置（Git 代理 + 环境变量 + 注册表系统代理）、TCP 443 可达性、HTTPS 最小探测，定位阻断点

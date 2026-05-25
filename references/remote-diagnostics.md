# Git 远程诊断参考知识库

本文档是 Git 远程操作故障诊断的核心参考知识库。供 `liam-git-workflow-remote-diagnose` 技能和主 Agent 在执行诊断时加载和查询。

---

## 故障分类

下表列出所有 Git 远程操作故障类别及其典型信号特征。

| 类别 | 信号特征 | 受影响操作 | 诊断层 |
|------|---------|-----------|--------|
| 本地状态阻塞 | `detached HEAD`、`merge/rebase in progress`、未解决的冲突 (`UU`)、分支无 upstream 配置 | `push`、`pull` | 第 1 层 |
| 远程目标错误 | remote URL 格式错误、upstream 分支不存在、仓库名/owner 拼写错误或路径缺失 | 全部 | 第 2 层 |
| 认证失败 | HTTP `401 Unauthorized`、`403 Forbidden`、SSH `Permission denied`、凭据助手为空或凭据已过期 | 全部 | 第 3 层 |
| 授权不足 | 仓库访问被拒、组织策略限制（IP 白名单、2FA 要求）、个人访问令牌权限不足 | `push`、`fetch` | 第 3 层 |
| DNS 解析失败 | `Could not resolve host`、`Name or service not known`、无法解析 Git 服务域名 | 全部 | 第 4 层 |
| 连接超时/拒绝 | `Connection timed out`、`Connection refused`、无法建立 TCP 连接 | 全部 | 第 4 层 |
| TLS/SSL 错误 | `SSL certificate problem`、`unable to get local issuer certificate`、`schannel: next InitializeSecurityContext failed` | 全部 | 第 4 层 |
| 代理错误 | `Proxy CONNECT aborted`、`tunneling socket could not be established`、`HTTP 407 Proxy Authentication Required` | 全部 | 第 4 层 |
| 仓库策略拒绝 | `protected branch` 拒绝推送、`direct push forbidden`、仓库已归档或设为只读 | `push` | 第 5 层 |
| 仓库不存在 | `repository not found`（HTTP 404）、仓库已重命名或删除、owner/org 名称变更 | 全部 | 第 5 层 |

---

## 五层诊断清单

以下按诊断顺序列出每层的具体检查命令、预期输出及异常解读。

### 第 1 层：本地仓库状态

| 检查项 | 命令 | 预期输出 | 非预期输出及含义 |
|--------|------|---------|----------------|
| 当前分支 | `git branch --show-current` | 正常分支名 | 空输出表示 detached HEAD |
| 进行中的 merge | `git status`，检查 `.git/MERGE_HEAD` 是否存在 | 无 MERGE_HEAD | 存在表示 merge 进行中，阻塞远程操作 |
| 进行中的 rebase | `git status`，检查 `.git/rebase-merge` 或 `.git/rebase-apply` | 目录不存在 | 存在表示 rebase 进行中 |
| 未解决冲突 | `git status --porcelain` | 无 `UU` 标记 | `UU` 表示未解决的合并冲突 |
| upstream 配置 | `git branch -vv` | 当前分支后显示 `[origin/branch]` | 无 `[...]` 表示未设置 upstream |
| 工作区状态 | `git status --porcelain` | 干净或只有未跟踪文件 | 未暂存/已暂存的修改可能影响某些操作 |

### 第 2 层：远程目标验证

| 检查项 | 命令 | 预期输出 | 非预期输出及含义 |
|--------|------|---------|----------------|
| 已配置的 remote | `git remote -v` | 至少有一个 fetch 和 push URL | 空输出表示未配置任何 remote |
| Remote URL 格式 | 检查 URL 是否匹配 `https://<host>/<owner>/<repo>.git` 或 `git@<host>:<owner>/<repo>.git` | 格式正确 | 缺少 `.git` 后缀、多余斜杠、缺失 owner 等为格式错误 |
| 分支 upstream 映射 | `git branch -vv` | 当前分支指向有效 remote 分支 | `gone` 状态表示远程分支已删除 |
| Remote 连通性（轻量） | `git ls-remote --heads <remote>` | 返回分支引用列表 | `fatal: repository not found` 表示仓库路径错误 |

### 第 3 层：认证与授权

| 检查项 | 命令 | 预期输出 | 非预期输出及含义 |
|--------|------|---------|----------------|
| 传输类型 | `git config --get remote.origin.url` | 明确的 `https://` 或 `git@`（SSH）前缀 | 无 — 仅用于确定后续检查方向 |
| 凭据助手（HTTPS） | `git config --get credential.helper` | 已配置的助手（如 `manager-core`、`osxkeychain`） | 空输出表示无凭据助手，可能每次都需要输入密码 |
| SSH 密钥状态 | `ssh -T git@github.com` | 成功认证消息（"You've successfully authenticated"） | `Permission denied` 表示密钥未注册或无权限 |
| 常见认证错误 | 检查 stderr | — | `fatal: Authentication failed` = 凭据错误/过期；`HTTP 403` = 有凭据但无权限；`The requested URL returned error: 403` = token 权限不足 |

### 第 4 层：网络路径

| 检查项 | 命令 | 预期输出 | 非预期输出及含义 |
|--------|------|---------|----------------|
| Git HTTP 代理 | `git config --get http.proxy` | 返回代理地址，或空（无代理） | 代理地址不匹配当前网络环境时会导致连接失败 |
| Git HTTPS 代理 | `git config --get https.proxy` | 返回代理地址，或空 | 同上 |
| 环境变量代理 | `env \| grep -i proxy`（Linux/macOS）或 `[System.Environment]::GetEnvironmentVariable('HTTP_PROXY')`（Windows） | 存在则显示，空则无 | 环境代理与 Git 代理不一致时可能冲突 |
| DNS 解析 | `nslookup <host>`（如 `nslookup github.com`） | 返回 IP 地址 | `server can't find` / `NXDOMAIN` = DNS 解析失败 |
| TCP 443 可达性（Windows） | `Test-NetConnection <host> -Port 443` | `TcpTestSucceeded: True` | `False` 或超时表示端口不可达（防火墙、代理阻止） |
| HTTPS 最小探测 | `curl -I https://<host>` | HTTP 响应头 | `Could not resolve host` = DNS 问题；`Connection timed out` = 网络不通；SSL 错误 = 证书/TLS 问题 |
| 窄带远程访问测试 | `git ls-remote <remote>` | 返回远程引用列表 | `fatal: unable to access` + 网络错误信息 = 网络/认证问题 |

### 第 5 层：仓库策略与服务端规则

| 检查项 | 检查方式 | 预期结果 | 非预期结果及含义 |
|--------|---------|---------|----------------|
| 受保护分支 | 检查 push 失败时的 stderr 是否包含 `protected branch` | 无此消息 | 包含则表示分支受保护，需通过 PR 合并 |
| 必需状态检查 | 检查 stderr 中是否提及 `required status check` | 无此消息 | CI 检查未通过导致推送被拒绝 |
| 强制推送被拒 | 检查 stderr 中是否有 `non-fast-forward` 或 `Updates were rejected` | 无 | 远程有本地不存在的提交，需先 pull |
| 仓库归档/只读 | 浏览器查看仓库 Settings → Danger Zone | 非归档状态 | 显示 "This repository has been archived" 表示仓库只读 |
| 组织策略 | 浏览器查看组织设置 → 第三方访问/安全策略 | 无限制 | IP 白名单、2FA 要求等可能阻止 CLI 访问 |

---

## 信号到原因映射

下表将常见错误信号映射到可能的原因，按置信度排序。

| 信号 | 可能原因 | 置信度 | 诊断层 | 验证方法 |
|------|---------|--------|--------|---------|
| `fatal: unable to access 'https://...': Could not resolve host` | DNS 解析失败或主机名拼写错误 | high | 第 4 层 | `nslookup` 目标主机名 |
| `fatal: Authentication failed for 'https://...'` | 凭据过期、密码/Token 错误 | high | 第 3 层 | 检查 `credential.helper` 配置，重新认证 |
| `error: failed to push some refs` + `protected branch` | 目标分支受保护，禁止直接推送 | high | 第 5 层 | 浏览器检查仓库分支保护设置 |
| `ssh: connect to host github.com port 22: Connection timed out` | SSH 端口被企业防火墙或网络策略阻止 | high | 第 4 层 | 测试 TCP 443（HTTPS）可达性，考虑切换传输协议 |
| `fatal: unable to access '...': Recv failure: Connection was reset` | 代理中断、TLS 版本不匹配或服务端重置连接 | medium | 第 4 层 | 检查代理配置，测试直连（绕过代理） |
| `fatal: unable to access '...': schannel: next InitializeSecurityContext failed` | Windows TLS/Schannel 证书链验证失败（常见于企业环境） | medium | 第 4 层 | 检查系统证书存储，检查是否有企业自签名证书代理 |
| `remote: Repository not found.` / `fatal: repository '...' not found` | 仓库名错误、仓库已删除、或访问权限不足导致仓库不可见 | high | 第 5 层 | 浏览器检查仓库是否存在，验证账号权限 |
| `fatal: unable to access '...': The requested URL returned error: 403` | Token 或凭据的权限范围不足（如缺少 `repo` 权限） | high | 第 3 层 | 检查 Token 权限范围，确认组织 SSO 认证状态 |
| `fatal: protocol '...' is not supported` | Remote URL 格式错误（如误写为 `htps://` 或多余空格） | high | 第 2 层 | 检查 `git remote -v` 输出，修正 URL |
| `fatal: not a git repository` | 当前目录不在 Git 仓库中，或 `.git` 目录已损坏 | high | 第 1 层 | `git rev-parse --git-dir` 确认 |
| `fatal: You are not currently on a branch` | detached HEAD 状态，无法推送 | high | 第 1 层 | `git branch --show-current` 确认为空 |
| `error: failed to push some refs` + `hint: Updates were rejected because the remote contains work` | 远程分支有本地不存在的提交，非 fast-forward | high | 第 1 层 | `git fetch` 后 `git pull --rebase` |
| `fatal: unable to access '...': Failed to connect to ... port 443: Timed out` | HTTPS 端口被防火墙阻止或网络路由不通 | high | 第 4 层 | `Test-NetConnection` / `telnet` 测试端口可达性 |
| `fatal: unable to access '...': Received HTTP code 407 from proxy` | 代理需要认证，但未提供凭据 | high | 第 4 层 | 检查 `http.proxy` 配置格式是否包含认证信息 |
| `fatal: SSL certificate problem: self signed certificate in certificate chain` | 企业代理使用自签名证书进行 SSL 拦截 | high | 第 4 层 | 检查系统证书存储或 `http.sslVerify` 配置 |

---

## 标准修复动作

按诊断层分类列出可直接执行的一线修复命令。

### 第 1 层修复：本地仓库状态

| 问题 | 修复命令 | 说明 |
|------|---------|------|
| merge 进行中 | `git merge --abort` | 中止当前 merge，恢复到 merge 前状态 |
| rebase 进行中 | `git rebase --abort` | 中止当前 rebase |
| 无 upstream | `git branch --set-upstream-to=origin/<branch>` | 设置分支跟踪的远程分支 |
| detached HEAD | `git checkout <branch>` | 切换到已有分支 |
| 未提交变更 | `git add <files>` 然后 `git commit` | 提交变更后再操作远程 |
| 未解决冲突 | 手动解决冲突后 `git add` + `git commit` 或 `git merge --continue` | 完成合并后解除阻塞 |

### 第 2 层修复：远程目标

| 问题 | 修复命令 | 说明 |
|------|---------|------|
| Remote URL 错误 | `git remote set-url origin <correct-url>` | 修正远程仓库地址 |
| 缺少 remote | `git remote add <name> <url>` | 添加新的远程仓库 |
| upstream 映射错误 | `git branch -u <remote>/<branch>` | 重新设置分支跟踪 |
| 远程分支已删除 | `git fetch --prune` 后重建分支 | 清理本地过期的远程引用 |

### 第 3 层修复：认证与授权

| 问题 | 修复命令 | 说明 |
|------|---------|------|
| HTTPS 凭据过期 | 使用 `git credential reject` 清除旧凭据，再执行 `git push`/`git pull` 触发重新认证 | 触发凭据助手弹出认证窗口 |
| SSH 密钥问题 | `ssh -T git@github.com` 验证连通性，若不通过则检查 SSH 密钥是否添加到 GitHub/GitLab | 可能需要重新生成密钥或重新添加公钥 |
| 切换 HTTPS → SSH | `git remote set-url origin git@<host>:<owner>/<repo>.git` | 切换到 SSH 避免 HTTPS 凭据问题 |
| 切换 SSH → HTTPS | `git remote set-url origin https://<host>/<owner>/<repo>.git` | 切换到 HTTPS 避免 SSH 端口/密钥问题 |
| 清除凭据缓存 | `git credential-cache exit` 或 `git config --global --unset credential.helper` | 清除可能缓存了错误凭据的助手 |

### 第 4 层修复：网络路径

| 问题 | 修复命令 | 说明 |
|------|---------|------|
| 配置代理 | `git config --global http.proxy http://<proxy-host>:<port>` | 设置 Git 使用的 HTTP 代理 |
| 清除代理 | `git config --global --unset http.proxy` | 移除 Git 代理配置（直连） |
| 绕过 SSL 验证（临时） | `git config --global http.sslVerify false` | 仅在确认无安全风险时使用，解决问题后应立即恢复 |
| SSH 端口被阻 | 切换 remote URL 为 HTTPS 协议 | 端口 443 比端口 22 更不容易被企业网络阻止 |
| DNS 问题 | 使用备用 DNS 或检查 `/etc/hosts`（Linux/macOS）/ `C:\Windows\System32\drivers\etc\hosts`（Windows） | 确认 DNS 服务器配置正确 |

### 第 5 层修复：仓库策略

第 5 层的问题大多需要通过浏览器或与服务端管理员交互解决，CLI 可执行的修复手段有限。

| 问题 | 修复方式 | 说明 |
|------|---------|------|
| 受保护分支 | 创建 PR 通过代码审查后合并 | 这是预期行为，不是故障 |
| 仓库不存在 | 浏览器确认仓库 URL，确认未被删除或重命名 | 可能需要请求访问权限 |
| 组织策略 | 浏览器查看组织安全设置（IP 白名单、2FA 要求） | 需管理员或组织成员处理 |
| 仓库归档 | 联系仓库管理员解除归档，或 fork 仓库后继续工作 | CLI 无法解除归档 |

---

## 升级与人工交互边界

以下信息类别不可从 CLI 环境观测。当诊断需要这些信息时，必须转为人工交互。

### 不可观测场景列表

| 场景 | 不可 CLI 观察的原因 | 用户提示模板 |
|------|-------------------|------------|
| **浏览器登录会话状态** | 浏览器 Cookie/Session 状态无 CLI 接口 | "无法从命令行确认您的浏览器登录状态。请在浏览器中访问 `https://github.com`（或对应 Git 服务平台的主页），确认是否已登录。回报：已登录或未登录。" |
| **组织授权页面** | GitHub 组织 SSO/权限审批页面需浏览器交互 | "无法从命令行确认您的组织授权状态。请访问 `https://github.com/settings/connections/applications` 或对应组织设置页面，检查您的 OAuth App 授权状态。回报：已授权或未授权，以及未授权的具体应用名称。" |
| **VPN 客户端状态** | VPN 客户端无标准 CLI 接口 | "无法从命令行确认 VPN 连接状态。请检查您的 VPN 客户端界面，确认：1) VPN 是否已连接，2) VPN 路由是否覆盖了 Git 服务域名（如 github.com）。回报：VPN 已连接/未连接，以及 Git 服务流量是否经过 VPN。" |
| **代理客户端 GUI 状态** | 代理客户端（如 V2Ray、Clash）无标准 CLI 接口 | "无法从命令行确认代理客户端运行状态。请检查您的代理客户端界面，确认：1) 代理是否已启动，2) 端口配置是否正确，3) 系统代理是否已开启。回报：代理状态（运行/停止），HTTP/HTTPS 代理端口号。" |
| **凭据轮换/替换批准** | 凭据更新需要用户主动确认 | "诊断发现您的凭据可能已过期。若要重新认证，系统将清除旧凭据并触发重新登录流程。是否同意继续？此操作仅影响本地 Git 凭据缓存，不会更改远程密码或 Token。" |
| **系统证书/公司设备策略** | 操作系统证书存储、组策略超出仓库 CLI 范围 | "无法从命令行确认系统证书状态。此问题可能由企业自签名证书或组策略引起。请在 Windows 上打开 `certmgr.msc`，检查证书存储中的受信任根证书列表。回报：是否有企业 CA 证书存在，以及证书是否未过期。" |

### 用户提示格式规范

每次需要人工交互时，提示必须按以下三段式构造：

1. **为什么无法自动化** — 解释所需信息无法从 CLI 观测的原因（参考上表"不可 CLI 观察的原因"列）
2. **用户应该做什么** — 精确的操作步骤，包括具体 URL、菜单路径或命令
3. **用户应该回报什么** — 精确需要回报的信息，避免开放式描述

---

## 输出契约字段定义

诊断完成后，必须返回包含以下字段的结构化输出。

| 字段 | 类型 | 说明 |
|------|------|------|
| `problem_category` | `string` | 主要问题的故障类别，必须与「故障分类」章节列出的类别之一对齐。示例值：`"认证失败"`、`"DNS 解析失败"`、`"连接超时/拒绝"` |
| `evidence` | `string[]` | 在诊断过程中收集到的信号和 CLI 输出摘录列表。每项应是一个可直接引用的具体观察。示例：`["git push stderr: fatal: unable to access ...", "nslookup github.com 返回 NXDOMAIN"]` |
| `likely_cause` | `string` | 基于信号到原因映射表匹配度最高的可能原因。应是一个完整的描述性语句。示例：`"企业防火墙阻止了 SSH 端口 22，但 HTTPS 端口 443 可达"` |
| `confidence` | `enum: high \| medium \| low` | 基于证据充分性和一致性的置信度评估。`high`：证据充分且信号一致指向单一原因；`medium`：证据指向多个可能原因但有一个主要原因；`low`：证据不足或信号矛盾，无法明确判定 |
| `actions_taken` | `string[]` | 按执行顺序排列的已执行诊断步骤列表。每项应包含具体的命令或检查动作。示例：`["git branch --show-current → feature/test", "git remote -v → origin ...", "nslookup github.com → NXDOMAIN"]` |
| `recommended_next_action` | `string` | 具体、可执行的下一步修复操作。主 Agent 应能直接执行该命令或操作。示例：`"git remote set-url origin git@github.com:user/repo.git 将 HTTPS 切换为 SSH"` |
| `human_interaction_required` | `boolean` | 建议的下一步是否需要人工交互。`true` 表示需要用户参与；`false` 表示主 Agent 可自行完成。 |
| `human_action_detail` | `string \| null` | 当 `human_interaction_required` 为 `true` 时，包含精确的用户操作指引（遵循三段式提示格式）。当 `human_interaction_required` 为 `false` 时，此字段为 `null`。 |

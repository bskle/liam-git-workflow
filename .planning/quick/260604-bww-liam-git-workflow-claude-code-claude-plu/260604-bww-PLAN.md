---
phase: quick
plan: 260604-bww
type: execute
wave: 1
depends_on: []
files_modified:
  - .claude-plugin/plugin.json
  - LICENSE
  - README.md
  - CHANGELOG.md
autonomous: false
requirements: []
user_setup: []

must_haves:
  truths:
    - "plugin.json 包含 superpowers 对标的所有字段（homepage, repository, license, author.email）"
    - "仓库根目录存在 MIT LICENSE 文件"
    - "GitHub Releases 页面有 v0.3.0 Release，包含完整的 Release Notes"
    - "README.md 包含插件市场安装命令，用户可复制粘贴执行"
  artifacts:
    - path: ".claude-plugin/plugin.json"
      provides: "Claude Code 插件注册 manifest（与 superpowers 字段对齐）"
      contains: ["homepage", "repository", "license"]
    - path: "LICENSE"
      provides: "MIT 开源许可证"
    - path: "README.md"
      provides: "项目使用说明（含插件市场安装方式）"
  key_links:
    - from: "plugin.json"
      to: "GitHub Release v0.3.0"
      via: "version 字段对应 git tag"
    - from: "README.md"
      to: "marketplace.json PR"
      via: "安装命令 claude plugins install @bskle/liam-git-workflow"
---

<objective>
市场分发准备：将 liam-git-workflow 的 plugin.json、README、LICENSE 对齐到 superpowers 的 marketplace 分发标准，并创建 GitHub Release v0.3.0，使用户可通过 Claude Code 插件市场安装。

Purpose: 对标 superpowers 的分发方式，补齐 marketplace 上架所需的所有项目文件，使仓库达到可提交 PR 到 superpowers-marketplace 索引的状态。
Output: 对齐后的 plugin.json、新增 LICENSE 文件、更新 README.md、GitHub Release v0.3.0
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>

## 参考基准：superpowers 项目的 marketplace 分发模式

通过研究 `obra/superpowers` 和 `obra/superpowers-marketplace` 两个仓库，确认 superpowers 的分发方式：

### superpowers 插件本身 (obra/superpowers)
- `.claude-plugin/plugin.json` 包含字段：`name`, `description`, `version`, `author` (含 `name` + `email`), `homepage`, `repository`, `license`, `keywords`
- 项目根目录有 `LICENSE` 文件（MIT）
- 使用语义化版本 + GitHub Release（最新 v5.1.0）
- `RELEASE-NOTES.md` 记录每个版本的 Breaking Changes / New Features / Bug Fixes

### superpowers-marketplace 索引仓库 (obra/superpowers-marketplace)
- 仓库仅包含 `.claude-plugin/marketplace.json` 和 README.md
- marketplace.json 中每个条目格式：
  ```json
  {
    "name": "plugin-name",
    "source": { "source": "url", "url": "https://github.com/owner/repo.git" },
    "description": "...",
    "version": "x.y.z",
    "strict": true
  }
  ```
- 提交到 marketplace 需要通过 PR 到该仓库（无公开 CONTRIBUTING 指南，推测为维护者审核制）
- 用户安装方式：`/plugin marketplace add obra/superpowers-marketplace` → `/plugin install liam-git-workflow@superpowers-marketplace`

### 当前 liam-git-workflow 的差距

| 项目 | superpowers | liam-git-workflow (当前) | 需要做 |
|------|-------------|--------------------------|--------|
| plugin.json 字段 | 8 字段 (含 homepage, repository, license, author.email) | 5 字段 (缺 3 个) | 补齐 3 字段 + author.email |
| LICENSE 文件 | MIT | 不存在 | 新建 LICENSE |
| GitHub Release | 每版本都有 Release + Release Notes | 只有 v1.0 标签，无 v0.3.0 Release | 创建 v0.3.0 Release |
| README 安装说明 | 含各平台安装命令 | 只有本地 /plugin install 路径方式 | 增加 marketplace 安装命令 |
| marketplace.json 条目 | 已在索引中 | 不在索引中 | 后续提交 PR（本次暂不执行，需联系维护者） |

### 关键约束
- **仓库地址**：`git@github.com:bskle/liam-git-workflow.git`（HTTPS: `https://github.com/bskle/liam-git-workflow`）
- **当前版本**：0.3.0（VERSION 文件 + plugin.json 一致）
- **已有标签**：仅 `v1.0`，没有 `v0.3.0` — 需要创建
- **语义版本策略**：项目使用 `MAJOR.MINOR.PATCH`（对标 superpowers）

</context>

<tasks>

<task type="auto">
  <name>Task 1: 对齐 plugin.json 到 superpowers 标准并添加 LICENSE</name>
  <files>.claude-plugin/plugin.json, LICENSE</files>
  <action>
  **1. 更新 plugin.json** — 对标 superpowers 的字段结构，确保插件注册 manifest 完整：

  当前 plugin.json：
  ```json
  {
    "name": "liam-git-workflow",
    "version": "0.3.0",
    "description": "面向 Codex 和 Claude Code 的个人 Git 工作流插件包 — 分支管理、提交规范、同步策略、远程诊断",
    "author": { "name": "Liam" },
    "keywords": ["git", "workflow", "conventional-commits", "branch-management", "chinese"],
    "skills": ["skills"]
  }
  ```

  需要补齐的字段（参考 superpowers）：
  - `author.email` — 添加 email 字段（superpowers 同时有 name 和 email）
  - `homepage` — `"https://github.com/bskle/liam-git-workflow"`（superpowers 有此字段）
  - `repository` — `"https://github.com/bskle/liam-git-workflow"`（superpowers 有此字段）
  - `license` — `"MIT"`（superpowers 有此字段）

  **注意**：保留现有的 `skills: ["skills"]` 字段（Claude Code 需要此字段来发现技能目录，superpowers 使用不同的技能发现机制所以不需要此字段）。

  **2. 创建 LICENSE 文件** — 使用标准 MIT License，版权持有人填写 "Liam"。

  MIT License 模板（标准文本，不可修改条款）：
  ```
  MIT License

  Copyright (c) 2026 Liam

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  ```
  </action>
  <verify>
    <automated>node -e "const p = require('./.claude-plugin/plugin.json'); const required = ['name','version','description','author','keywords','skills','homepage','repository','license']; const missing = required.filter(k => !(k in p)); if(missing.length) { console.log('MISSING:', missing); process.exit(1); } console.log('plugin.json OK: all', required.length, 'fields present');"</automated>
    <automated>test -f LICENSE && grep -q "MIT License" LICENSE && echo "LICENSE OK"</automated>
  </verify>
  <done>plugin.json 包含 8 个关键字段（name, version, description, author.name, author.email, homepage, repository, license, keywords, skills），LICENSE 文件存在且为标准 MIT 文本</done>
</task>

<task type="auto">
  <name>Task 2: 创建 GitHub Release v0.3.0</name>
  <files>CHANGELOG.md</files>
  <action>
  创建 git tag `v0.3.0` 并在 GitHub 上创建 Release，对标 superpowers 的发布方式。

  **步骤：**

  1. 创建带注释的 git tag（annotated tag，对标 superpowers 使用 annotated tags）：
     ```bash
     git tag -a v0.3.0 -m "v0.3.0: 插件化安装 — Claude Code /plugin install 标准路径 + 双平台 symlink 安装模型"
     ```
     注意：-m 使用英文。tag message 简短描述本次发布主题。

  2. 推送 tag 到远程：
     ```bash
     git push origin v0.3.0
     ```

  3. 使用 `gh` CLI 创建 GitHub Release（如果 gh 不可用，则提示用户在 GitHub Web UI 手动创建）：
     ```bash
     gh release create v0.3.0 \
       --title "v0.3.0 — 插件化安装 + 双平台 symlink 安装模型" \
       --notes-file - <<'RELEASENOTES'
     ## 0.3.0 — 插件化安装

     仓库支持 Claude Code `/plugin install` 标准安装路径，安装模型从文件复制改为 symlink + 插件注册。

     ### 新增
     - `.claude-plugin/plugin.json` — Claude Code 插件注册 manifest
     - `hooks/hooks.json` — SessionStart 会话钩子，启动时注入 Git 工作流可用技能提示
     - 双平台安装脚本 — `install.ps1` 支持 Codex (symlink) 和 Claude Code (plugin-dir 注册)
     - `-CleanLegacy` 安装标志 — 清理旧版本文件复制产物

     ### 变更
     - 安装模型从文件复制改为目录符号链接（`mklink /J` + plugin-dir 注册），技能内容 `git pull` 后自动更新
     - Codex `marketplace.json` source.path 修正为 `"../.."`
     - 废弃 `claude/commands/` — 删除 10 个旧 slash commands，统一通过 skills 机制加载
     - 简化 `scripts/common.ps1` — 移除文件复制和路径重写函数

     ### 修复
     - 修正仓库内相对路径引用，确保技能在 symlink 和插件注册两种模式下均正确解析

     ### 安装
     ```
     # Claude Code（推荐）
     /plugin install <仓库路径>

     # Codex
     powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -SkipClaude
     ```

     **完整变更日志**: [CHANGELOG.md](https://github.com/bskle/liam-git-workflow/blob/main/CHANGELOG.md)
     RELEASENOTES
     ```

  4. 如果 `gh` CLI 未认证，回退方案：在终端输出 Release Notes 内容，提示用户到 `https://github.com/bskle/liam-git-workflow/releases/new?tag=v0.3.0` 手动创建 Release，将 Release Notes 粘贴进去。

  **对标说明**：superpowers 使用 annotated tags + GitHub Releases + RELEASE-NOTES.md。由于 liam-git-workflow 已有 CHANGELOG.md 记录版本变更，Release Notes 从 CHANGELOG.md 0.3.0 条目提炼。未来可考虑新增独立的 RELEASE-NOTES.md（不在本次 quick task 范围内）。
  </action>
  <verify>
    <automated>git tag -l v0.3.0</automated>
    <automated>gh release view v0.3.0 --json tagName,name,publishedAt 2>/dev/null || echo "gh not available — verify at https://github.com/bskle/liam-git-workflow/releases"</automated>
  </verify>
  <done>git tag v0.3.0 存在并已推送到远程，GitHub Release v0.3.0 已发布且包含完整的 Release Notes（如 gh CLI 不可用则提供手动创建指引）</done>
</task>

<task type="auto">
  <name>Task 3: 更新 README.md 增加插件市场安装说明</name>
  <files>README.md</files>
  <action>
  更新 README.md 的安装章节，增加 marketplace 安装方式，对标 superpowers README 中 "Claude Code — `/plugin install superpowers@claude-plugins-official`" 的写法。

  **当前 README.md 安装章节的问题**：
  - Claude Code 安装只写了本地路径方式（`/plugin install <仓库路径>`）
  - 没有提到插件市场安装命令
  - 没有提到用户如何添加自定义 marketplace 源

  **需要增加的内容**：

  在 README.md 的 "## 安装 → ### Claude Code 安装" 章节中，**在"方式 1: /plugin install (推荐)"之前**，新增一个更高优先级的方式：

  ```markdown
  ### Claude Code 安装

  **方式 1: 插件市场安装（推荐）**

  通过 Claude Code 插件市场一键安装：

  ```text
  /plugin marketplace add obra/superpowers-marketplace
  /plugin install liam-git-workflow@superpowers-marketplace
  ```

  安装后，所有 Git 工作流技能通过 Skill tool 自动可用。

  **方式 2: /plugin install 本地路径**

  在 Claude Code 会话中运行:
  ```text
  /plugin install <仓库路径>
  ```

  Claude Code 会自动发现 `.claude-plugin/plugin.json`，加载 skills/ 目录中的全部技能，并注册 hooks/ 中的钩子。

  **方式 3: 启动参数**
  ...（保持原有内容）
  ```

  **注意事项**：
  - 方式 1 依赖 `obra/superpowers-marketplace` 中已收录此插件（见 Task 4 后续步骤）
  - 如果 marketplace 还未收录，方式 1 暂时不可用，用户使用方式 2 或 3
  - 在 marketplace 未收录时，方式 1 前可以加注释 `<!-- TODO: 插件收录到 superpowers-marketplace 后启用 -->`

  实际做法（在 marketplace PR 未合并前）：在方式 1 前面添加提示：
  ```markdown
  > **注意**: 插件市场收录正在申请中（等待 PR 合并到 superpowers-marketplace）。收录完成前请使用方式 2（本地路径安装）。
  ```
  </action>
  <verify>
    <automated>grep -q "superpowers-marketplace" README.md && echo "Marketplace install section exists" || echo "MISSING"</automated>
    <automated>grep -q "claude plugins install" README.md && echo "Install command exists" || echo "MISSING"</automated>
  </verify>
  <done>README.md 包含 marketplace 安装方式，对标 superpowers 的插件市场安装体验</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| 无新增边界 | 本次为纯文档/配置变更，不涉及代码执行或用户数据 |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-quick-01 | Spoofing | GitHub Release | accept | GitHub Release 依赖 GitHub 平台认证，无新增攻击面 |
| T-quick-02 | Tampering | marketplace.json PR | accept | PR 由 superpowers-marketplace 维护者审核，合并后生效 |
</threat_model>

<verification>
- [ ] `node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/plugin.json','utf8'))"` 通过（plugin.json 是合法 JSON）
- [ ] plugin.json 包含 homepage, repository, license 字段
- [ ] LICENSE 文件存在且为标准 MIT 文本
- [ ] `git tag -l v0.3.0` 返回 v0.3.0
- [ ] GitHub Release v0.3.0 可访问
- [ ] README.md 包含 marketplace 安装说明
</verification>

<success_criteria>
- [ ] plugin.json 字段与 superpowers 对齐（homepage, repository, license, author.email 全部就位）
- [ ] LICENSE 文件存在（MIT），与 superpowers 许可策略一致
- [ ] GitHub Release v0.3.0 已发布，包含 Release Notes
- [ ] README.md 包含 marketplace 安装命令
- [ ] 仓库达到可提交 PR 到 superpowers-marketplace 的状态（余下工作仅为 PR 提交和审核）
</success_criteria>

<output>
After completion, create `.planning/quick/260604-bww-liam-git-workflow-claude-code-claude-plu/260604-bww-SUMMARY.md`
</output>

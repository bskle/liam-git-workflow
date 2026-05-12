# Commit Rules

## Format

```text
<type>(<scope>): <subject>
```

## Requirements

- `subject` should be Chinese
- use imperative tone
- keep it concise
- do not mix unrelated changes

## Allowed Types

- `feat`
- `fix`
- `docs`
- `chore`
- `refactor`
- `test`
- `build`
- `ci`
- `perf`
- `revert`

## Examples

- `feat(api): 新增术语查询接口`
- `fix(login): 修复网络异常重试逻辑`
- `docs(deploy): 补充部署日志维护说明`
- `chore(tooling): 调整本地校验脚本`
- `refactor(service): 拆分翻译服务校验逻辑`

## Scope Guidance

- prefer module or feature scope
- avoid empty scope when a clear scope exists
- keep scope English and compact


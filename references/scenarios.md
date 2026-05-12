# Common Scenarios

## Create a production bug branch

Input:

```text
$liam-git-workflow
创建一个线上bug修复的分支，修复login出现的网络问题
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
检查我的git全局配置
```

Expected output:

- current config values
- drift from policy
- suggested commands to align


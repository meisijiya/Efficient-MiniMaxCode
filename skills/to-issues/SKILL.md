---
name: to-issues
description: "把 plan / spec / PRD 拆成可独立领取的 issue（vertical slice / tracer bullet）。适用于 GitHub Issues / mavis team plan tasks / Jira 等任何 issue tracker。触发词：to-issues, 拆issue, 拆任务, issue拆分, vertical slice, 切片, PRD拆分, 需求拆解, 任务分解, issue tracker, tracer bullet"
---

# To Issues — Spec/PRD → 独立 Issue（vertical slice）

> 来自 mattpocock/skills 的 `to-issues`，adapted 到 MiniMax Code 体系。
> 单职责：**把任何"计划 / 规范 / PRD"切成可独立领取、可独立验收的 issue**。不写代码、不产 spec——只切分。

## 触发场景

- spec-miner 产出了 spec，下一步需要"怎么干"
- 用户给了 PRD / 大需求 / 模糊目标，要落地为可分配任务
- 复杂任务跨多个模块 / 多个服务，需要并行开发
- 已有 issue 列表但粒度太粗 / 太细
- 跨库迁移、新模块开发、整体重构

**不适用**：单个 bug 修复 / 单文件改动 / 性能优化——这些直接给 coder。

## 核心原则：Vertical Slice（Tracer Bullet）

```
WRONG（horizontal slice — 按层分）：
  Issue 1: 建数据库表
  Issue 2: 写 repository
  Issue 3: 写 service
  Issue 4: 写 controller
  Issue 5: 写前端

RIGHT（vertical slice — 按端到端切）：
  Issue 1: 用户注册端到端（DB + repo + service + API + 测试）
  Issue 2: 用户登录端到端（同上）
  Issue 3: 密码重置端到端（同上）
```

每片 issue 是**窄但完整**的端到端切片：
- ✅ 完成后**可独立演示 / 可独立验收**
- ✅ 穿过所有集成层（schema → API → UI → 测试）
- ❌ 不出现"等所有 layer 都写完才能 demo"

## 工作流

### 1. 收集 context
- 从对话历史 / spec-miner 输出 / PRD / 用户 issue 引用（issue 号 / URL / 路径）取
- 如果是路径/URL，读完整 body + 评论

### 2. 探索 codebase（可选）
- 不熟的项目：跑 `code-reader` 摸清现状
- **用项目自己的领域词汇**（看 `project-context` skill 的 domain glossary）
- 看 ADR（架构决策记录）遵守之
- **寻找可 prefactor 的地方** —— "Make the change easy, then make the easy change"

### 3. 拟 vertical slice

按以下规则切：

```
<vertical-slice-rules>
- 每片 = 窄但完整的端到端路径（schema + API + UI + tests）
- 完成的 slice 必须可 demo / 可独立验收
- 任何 prefactoring 必须先单独一片做掉
- slice 粒度：1-3 天工作量（不能 1 周一片，也不能 1 小时一片）
- 依赖关系清晰标注（Blocked by）
</vertical-slice-rules>
```

### 4. 让用户审（matt 的 "Quiz the user"）

展示拟好的列表，每片包含：
- **Title**：简短描述
- **Blocked by**：依赖哪几片（前置）
- **User stories covered**：覆盖哪些用户故事

问用户：
1. 粒度对吗？（太粗 / 太细）
2. 依赖关系对吗？
3. 哪些片要合并 / 拆分？

**迭代到用户 approve**。

### 5. 发布到 issue tracker

按依赖顺序发布（blocker 先），让后置片可以引用真实 issue ID。

#### 选项 A：GitHub Issues

每个 issue body：
```markdown
## Parent
引用父 issue（如果有）。

## What to build
简洁的端到端行为描述。**不要写具体文件路径或代码片段**——会过时。
例外：prototype 产出的精确决策（state machine / reducer / schema / type shape）可以 inline，并简短标注"来自 prototype"。

## Acceptance criteria
- [ ] 端到端 demo 通过
- [ ] 单测覆盖关键路径
- [ ] 集成测试覆盖跨层边界

## Blocked by
#<issue-id>（如果非首片）

## Triage
`<triage-label>`（来自项目约定）
```

#### 选项 B：Mavis team plan tasks（**默认推荐**）

直接转成 `mavis team plan` 的 task 列表——自带 verify 机制：
```yaml
- id: <slice-id>
  title: <slice title>
  prompt: |
    实施 <slice>：<end-to-end behavior>。
    Acceptance:
    - <criterion 1>
    - <criterion 2>
  assigned_to: coder
  verified_by: verifier
  verify_prompt: |
    独立验证 <slice>：
    1. demo <end-to-end>
    2. 跑 test 套件
    3. review code diff
  depends_on: [<blocker-slice-ids>]
  max_retries: 2
```

#### 选项 C：Jira / Linear / 其他

按对应 tracker 模板。

## 跟其他 skill 的联动

| 阶段 | 联动 skill / agent |
|------|-------------------|
| 拿到 spec / PRD | `spec-miner` |
| 切分前要更多 context | `code-reader` |
| 切分后实施 | `coder` + `implement` |
| 验收每片 | `verifier` |
| 跨片架构审查 | `architect` |

## 红线

- **不要**写具体文件路径或代码片段到 issue body（会过时）
- **不要**切 horizontal slice（按层分）
- **不要**让一片跨周（粒度太粗）
- **不要**让一片跨小时（粒度太细）
- **不要**忘记 prefactor——"先做易改的，再做改动本身"
- **不要**跳过用户确认（Quiz 步骤）

## 怎么算"在工作"

- 用户没反对"切得太碎 / 太粗"
- 每片都有清晰 acceptance criteria
- 依赖关系准确（无循环）
- 每片完成后可独立 demo

---

**怎么算"在工作"**：用户在 Quiz 步骤主动质疑粒度 / 合并 / 拆分——说明切片在帮用户思考，不是机械执行。
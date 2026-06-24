# Skill Routing Knowledge — 怎么选 skill (2026-06-24)

> **目的**: 解决 v0.4.0 ADR 发现的 4 个 cluster skill 描述重叠 (TDD/Plan/委派/Review)
> **场景**: 任何 agent 收到 task 时, 根据 task 性质选 skill
> **维护**: 单一作者 (meta-writer), cluster 拆分要改本表 + 改 skill description

---

## 0. 路由总则 (3 步决策)

```
Step 1: task 在哪个阶段?
        spec-miner (需求) / planner (方案) / coder (实施) / verifier (审查) / release-manager (发布)

Step 2: 这个阶段用什么 skill (按本表)?

Step 3: skill 必须 load (must-load 段) — 见各 agent.md "🔌 Must-Load Skills" 段
```

**反模式**:
- ❌ "TDD 类 task" 不知道用 test-driven-development 还是 verification-loop
- ❌ "做个 plan" 不知道用 writing-plans / plan-workflow / implement / executing-plans
- ❌ 同一 task load 4 个 cluster skill 重复触发

---

## 1. Cluster A: TDD / 验证 4 件套 (按任务阶段选)

| Skill | 适用阶段 | 触发词 | 何时**不**用 |
|-------|---------|--------|------------|
| `verification-loop` | **任务设计** (spec-miner) | "怎么知道这个 task 算做完" / "成功标准" / "可验证的成功标准" | ❌ 写代码时不用 / ❌ 提交前不用 |
| `test-driven-development` | **写代码** (coder) | "实现前先写测试" / "TDD" / "红绿循环" | ❌ 任务设计时不用 / ❌ 提交前不用 |
| `verification-before-completion` | **提交前** (coder/release-manager) | "完成前 evidence" / "跑测试确认" / "提交前验证" | ❌ 写代码时不用 / ❌ 任务设计时不用 |
| `implement` | **完整 SOP** (coder 全流程) | "PRD 转代码" / "端到端实施" / "6 步 SOP" | ❌ 单步任务不用 / ❌ 审查不用 |

**4 件套边界** (按 description):
- `verification-loop` = 模糊任务 → **可验证成功标准** (设计阶段工具)
- `test-driven-development` = 实现前先写测试 (写代码阶段工具)
- `verification-before-completion` = 提交前 evidence-based 自检 (提交阶段工具)
- `implement` = PRD → 代码 完整 6 步 SOP (端到端)

**冲突解决决策树**:
```
用户 task 是 "做 PRD 转代码"?
  → 4 选 1: implement (一站式)
用户 task 是 "加个功能"?
  → 2 选 1: test-driven-development (有测试要求) OR implement (完整流程)
用户 task 是 "这个 task 怎么算做完"?
  → 唯一: verification-loop
用户 task 是 "准备 commit"?
  → 唯一: verification-before-completion
```

---

## 2. Cluster B: 委派 2 件套 (按并发场景选)

| Skill | 适用场景 | 触发词 |
|-------|---------|--------|
| `subagent-driven-development` | 串行 multi-task 派 worker (subagent 启动) | "派 sub-agent" / "执行 plan" / "独立 task 串行" |
| `dispatching-parallel-agents` | 并行 multi-task 派 worker (同时跑) | "并行 2+ 任务" / "max_concurrency > 1" / "派 worker 同时跑" |

**2 件套边界**:
- `subagent-driven-development` = 1 个 worker 跑 1 个 task, 多个 worker **串行**或**有依赖**
- `dispatching-parallel-agents` = 2+ worker **同时**跑,**无依赖** (parallel-write 边界: 不能改同文件)

**冲突解决决策树**:
```
多个 task 互相依赖 (A 完成后 B 才能跑)?
  → 唯一: subagent-driven-development
多个 task 互不依赖 (可同时跑)?
  → 唯一: dispatching-parallel-agents
```

---

## 3. Cluster C: Plan 4 件套 (按规划阶段选)

| Skill | 适用场景 | 触发词 |
|-------|---------|--------|
| `writing-plans` | 从 spec 出多步 plan (obra) | "spec 转 plan" / "多步 task 计划" |
| `plan-workflow` | Mavis 内部 /plan 工作流 (spec-miner→planner→coder 流水线) | "/plan" / "Mavis plan 流水线" |
| `executing-plans` | 已有 plan 的执行 (obra) | "执行已有 plan" / "plan 在手上" |
| `implement` | **plan + 实施** (SOP 全包) | "PRD 转代码 SOP" |

**4 件套边界**:
- `writing-plans` = plan **创作** (从 spec 开始)
- `plan-workflow` = mavis **自家** 流水线 (触发 spec-miner agent)
- `executing-plans` = plan **执行** (obra 工作流, 你已有 plan)
- `implement` = plan + 实施 (中文 SOP 全包, 适合中文 user)

**冲突解决决策树**:
```
用户用英文, 已有 spec, 要 plan?
  → 唯一: writing-plans (obra 标准)
用户说 "/plan" 或 "走 plan 流程"?
  → 唯一: plan-workflow (mavis 内部)
用户用英文, 已有 plan, 要跑?
  → 唯一: executing-plans (obra 标准)
用户用中文, PRD/spec 起步, 一站式?
  → 唯一: implement (中文 SOP)
```

---

## 4. Cluster D: Review 2 件套 (按角色选)

| Skill | 适用角色 | 触发词 |
|-------|---------|--------|
| `requesting-code-review` | **请求** review 的人 (coder) | "请 verifier 看下" / "派 review 任务" / "4-step SOP" |
| `receiving-code-review` | **接受** review 的人 (coder 被 review 后) | "收到 PR review" / "防表演性同意" / "verify before apply" |

**2 件套边界**:
- `requesting-code-review` = 你**派**别人 review 你的代码
- `receiving-code-review` = 你**收到**别人的 review 反馈

**不冲突** (互补), 但**触发词**重叠, 需明确**角色**。

---

## 5. must-load 联动 (跨 agent 一致性)

每个 agent 的 `🔌 Must-Load Skills` 段 (v0.4.0 D-P0-NEW-3 强制) 决定:
- agent 启动时必须 load 哪些 skill
- 例: coder 必须 load `test-driven-development` + `verification-before-completion`
- 例: verifier 必须 load `using-superpowers` + `verification-before-completion` + `receiving-code-review`

**位置统一**: 所有 13 agent 的 must-load 段都在 **marker 之后, 标题之前** (顶部)。位置不一致会视觉混乱。

---

## 6. 路由表使用示例

**场景 A: 用户说"帮我加个新功能"**
```
1. mavis 路由 → coder agent
2. coder must-load: test-driven-development + verification-before-completion
3. coder 选 skill: test-driven-development (Cluster A 写代码阶段)
4. 完成后: verification-before-completion (提交前 evidence)
```

**场景 B: 用户说"做个 plan"**
```
1. mavis 路由 → planner agent (或 spec-miner 先)
2. planner 选 skill: writing-plans (Cluster C 英文) OR plan-workflow (mavis 内部)
3. 用户用中文 + PRD: implement (Cluster C 中文 SOP)
```

**场景 C: 用户说"几个独立 task 并行跑"**
```
1. mavis 路由 → mavis team plan
2. mavis 委派 coder
3. coder 选 skill: dispatching-parallel-agents (Cluster B 并行)
4. 不能改同文件 (parallel-write 边界)
```

---

## 7. 维护规则

- **新加 skill** → 必须 (a) 写 description 触发词, (b) 决定 cluster, (c) 更新本表
- **改 skill description** → 必须同步更新本表
- **cluster 重叠 > 3 skill** → 必须拆分 (拆 1 个, 改 description 划清边界)
- **每个 cluster max 4 skill**, 超过拆

---

## 8. 关联文档

- `docs/OPTIMIZATION-v0.4.0-ADR.md` — v0.4.0 ADR (D-P0-2 / D-P0-6 / D-P0-NEW-3 触发)
- `docs/RECIPES/windows-powershell-utf8-zhcn.md` — PowerShell 中文乱码修复
- `AGENTS.md` — 13 agent 索引 + must-load 联动表
- `SKILLS.md` — 43 skill 完整索引

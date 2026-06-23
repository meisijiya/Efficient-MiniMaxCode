---
name: implement
description: "把 PRD / spec / issue 列表转成可工作代码的完整 SOP。覆盖：plan → TDD → typecheck → test → review → commit。整合 Mavis 现有 agent (coder / test-writer / verifier / build-error-resolver)。触发词：implement, 实施, 落地, 实现, plan-to-code, PRD-to-code, spec-to-code, issue-to-code, TDD流程, 编码流程, 实施工作流"
---

# Implement — PRD/Issue → 代码的完整 SOP

> 来自 mattpocock/skills 的 `implement`（原版只 14 行，扩展为完整 SOP）。
> 单职责：**协调** PRD/Issue → 代码 的端到端实施流程。不写代码——那是 coder。
> **真正干活的是 Mavis agent 团队**：coder / test-writer / verifier / build-error-resolver。

## 触发场景

- spec-miner 产 spec + to-issues 切成 issue 列表后，开始实施
- 用户给 PRD 说"按这个实施"
- GitHub Issues / mavis plan task 列表已 ready，开始动手
- 复杂模块从 0 到 1 开发

**不适用**：单 bug 修复 / 单文件改动 / 性能优化 / 纯文档——这些直接给 coder / test-writer。

## 核心原则（matt 原版精髓）

1. **用 /tdd 在预先约定的 seams 边界**——红绿重构循环
2. **定期 typecheck + 单文件 test**——不要攒到最后
3. **完整 test suite 跑一次**——只在最后
4. **完成后用 /review 审一遍**——verifier agent
5. **commit 到当前 branch**——单 commit 或逻辑切片 commits

## 工作流（6 步）

### Step 1: 读取输入

- **从哪里**：
  - spec-miner 产出的 `spec.md` + to-issues 切出的 issue 列表
  - GitHub Issues（带 `to-implement` 标签）
  - mavis team plan task 列表（`depends_on` 已就绪的 ready 任务）
  - 用户口述："按这个 PRD 实现"

- **读什么**：
  - spec / PRD 全文
  - 所有 issue 的 acceptance criteria
  - 依赖关系（哪些先做）
  - 关联 ADR（架构约束）

### Step 2: Plan（**不写代码**）

调用 `coder` agent（或自己规划）：
- 对每个 issue 拆 sub-task：
  - **要新建哪些文件**（module / class / test）
  - **要改哪些现有文件**（影响面）
  - **要写哪些 test**（unit / integration / e2e）
  - **TDD seams 在哪**（哪些边界先用 test 钉住）
- 输出 sub-task 列表（5-30 项），用户确认

> 复杂时直接 spawn `mavis team plan`：
> ```bash
> mavis team plan run <plan.yaml>
> ```
> plan 内每个 sub-task = 一个 worker session。

### Step 3: TDD Loop（**核心**）

按 sub-task 顺序，每个 sub-task 跑：

```
RED:      写失败的 test（最先）
GREEN:    写最少代码让 test 通过
REFACTOR: 清理代码，保持 test 通过
REPEAT:   下一个 sub-task
```

**关键**：
- TDD 不是教条——只在"边界明确 + 业务规则清楚"的地方用
- 复杂集成 / UI / 异步代码可以**先 implementation 后补 test**
- 但**接口契约必须先 test**——这是 TDD 的真正价值

### Step 4: 持续验证（**不要攒**）

每完成一个 sub-task：

```bash
# 1. Type check（按语言）
mvn compile          # Java/Spring Boot
tsc --noEmit         # TypeScript
mypy .               # Python

# 2. 跑对应 sub-task 的 test
mvn test -Dtest=ClassName          # Java
pnpm test path/to/file.test.ts     # TS
pytest tests/test_file.py::test_X  # Python

# 3. 不要跑全 test suite（会慢）—— 最后才跑
```

**如果失败**：
- typecheck 错 → 调 `build-error-resolver`
- test 挂 → 看 diff，**先 reproduce → 找 root cause → 改**（不绕过）
- **不要** `--no-verify` 跳过 typecheck
- **不要** `it.skip()` 跳过 test

### Step 5: 完整验证 + Review

sub-task 全完后：

```bash
# 1. 跑全 test suite
mvn test             # Java
pnpm test            # TS
pytest               # Python

# 2. 调用 verifier agent 审
# mavis communication send --command spawn verifier "<diff 描述>"
```

**verifier 检查**：
- acceptance criteria 是否达成
- 4 层置信度门（karpathy 原则 4）
- Vibe Coding 5 实践（vibecoding-discipline skill）
- 是否有 silent failure（silent-failure-hunter）
- 架构是否合理（architect，重大改动时）

**verifier 出 BLOCK → 修复后重审**（不要 override accept 偷懒）。

### Step 6: Commit

```bash
# 单 commit（feature 完整）
git add -A
git commit -m "<type>(<scope>): <description>

<detail 1>
<detail 2>

Refs: #<issue-id>
Test: <怎么验证>
"

# 或多个 commits（按 vertical slice 切分）
```

**commit 规范**（参考 git-workflow-and-versioning skill）：
- type: feat / fix / refactor / test / docs / chore
- scope: 模块名
- title < 72 字符
- body 解释 why（不是 what）

## 跟其他 skill / agent 的联动

| 阶段 | 联动 |
|------|------|
| Plan sub-task | `coder` agent |
| 写 test | `test-writer` skill（边界 + 异常 + mock） |
| Typecheck 失败 | `build-error-resolver` agent |
| 边界性能问题 | `performance-analyzer` skill |
| 错误处理 / 吞错 | `silent-failure-hunter` agent |
| 架构审查 | `architect` agent（重大改动时） |
| 最终验证 | `verifier` agent |
| 删过度设计 | `code-simplifier` agent（提交前） |

## 跟 to-issues 的边界

| Skill | 输入 | 输出 |
|-------|------|------|
| **to-issues** | spec / PRD / 大需求 | issue 列表（vertical slice） |
| **implement**（这个） | issue 列表 | 代码 + test + commit |

**链式**：spec-miner → to-issues → **implement** → verifier → release-manager

## 红线

- **不要**没 acceptance criteria 就动手——回去问用户 / 看 spec
- **不要**跳过 TDD 边界——接口契约必须先 test
- **不要**攒到最后跑 typecheck / test——每个 sub-task 后跑
- **不要**忽略 verifier BLOCK——要么修，要么 override_accept with reason
- **不要**写巨大单 commit——按 vertical slice 切
- **不要**写巨大单 PR——一个 issue = 一个 PR（PR 比 issue 大就拆）

## 怎么算"在工作"

- test 覆盖率不下降
- 每个 vertical slice 独立可演示
- typecheck 全过 + 全 test suite 全过
- verifier 没出 BLOCK（或 BLOCK 都修了）
- commit 历史清晰（按 slice 切分）
# Agent Index (13)

> Last verified: 2026-06-24 | Total: 13 agents
> Auto-regenerated from `agents/<name>/agent.md` content. This is the canonical "which agent does what" quick reference.

## Quick Reference

| Trigger | Agent |
|---------|-------|
| "帮我做 XX" / "加功能" / "改代码" / "修 bug" | `coder` |
| "看下这个" / "审查" / "提 PR" | `architect` + `verifier` (2 layers) |
| "架构对吗" / "新模块" / "重构" / "schema 改" | `architect` |
| "代码对吗" / "边界过吗" / "性能" | `verifier` |
| "为什么不生效" / "数据丢了" / "没报错但 XX" | `silent-failure-hunter` |
| "代码太啰嗦" / "砍一下" / "简化" | `code-simplifier` |
| "需求不清楚" / "先挖一个" / "做个 plan" | `spec-miner` → `planner` |
| "build 挂了" / "测试挂了" / "编译报错" | `build-error-resolver` |
| "加测试" / "补测试" | `test-writer` (skill) |
| "摸清这个模块" / "Code Map" / "这个盘干嘛的" | `code-reader` (skill) |
| "性能问题" / "慢死了" / "profile" | `performance-analyzer` (skill) |
| "记一个决策" / "写 ADR" | `meta-writer` |
| "上线" / "发布" / "changelog" / "打 tag" | `release-manager` |
| "审计" / "合规" / "安全" / "PII" / "依赖" | `auditor` (重大决策时) |
| "我不知道该找谁" | `mavis` (我先判断) |

---

## Detailed Roles

### `mavis` — Root Orchestrator
- **Type**: Orchestrator
- **Role**: 7-step pipeline routing + decision tree + failure fallback
- **Trigger**: Any ambiguous user intent
- **Loads skills**: `using-superpowers`, `brainstorming`, `writing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `verification-before-completion`, `vibecoding-discipline`
- **Key files**: `mavis/agent.md`

### `coder` — Software Engineer
- **Type**: Worker
- **Role**: Write code (Spring Boot / TS / Python priority)
- **4 principles**: Think / Simplicity / Surgical / Goal-driven
- **Loads skills**: `test-driven-development`, `verification-before-completion`, `systematic-debugging`, `vibecoding-discipline`, `backend-patterns-java`, `backend-patterns-typescript`, `backend-patterns-python`
- **Key files**: `coder/agent.md`

### `architect` — Architectural Reviewer
- **Type**: Worker
- **Role**: Module boundaries / interfaces / data flow / state ownership / dependency direction
- **Does NOT do**: Code details, error handling, performance
- **Loads skills**: `using-superpowers`, `vibecoding-discipline`, `verification-before-completion`
- **Key files**: `architect/agent.md`

### `verifier` — Adversarial Code Reviewer
- **Type**: Worker
- **Role**: 4-layer confidence gate + Vibe Coding 5-practice review
- **Verdicts**: APPROVE / WARNING / BLOCK
- **Loads skills**: `using-superpowers`, `verification-before-completion`, `receiving-code-review`, `requesting-code-review`
- **Key files**: `verifier/agent.md`

### `silent-failure-hunter` — Silent Failure Specialist
- **Type**: Worker
- **Role**: 7 silent-failure patterns (empty catch / swallowed errors / fire-and-forget / default-value masking / early-return-without-error / async race / silent rollback)
- **Trigger**: Production incident with no error log
- **Loads skills**: `using-superpowers`, `systematic-debugging`, `observability-and-instrumentation`
- **Key files**: `silent-failure-hunter/agent.md`

### `code-simplifier` — Over-engineering Remover
- **Type**: Worker
- **Role**: Trim 200-line code to 50 — only removes, never adds
- **Trigger**: "这代码怎么这么啰嗦"
- **Loads skills**: `using-superpowers`, `test-driven-development`, `verification-before-completion`, `vibecoding-discipline`
- **Key files**: `code-simplifier/agent.md`

### `spec-miner` — Requirement Archaeologist
- **Type**: Worker
- **Role**: Vague requirement → structured spec (with non-goals + acceptance criteria)
- **Trigger**: User says "做个 XX" without clear scope
- **Loads skills**: `using-superpowers`, `brainstorming`
- **Key files**: `spec-miner/agent.md`

### `planner` — Strategic Planner
- **Type**: Worker
- **Role**: Architecture + product spec + executable plan (multi-phase, independently mergeable)
- **Trigger**: Complex feature / refactor / architecture decision
- **Loads skills**: `using-superpowers`, `writing-plans`, `executing-plans`
- **Key files**: `planner/agent.md`

### `build-error-resolver` — Build Error Fixer
- **Type**: Worker
- **Role**: Targeted build / lint / test failure fix
- **Also handles**: `test-runner` role (runs tests, not just writes them)
- **Loads skills**: `using-superpowers`, `systematic-debugging`, `test-driven-development`, `verification-before-completion`
- **Key files**: `build-error-resolver/agent.md`

### `meta-writer` — Metadata Single-writer
- **Type**: Worker
- **Role**: 11-type project metadata (ADR / DECISIONS / KNOWLEDGE / INSTINCTS / etc.) — single-writer iron rule
- **Trigger**: Made a non-trivial decision
- **Loads skills**: `using-superpowers`, `writing-plans`, `verification-before-completion`, `vibecoding-discipline`
- **Key files**: `meta-writer/agent.md`

### `auditor` — Security / Compliance Auditor
- **Type**: Worker
- **Role**: 6 audit dimensions (input validation / authN-Z / sensitive data / dependencies / config-deploy / business logic)
- **Trigger**: 重大决策 (payment / PII / GDPR / new deps / auth)
- **Default**: NOT spawned. Only via `mavis` upgrade path.
- **Loads skills**: `using-superpowers`, `verification-before-completion`
- **Key files**: `auditor/agent.md`

### `release-manager` — Release Conductor
- **Type**: Worker
- **Role**: 7-step release flow (pre-flight / changelog / version+tag / commit+push / deploy / post-deploy verify / notify+document) + rollback
- **Trigger**: "上线" / "发布" / "打 tag" / `release/vX.Y` branch
- **Loads skills**: `using-superpowers`, `finishing-a-development-branch`, `verification-before-completion`
- **Key files**: `release-manager/agent.md`

### `general` — Generic Fallback
- **Type**: Worker
- **Role**: Generic worker, routes to specialists when needed
- **Use case**: One-off tasks without a specialist
- **Loads skills**: `using-superpowers`
- **Key files**: `general/agent.md`

---

## Review Layer Configuration

**Default**: 2 layers (`architect` + `verifier`)
**Upgrade to 3 layers**: Add `auditor` when ANY of:
- Payment / money / financial
- PII / GDPR / CCPA / compliance
- New dependency / new middleware
- Auth / permission / OAuth / JWT
- Database schema major change

**Don't use 4 layers** by default. The "business reviewer" role is handled by `spec-miner` in the upfront phase — adding a 4th reviewer would duplicate work.

See `mavis/agent.md` (routing table section) for the full decision tree.

---

## must-load skill 联动 (v0.4.0 D-P0-NEW-3)

每个 agent 启动时**强制 load** 的 obra skill（声明在本 agent.md 的 "必须加载" 段）：

| Agent | Must-load (obra) | 关联 |
|-------|------------------|------|
| `mavis` | using-superpowers (meta) | 启动先 load |
| `coder` | test-driven-development, verification-before-completion, systematic-debugging | 写代码前 |
| `verifier` | using-superpowers, verification-before-completion, receiving-code-review, requesting-code-review | 审查前 |
| `silent-failure-hunter` | systematic-debugging, using-superpowers | 找 silent failure 前 |
| `code-simplifier` | test-driven-development, verification-before-completion, vibecoding-discipline | 删前看 test |
| `spec-miner` | brainstorming | 挖需求前 |
| `planner` | writing-plans, executing-plans | 出 plan 前 |
| `build-error-resolver` | systematic-debugging, test-driven-development, verification-before-completion | 跑+修前 |
| `meta-writer` | writing-plans, verification-before-completion | 写 ADR 前 |
| `auditor` | verification-before-completion | 审计前 |
| `release-manager` | finishing-a-development-branch, verification-before-completion | 发布前 |
| `general` | using-superpowers | fallback |
| `architect` | vibecoding-discipline, verification-before-completion | 架构审前 |

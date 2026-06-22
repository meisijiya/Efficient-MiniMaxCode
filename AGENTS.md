# Agent Index (13)

> This index is auto-generated from the actual `agent.md` content. Use it as a quick reference for "which agent does what".

## Quick Reference

| Trigger | Agent |
|---------|-------|
| "做 XX" / "加功能" / "改代码" / "修 bug" | `coder` |
| "看这版" / "审查" / "提 PR" | `architect` + `verifier` (2 layers) |
| "架构对吗" / "新模块" / "重构" / "schema 改" | `architect` |
| "代码对吗" / "边界过吗" / "性能" | `verifier` |
| "为什么没生效" / "数据丢了" / "没报错但 XX" | `silent-failure-hunter` |
| "代码太啰嗦" / "砍一下" / "简化" | `code-simplifier` |
| "需求不清楚" / "先挖一下" / "做个 plan" | `spec-miner` → `planner` |
| "build 红了" / "测试挂了" / "编译报错" | `build-error-resolver` |
| "加测试" / "补测试" | `test-writer` (skill) |
| "摸清这模块" / "Code Map" / "这个干什么的" | `code-reader` (skill) |
| "性能问题" / "慢死了" / "profile" | `performance-analyzer` (skill) |
| "记一下决策" / "写 ADR" | `meta-writer` |
| "上线" / "发布" / "changelog" / "打 tag" | `release-manager` |
| "审计" / "合规" / "安全" / "PII" / "依赖" | `auditor` (重大决策时) |
| "我不知道该找谁" | `mavis` (我先判断) |

---

## Detailed Roles

### `mavis` — Root Orchestrator
- **Type**: Orchestrator
- **Role**: 7-step pipeline routing + decision tree + failure fallback
- **Trigger**: Any ambiguous user intent
- **Key files**: `mavis/agent.md`

### `coder` — Software Engineer
- **Type**: Worker
- **Role**: Write code (Spring Boot / TS / Python priority)
- **4 principles**: Think / Simplicity / Surgical / Goal-driven
- **Loads skills**: `vibecoding-discipline`, `verification-loop`, `backend-patterns-*` (per language)
- **Key files**: `coder/agent.md` + `coder/.builtin-prompt-layout-v2`

### `architect` — Architectural Reviewer
- **Type**: Worker
- **Role**: Module boundaries / interfaces / data flow / state ownership / dependency direction
- **Does NOT do**: Code details, error handling, performance
- **Key files**: `architect/agent.md` + `PERSONA.md`

### `verifier` — Adversarial Code Reviewer
- **Type**: Worker
- **Role**: 4-layer confidence gate + Vibe Coding 5-practice review
- **Verdicts**: APPROVE / WARNING / BLOCK
- **Key files**: `verifier/agent.md` + `.builtin-prompt-layout-v2`

### `silent-failure-hunter` — Silent Failure Specialist
- **Type**: Worker
- **Role**: 7 silent-failure patterns (empty catch / swallowed errors / fire-and-forget / default-value masking / early-return-without-error / async race / silent rollback / log-to-blackhole)
- **Trigger**: Production incident with no error log
- **Key files**: `silent-failure-hunter/agent.md` + `PERSONA.md`

### `code-simplifier` — Over-engineering Remover
- **Type**: Worker
- **Role**: Trim 200-line code to 50 — only removes, never adds
- **Trigger**: "这代码怎么这么啰嗦"
- **Key files**: `code-simplifier/agent.md` + `PERSONA.md`

### `spec-miner` — Requirement Archaeologist
- **Type**: Worker
- **Role**: Vague requirement → structured spec (with non-goals + acceptance criteria)
- **Trigger**: User says "做个 XX" without clear scope
- **Key files**: `spec-miner/agent.md` + `PERSONA.md`

### `planner` — Strategic Planner
- **Type**: Worker
- **Role**: Architecture + product spec + executable plan (multi-phase, independently mergeable)
- **Trigger**: Complex feature / refactor / architecture decision
- **Key files**: `planner/agent.md` + `.builtin-prompt-layout-v2`

### `build-error-resolver` — Build Error Fixer
- **Type**: Worker
- **Role**: Targeted build / lint / test failure fix
- **Also handles**: `test-runner` role (runs tests, not just writes them)
- **Key files**: `build-error-resolver/agent.md` + `PERSONA.md`

### `meta-writer` — Metadata Single-writer
- **Type**: Worker
- **Role**: 11-type project metadata (ADR / DECISIONS / KNOWLEDGE / INSTINCTS / etc.) — **single-writer iron rule**
- **Trigger**: Made a non-trivial decision
- **Key files**: `meta-writer/agent.md` + `PERSONA.md`

### `auditor` — Security / Compliance Auditor
- **Type**: Worker
- **Role**: 6 audit dimensions (input validation / authN-Z / sensitive data / dependencies / config-deploy / business logic)
- **Trigger**: 重大决策 (payment / PII / GDPR / new deps / auth)
- **Default**: NOT spawned. Only via `mavis` upgrade path.
- **Key files**: `auditor/agent.md` + `PERSONA.md`

### `release-manager` — Release Conductor
- **Type**: Worker
- **Role**: 7-step release flow (pre-flight / changelog / version+tag / commit+push / deploy / post-deploy verify / notify+document) + rollback
- **Trigger**: "上线" / "发布" / "打 tag" / `release/vX.Y` branch
- **Key files**: `release-manager/agent.md` + `PERSONA.md`

### `general` — Generic Fallback
- **Type**: Worker
- **Role**: Generic worker, routes to specialists when needed
- **Use case**: One-off tasks without a specialist
- **Key files**: `general/agent.md` + `.builtin-prompt-layout-v2`

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

See `mavis/agent.md` (routing table section) for the decision tree.

# Agent Index (13)

> This index is auto-generated from the actual `agent.md` content. Use it as a quick reference for "which agent does what".

## Quick Reference

| Trigger | Agent |
|---------|-------|
| "鍋?XX" / "鍔犲姛鑳? / "鏀逛唬鐮? / "淇?bug" | `coder` |
| "鐪嬭繖鐗? / "瀹℃煡" / "鎻?PR" | `architect` + `verifier` (2 layers) |
| "鏋舵瀯瀵瑰悧" / "鏂版ā鍧? / "閲嶆瀯" / "schema 鏀? | `architect` |
| "浠ｇ爜瀵瑰悧" / "杈圭晫杩囧悧" / "鎬ц兘" | `verifier` |
| "涓轰粈涔堟病鐢熸晥" / "鏁版嵁涓簡" / "娌℃姤閿欎絾 XX" | `silent-failure-hunter` |
| "浠ｇ爜澶暟鍡? / "鐮嶄竴涓? / "绠€鍖? | `code-simplifier` |
| "闇€姹備笉娓呮" / "鍏堟寲涓€涓? / "鍋氫釜 plan" | `spec-miner` 鈫?`planner` |
| "build 绾簡" / "娴嬭瘯鎸備簡" / "缂栬瘧鎶ラ敊" | `build-error-resolver` |
| "鍔犳祴璇? / "琛ユ祴璇? | `test-writer` (skill) |
| "鎽告竻杩欐ā鍧? / "Code Map" / "杩欎釜骞蹭粈涔堢殑" | `code-reader` (skill) |
| "鎬ц兘闂" / "鎱㈡浜? / "profile" | `performance-analyzer` (skill) |
| "璁颁竴涓嬪喅绛? / "鍐?ADR" | `meta-writer` |
| "涓婄嚎" / "鍙戝竷" / "changelog" / "鎵?tag" | `release-manager` |
| "瀹¤" / "鍚堣" / "瀹夊叏" / "PII" / "渚濊禆" | `auditor` (閲嶅ぇ鍐崇瓥鏃? |
| "鎴戜笉鐭ラ亾璇ユ壘璋? | `mavis` (鎴戝厛鍒ゆ柇) |

---

## Detailed Roles

### `mavis` 鈥?Root Orchestrator
- **Type**: Orchestrator
- **Role**: 7-step pipeline routing + decision tree + failure fallback
- **Trigger**: Any ambiguous user intent
- **Key files**: `mavis/agent.md`

### `coder` 鈥?Software Engineer
- **Type**: Worker
- **Role**: Write code (Spring Boot / TS / Python priority)
- **4 principles**: Think / Simplicity / Surgical / Goal-driven
- **Loads skills**: `vibecoding-discipline`, `verification-loop`, `backend-patterns-*` (per language)
- **Key files**: `coder/agent.md`

### `architect` 鈥?Architectural Reviewer
- **Type**: Worker
- **Role**: Module boundaries / interfaces / data flow / state ownership / dependency direction
- **Does NOT do**: Code details, error handling, performance
- **Key files**: `architect/agent.md`

### `verifier` 鈥?Adversarial Code Reviewer
- **Type**: Worker
- **Role**: 4-layer confidence gate + Vibe Coding 5-practice review
- **Verdicts**: APPROVE / WARNING / BLOCK
- **Key files**: `verifier/agent.md`

### `silent-failure-hunter` 鈥?Silent Failure Specialist
- **Type**: Worker
- **Role**: 7 silent-failure patterns (empty catch / swallowed errors / fire-and-forget / default-value masking / early-return-without-error / async race / silent rollback / log-to-blackhole)
- **Trigger**: Production incident with no error log
- **Key files**: `silent-failure-hunter/agent.md`

### `code-simplifier` 鈥?Over-engineering Remover
- **Type**: Worker
- **Role**: Trim 200-line code to 50 鈥?only removes, never adds
- **Trigger**: "杩欎唬鐮佹€庝箞杩欎箞鍟板棪"
- **Key files**: `code-simplifier/agent.md`

### `spec-miner` 鈥?Requirement Archaeologist
- **Type**: Worker
- **Role**: Vague requirement 鈫?structured spec (with non-goals + acceptance criteria)
- **Trigger**: User says "鍋氫釜 XX" without clear scope
- **Key files**: `spec-miner/agent.md`

### `planner` 鈥?Strategic Planner
- **Type**: Worker
- **Role**: Architecture + product spec + executable plan (multi-phase, independently mergeable)
- **Trigger**: Complex feature / refactor / architecture decision
- **Key files**: `planner/agent.md`

### `build-error-resolver` 鈥?Build Error Fixer
- **Type**: Worker
- **Role**: Targeted build / lint / test failure fix
- **Also handles**: `test-runner` role (runs tests, not just writes them)
- **Key files**: `build-error-resolver/agent.md`

### `meta-writer` 鈥?Metadata Single-writer
- **Type**: Worker
- **Role**: 11-type project metadata (ADR / DECISIONS / KNOWLEDGE / INSTINCTS / etc.) 鈥?**single-writer iron rule**
- **Trigger**: Made a non-trivial decision
- **Key files**: `meta-writer/agent.md`

### `auditor` 鈥?Security / Compliance Auditor
- **Type**: Worker
- **Role**: 6 audit dimensions (input validation / authN-Z / sensitive data / dependencies / config-deploy / business logic)
- **Trigger**: 閲嶅ぇ鍐崇瓥 (payment / PII / GDPR / new deps / auth)
- **Default**: NOT spawned. Only via `mavis` upgrade path.
- **Key files**: `auditor/agent.md`

### `release-manager` 鈥?Release Conductor
- **Type**: Worker
- **Role**: 7-step release flow (pre-flight / changelog / version+tag / commit+push / deploy / post-deploy verify / notify+document) + rollback
- **Trigger**: "涓婄嚎" / "鍙戝竷" / "鎵?tag" / `release/vX.Y` branch
- **Key files**: `release-manager/agent.md`

### `general` 鈥?Generic Fallback
- **Type**: Worker
- **Role**: Generic worker, routes to specialists when needed
- **Use case**: One-off tasks without a specialist
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

**Don't use 4 layers** by default. The "business reviewer" role is handled by `spec-miner` in the upfront phase 鈥?adding a 4th reviewer would duplicate work.

See `mavis/agent.md` (routing table section) for the decision tree.

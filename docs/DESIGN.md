# Design Rationale

> Why 16 agents? Why 43 skills? Why this orchestration? This document explains the design decisions behind the Efficient-MiniMaxCode collection.

---

## 1. Why Split Into Agents (Not Just Skills)?

**Insight**: In a Mavis Code session, the difference between an `agent` and a `skill` is **who initiates**:
- **Agent**: spawned by the orchestrator (`mavis`) as a fresh sub-session. Has its own context, can use tools, returns a deliverable.
- **Skill**: loaded into the current session's context. Provides knowledge / patterns / methods, doesn't return a deliverable on its own.

**Rule of thumb**:
- If the task produces an **artifact** (code, report, fix, plan) → make it an **agent**.
- If the task provides **guidance** (patterns, methods, triggers) → make it a **skill**.

**In this collection**:
- Agents = things that *do* work (coder, verifier, architect, planner, meta-writer, release-manager, etc.)
- Skills = things that *guide* work (vibecoding-discipline, verification-loop, backend-patterns-*, etc.)

The 4-layer principle: **agents do, skills teach**.

---

## 2. Why 16 Agents (Not 30)?

Following the [ohMeisijiyaCode](https://github.com/meisijiya/ohMeisijiyaCode) principle: **agents are expensive** (each spawn = new LLM session + context). Don't add an agent if a prompt can be re-used.

**What we excluded** (and why):
- ❌ **`test-runner` agent** → folded into `build-error-resolver` (it already runs tests, not just writes them)
- ❌ **`db-migration` agent** → folded into `coder` (one task: schema change = entity + Flyway script together; architect reviews the schema)
- ❌ **`business-reviewer` agent** → folded into `spec-miner` (upfront phase covers business alignment)
- ❌ **`penetration-tester` agent** → out of scope; auditor does "adversarial review" but not red-team
- ❌ **`devops` agent** → release-manager triggers user-defined deploy scripts, doesn't write deploy logic
- ❌ **`database-admin` agent** → schema design in architect, schema migration in coder, query in performance-analyzer
- ❌ **`i18n-engineer` agent** → knowledge-digest + code-reader cover it for now

**Result**: 16 agents = 1 orchestrator + 14 specialists + 1 fallback. The smallest sufficient set.

**v0.4.2 expansion (13 → 16)**: We added 4 specialists that earn their own context:
- **`planner`** — 把 spec-miner 输出转成多 Phase implementation plan(vertical slice 优先,笔记启发 8)
- **`scout`** — 只读探索文件系统 / 代码库,返回结构化摘要(笔记启发 9:Pi Subagents Scout 等价,防止主 agent context 污染)
- **`incident-responder`** — 线上事故响应(报警 → 定位 → 临时缓解 → 复盘),**只响应,长期修复转 coder**
- **`doc-writer`** — 技术文档专职(API 文档 / 教程 / README / 内部 wiki),**不写元信息(归 meta-writer)**

---

## 3. Why 2-3 Layer Review (Not 4)?

**Original inspiration**: ohMeisijiyaCode v2.21 specifies 4-layer review (reviewer + architect + auditor + verifier).

**Why we reduced to 2-3**:
- The **business reviewer** role (does this match the user's need?) is **already done** in the upfront phase by `spec-miner`. Adding a 4th reviewer duplicates it.
- **Cost**: 4 layers = 4× tokens + 4× time. For small PRs, that's overkill.
- **Diminishing return**: Most of the value is in the first 2 layers (architect catches structural issues, verifier catches implementation issues). 3rd layer (auditor) only matters for security/compliance scenarios.

**Decision matrix**:

| Scenario | Layers |
|----------|--------|
| Small fix (≤2h, ≤10 lines) | `verifier` only |
| Feature (1-3 days) | `architect` + `verifier` |
| Major decision / security / PII / payment | `architect` + `verifier` + `auditor` |
| Never | 4 layers (redundant) |

---

## 4. Why the 7-Step Pipeline?

From ohMeisijiyaCode:
```
Think → Plan → Build → Review → Test → Ship → Reflect
```

**What each step does** (mapped to our agents):

| Step | Agent | Output |
|------|-------|--------|
| **Think** | `spec-miner` | Spec doc (with non-goals) |
| **Plan** | `planner` | Implementation plan (multi-phase, independently mergeable) |
| **Build** | `coder` | Diff + commit |
| **Review** | `architect` + `verifier` | Two review reports |
| **Test** | `test-writer` | Tests + coverage |
| **Ship** | `release-manager` | Tag + deploy + verify |
| **Reflect** | `meta-writer` | ADR / DECISION / KNOWLEDGE entry |

**Why this order matters**:
- Think before Plan: vague requirements lead to bad plans.
- Plan before Build: "complexity grows quadratically" without architectural discipline (Karpathy).
- Review before Test: cheap architectural issues caught early; expensive runtime issues caught late.
- Ship before Reflect: ship is the user-visible value; reflect is meta-info (skip if user wants speed).

---

## 5. Why Spring Boot / TS / Python Priority?

**User's stack** (from profile):
- Spring Boot 3+ / JVM 21+ (most familiar)
- TypeScript (Node/Express/NestJS) — secondary
- Python (FastAPI/Django) — secondary
- React/Next.js — growing into full-stack

**Implementation**:
- Three separate `backend-patterns-{lang}` skills (not one merged skill) → precise loading, smaller context per call
- All Spring Boot rules inlined into `coder/agent.md` (no need to load the skill for core rules)
- TS and Python skills cover language-specific patterns (Pydantic, Zod, async)

---

## 6. Why the 5-Decoupling Practice?

From the [Vibe Coding video (BV1v9ER68EJE)](https://www.bilibili.com):

> "AI 写代码越快，工程边界越不能糊。复杂度平方级增长——人定架构 AI 实现。"

The 5 practice:
1. **Interface separation** — depend on interface, not implementation
2. **Single responsibility** — one module, one job
3. **Composition over inheritance** — don't build 5-level inheritance trees
4. **Incremental delivery** — small mergeable commits, not big-bang
5. **Pure functions first** — minimize mutable state

**Why these 5 specifically**: They're the boundary between "code that AI can maintain" and "code that becomes legacy within weeks."

**Implementation**:
- `vibecoding-discipline/SKILL.md` — full definitions + examples
- All coding-related agents (`coder`, `verifier`, `architect`, `test-writer`) explicitly load this skill
- `verifier` uses the 5 practice as a checklist in every review

---

## 7. Karpathy 4-Principle Constitution

From [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) `CLAUDE.md`:

1. **Think Before Coding** — list assumptions, ask if multiple interpretations, push back if simpler
2. **Simplicity First** — only write what's asked, no "future-proofing hooks"
3. **Surgical Changes** — only touch what must be touched, match existing style
4. **Goal-Driven Execution** — turn imperative tasks into verifiable success criteria

**Implementation**:
- All four principles are inlined into `coder/agent.md` and `code-expert/SKILL.md` (renamed to `plan-workflow` in newer versions)
- The `verification-loop` skill operationalizes principle 4 (goal-driven loop)
- The `search-first` skill operationalizes principle 1 (think = research first)

---

## 8. Known Limitations

This collection is **not perfect**. Known issues:

- ❌ ~~**API design and frontend patterns skills are empty** (placeholders only). They need real content.~~ **Fixed 2026-06-23** — both skills now have full v1 content.
- ❌ **No auditor for run-time / observability** (only security / compliance). A future `observability-auditor` could review metrics / alerts / dashboards.
- ❌ **No multi-language README** yet (English only).
- ❌ **No CI** to validate agents don't exceed the Mavis daemon's 8000-byte `mavis agent new` limit (workaround: use `mavis agent update` for large prompts — see `mavis` memory entry).
- ❌ **No instinct library** in this repo (lives in `~/.mavis/memory/instincts/` separately, project-level).

### v0.4.3 新增已知问题(Mavis 工具链 silent-drop 家族)

**触发**:2026-06-24 19:34-21:55 注册 4 个新 agent 时反复栽在 daemon 注册流程

| # | 问题 | 影响 | Work-around |
|---|------|------|------------|
| **B-1** | `mavis agent new` 失败时 silent(0 退出码 + 无错误) | 用户无法判断成功/失败,反复"重启验证"浪费 1h+ | 用 Node `spawnSync('cmd.exe', [...])` 调 CLI 不传 `--system-prompt` |
| **B-2** | daemon 启动时不自检磁盘 vs sqlite,缺哪个不补 | 手动放文件注册的 agent 永远不被 daemon 发现 | 必须走 `mavis agent new` CLI 走一遍 |
| **B-3** | `mavis agent list` 不显示磁盘与 sqlite 差异 | 诊断"为什么不生效"时看不到孤儿 agent | 无 work-around,等 B-3 修复 |
| **silent-drop 家族** | agent.md >8000B / 中文长 prompt 走 PS 5.1 CLI / spawn 无 prompt | 多次"silent 失败"循环 | Edit/Write 工具(UTF-8 直通)+ YAML hardcode + scratchpad pointer |

**完整委派 SOP**:见 `skills/delegation-sop/SKILL.md`(v0.4.3 首次入库,243 行)

---

## 9. Future Work

- [x] Complete `api-design` and `frontend-patterns` skills — **done 2026-06-23**
- [x] Add `planner` / `scout` / `incident-responder` / `doc-writer` agents — **done v0.4.2** (13→16)
- [x] Add `delegation-sop` skill — **done v0.4.3** (Mavis 工具链 silent-drop 完整 SOP)
- [ ] **Backport v0.4.3 backlog B-1/B-2/B-3** — mavis 工具链注册流程可靠性修复
- [ ] Add CI with `mavis agent list` validation
- [ ] Add a `release` workflow (GitHub Actions to publish tagged versions)
- [ ] Translate README / DESIGN into English / 日本語
- [ ] Add an `examples/` directory showing real 7-step pipeline runs
- [ ] Add a `CONTRIBUTING.md` with agent / skill authoring guide
- [ ] Add `instincts/` to repo (currently project-level only)
- [ ] Backfill 5 skill gaps (3-layer router / spec-from-correction / context-reset / prompt-hardening / deep-modules)

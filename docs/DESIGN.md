# Design Rationale

> Why 13 agents? Why 21 skills? Why this orchestration? This document explains the design decisions behind the Efficient-MiniMaxCode collection.

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

## 2. Why 13 Agents (Not 30)?

Following the [ohMeisijiyaCode](https://github.com/meisijiya/ohMeisijiyaCode) principle: **agents are expensive** (each spawn = new LLM session + context). Don't add an agent if a prompt can be re-used.

**What we excluded** (and why):
- ❌ **`test-runner` agent** → folded into `build-error-resolver` (it already runs tests, not just writes them)
- ❌ **`db-migration` agent** → folded into `coder` (one task: schema change = entity + Flyway script together; architect reviews the schema)
- ❌ **`business-reviewer` agent** → folded into `spec-miner` (upfront phase covers business alignment)
- ❌ **`penetration-tester` agent** → out of scope; auditor does "adversarial review" but not red-team
- ❌ **`devops` agent** → release-manager triggers user-defined deploy scripts, doesn't write deploy logic
- ❌ **`database-admin` agent** → schema design in architect, schema migration in coder, query in performance-analyzer
- ❌ **`i18n-engineer` agent** → knowledge-digest + code-reader cover it for now

**Result**: 13 agents = 1 orchestrator + 11 specialists + 1 fallback. The smallest sufficient set.

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

---

## 9. Future Work

- [x] Complete `api-design` and `frontend-patterns` skills — **done 2026-06-23**
- [ ] Add CI with `mavis agent list` validation
- [ ] Add a `release` workflow (GitHub Actions to publish tagged versions)
- [ ] Translate README / DESIGN into English / 日本語
- [ ] Add an `examples/` directory showing real 7-step pipeline runs
- [ ] Add a `CONTRIBUTING.md` with agent / skill authoring guide
- [ ] Add `instincts/` to repo (currently project-level only)

# Skill Index (43)

> This index is auto-generated from the actual `SKILL.md` content. Use it as a quick reference for "which skill should I load for XX task".

## Quick Reference

| Task | Skill |
|------|-------|
| Write Java / Spring Boot code | `backend-patterns-java` |
| Write TypeScript / Node code | `backend-patterns-typescript` |
| Write Python / FastAPI / Django | `backend-patterns-python` |
| Design / review REST API | `api-design` (v1) |
| Design / review SQL schema | `database-patterns` |
| Write / refactor React component | `frontend-patterns` (v1) |
| Read / understand unfamiliar code | `code-reader` |
| Write tests (TDD-first) | `test-writer` |
| Profile / optimize performance | `performance-analyzer` |
| Plan a complex feature | `plan-workflow` (`/plan` command) |
| Apply 5-decoupling practice | `vibecoding-discipline` |
| Validate with goal-driven loop | `verification-loop` |
| Search docs / source first | `search-first` |
| Brainstorm a feature | `brainstorming` |
| Read / write Excel | `minimax-xlsx` |
| Read / write Office docs | `office-document-specialist-suite` |
| Make PowerPoint | `pptx-skill` |
| Build a prototype from PRD | `prd-to-prototype` |
| Generate image / video / audio | `ai-coder` (or `ai-short-drama-director`) |
| Humanize AI-written text | `ai-eraser-skills` |
| Digest learning material | `knowledge-digest` |
| Generate story video | `story-video-generator` |
| Split spec / PRD into vertical-slice issues | `to-issues` |
| Implement PRD / issues into code (TDD SOP) | `implement` |
| **Superpowers framework** (mandatory at conversation start) | `using-superpowers` |
| Brainstorm before creative work | `brainstorming` (obra) |
| Write implementation plan | `writing-plans` |
| Execute plan with checkpoints | `executing-plans` |
| Multi-task subagent execution + 2-stage review | `subagent-driven-development` |
| Dispatch 2+ independent tasks in parallel | `dispatching-parallel-agents` |
| Test-driven development (RED-GREEN-REFACTOR) | `test-driven-development` |
| Debug systematically (4-phase root cause) | `systematic-debugging` |
| Request code review | `requesting-code-review` |
| Receive / respond to review feedback | `receiving-code-review` |
| Verify before claiming complete | `verification-before-completion` |
| Use git worktrees for isolation | `using-git-worktrees` |
| Finish dev branch (merge/PR/keep/discard) | `finishing-a-development-branch` |
| Write / edit skills following best practice | `writing-skills` |

---

## Built-in Skills (10 鈥?provided by Mavis)

These come with every Mavis Code install. Listed here for completeness.

| Skill | Purpose |
|-------|---------|
| `ai-coder` | General full-stack development assistant |
| `ai-eraser-skills` | De-AI-ify text (reduce AI-detection rate) |
| `ai-short-drama-director` | Auto-generate AI short drama from script |
| `brainstorming` | Explore intent / requirements before implementation |
| `knowledge-digest` | Convert learning material to multi-modal study aid |
| `minimax-xlsx` | Read / create / edit / analyze Excel |
| `office-document-specialist-suite` | Anthropic's Office docx/xlsx/pdf/pptx suite |
| `pptx-skill` | Read / create / edit PowerPoint |
| `prd-to-prototype` | PRD 鈫?interactive HTML/Tailwind prototype |
| `story-video-generator` | Image / text 鈫?video story |

---

## Custom Skills (11 鈥?built for the Mavis team)

### `backend-patterns-java`
- **Triggers**: java, spring, springboot, jvm, jpa
- **Purpose**: Java backend core patterns (record > class, constructor injection, exception hierarchy)
- **Must read for**: `coder` agent on any Java task
- **File**: `skills/backend-patterns-java/SKILL.md`

### `backend-patterns-python`
- **Triggers**: python, fastapi, django, async, pydantic, sqlalchemy
- **Purpose**: Python backend patterns (type hints mandatory, Pydantic validation, async)
- **File**: `skills/backend-patterns-python/SKILL.md`

### `backend-patterns-typescript`
- **Triggers**: typescript, ts, node, express, nest, fastify
- **Purpose**: TS/Node patterns (strict mode, Zod validation, async/await not .then)
- **File**: `skills/backend-patterns-typescript/SKILL.md`

### `code-reader`
- **Triggers**: read code, understand, 璇绘噦, 璋冪爺, 瑙ｉ噴浠ｇ爜
- **Purpose**: Code understanding specialist (produces Code Maps)
- **Use case**: Onboarding to unfamiliar codebase
- **File**: `skills/code-reader/SKILL.md`

### `database-patterns`
- **Triggers**: database, db, sql, postgres, mysql, migration, 绱㈠紩, 浜嬪姟, orm
- **Purpose**: DB schema / migration / query optimization / ORM patterns
- **File**: `skills/database-patterns/SKILL.md`

### `performance-analyzer`
- **Triggers**: performance, 鎬ц兘, 鎱? profile, latency, 浼樺寲, 璋冧紭
- **Purpose**: Performance analysis specialist (measure first, then optimize)
- **File**: `skills/performance-analyzer/SKILL.md`

### `plan-workflow`
- **Triggers**: /plan, 璁″垝, planning, 娴佹按绾? workflow
- **Purpose**: `/plan` command orchestration (spec-miner 鈫?planner 鈫?coder 鈫?architect + verifier 鈫?test-writer 鈫?meta-writer)
- **File**: `skills/plan-workflow/SKILL.md`

### `search-first`
- **Triggers**: search, 调研, 查文档, 找惯例, research, 引用源, source-driven
- **Purpose**: Search docs / source / conventions before coding (Karpathy principle 1) + addy `source-driven-development` — must cite sources or mark UNVERIFIED
- **File**: `skills/search-first/SKILL.md`

### `test-writer`
- **Triggers**: test, tdd, 鍗曟祴, 闆嗘垚娴嬭瘯, mock, pytest, junit, vitest
- **Purpose**: Test writing specialist (TDD-first, boundary + exception + integration)
- **File**: `skills/test-writer/SKILL.md`

### `verification-loop`
- **Triggers**: verify, test, tdd, 楠岃瘉, 寰幆, 鐩爣
- **Purpose**: Goal-driven validation loop (Karpathy principle 4)
- **File**: `skills/verification-loop/SKILL.md`

### `vibecoding-discipline`
- **Triggers**: vibecoding, 屎山, 耦合, 解耦, 架构, 模块化
- **Purpose**: 5-decoupling-practice enforcer (Vibe Coding video origin)
- **File**: `skills/vibecoding-discipline/SKILL.md`

### `grill-me` (NEW 2026-06-23)
- **Triggers**: grill, interview, 需求不清晰, 95% 置信度, 反问
- **Purpose**: Addy `interview-me` + matt `grill-me` fusion — one question at a time, until 95% confidence. spec-miner MUST load this.
- **File**: `skills/grill-me/SKILL.md`

### `context-engineering` (NEW 2026-06-23)
- **Triggers**: context, 喂信息, 上下文, 信息太多, 信息冲突
- **Purpose**: Addy `context-engineering` — feed agents the right info at the right time. 4 filter rules + 4 context types.
- **File**: `skills/context-engineering/SKILL.md`

### `observability-and-instrumentation` (NEW 2026-06-23)
- **Triggers**: observability, 监控, 告警, 埋点, log, metric, trace, 上线
- **Purpose**: Addy `observability-and-instrumentation` — structured logging + RED metrics + OpenTelemetry + symptom-based alerting. release-manager MUST check 4 items before launch.
- **File**: `skills/observability-and-instrumentation/SKILL.md`

### `project-context` (NEW 2026-06-23)
- **Triggers**: CONTEXT.md, 术语, 领域语言, ubiquitous language, DDD
- **Purpose**: Matt `CONTEXT.md` pattern — project-level domain language table. mavis loads on project start, all agents share.
- **File**: `skills/project-context/SKILL.md`

### `git-workflow-and-versioning` (NEW 2026-06-23)
- **Triggers**: git, commit, branch, merge, push, PR, conflict, worktree, gh CLI
- **Purpose**: Adapted from addy `git-workflow-and-versioning` — Trunk-based + Conventional Commits + Worktrees (multi-person) + Java/Maven pre-commit hygiene + gh CLI toolbox. Works for 1 person or many.
- **File**: `skills/git-workflow-and-versioning/SKILL.md`

### `to-issues` (NEW 2026-06-23)
- **Triggers**: to-issues, 拆issue, 拆任务, issue拆分, vertical slice, 切片, PRD拆分, 需求拆解, 任务分解, tracer bullet
- **Purpose**: Adapted from mattpocock/skills `engineering/to-issues` — split any plan / spec / PRD into independently-grabbable vertical-slice issues. Outputs to GitHub Issues / mavis team plan tasks / Jira.
- **File**: `skills/to-issues/SKILL.md`

### `implement` (NEW 2026-06-23)
- **Triggers**: implement, 实施, 落地, 实现, plan-to-code, PRD-to-code, spec-to-code, issue-to-code, TDD流程, 编码流程
- **Purpose**: Adapted from mattpocock/skills `engineering/implement` (14 lines) — expanded to full SOP: plan → TDD → typecheck → test → review → commit. Coordinates coder + test-writer + verifier + build-error-resolver.
- **File**: `skills/implement/SKILL.md`

### `obra/superpowers` 14-skill framework (NEW 2026-06-24)
- **Source**: [obra/superpowers](https://github.com/obra/superpowers) (237k stars, the de facto agentic skills framework)
- **Purpose**: Complete software development methodology — replaces `brainstorming` (mavis builtin) and `test-writer` with obra's verified versions; adds 12 more skills covering the full dev lifecycle.
- **Meta-skill**: `using-superpowers` mandates skill invocation before ANY response — fixes the "skill 不经常触发" problem.

**14 skills installed (byte-exact from obra/superpowers)**:

| Skill | Purpose | Replaces / Adds |
|-------|---------|-----------------|
| `using-superpowers` | Mandatory skill invocation at conversation start | **NEW** (meta-skill, fixes trigger problem) |
| `brainstorming` | Refine ideas through Socratic dialogue before code | **REPLACES** mavis builtin `brainstorming` |
| `writing-plans` | Break spec into bite-sized (2-5 min) tasks with TDD steps | **NEW** (complements `plan-workflow`) |
| `subagent-driven-development` | Each task = fresh subagent + 2-stage review (spec compliance → code quality) | **NEW** (validates our `mavis team plan` pattern) |
| `executing-plans` | Execute plan in separate session with checkpoints | **NEW** |
| `dispatching-parallel-agents` | Spawn multiple agents for independent tasks | **NEW** (validates our `max_concurrency: 3` pattern) |
| `test-driven-development` | Strict RED-GREEN-REFACTOR; no production code without failing test | **REPLACES** `test-writer` |
| `systematic-debugging` | 4-phase root cause investigation before proposing fixes | **NEW** (complements `silent-failure-hunter`) |
| `requesting-code-review` | Pre-review checklist; request review between tasks / before merge | **NEW** (validates our `verifier` pattern) |
| `receiving-code-review` | Technical rigor over performative agreement; verify before implementing | **NEW** (防 AI 表演性回应) |
| `using-git-worktrees` | Isolated workspace via native tools or git worktree fallback | **NEW** (complements `git-workflow-and-versioning`) |
| `finishing-a-development-branch` | Merge / PR / keep / discard structured options | **NEW** (complements `release-manager`) |
| `verification-before-completion` | Run verification command + read output before claiming success | **NEW** (complements `verification-loop`) |
| `writing-skills` | Skill creation methodology with TDD-like pressure scenarios | **NEW** (complements `create-agent`) |

**Removed**: `test-writer` (replaced by `test-driven-development` — obra's TDD is stricter)

---

## Skill 鈫?Agent Loading Map

| Agent | Skills it MUST load |
|-------|---------------------|
| `coder` | `vibecoding-discipline` + `verification-loop` + `search-first` (第三方库) + `context-engineering` + `backend-patterns-{java OR python OR ts}` + `database-patterns` (if SQL) + `api-design` (if API) |
| `verifier` | `vibecoding-discipline` + `verification-loop` + `context-engineering` |
| `architect` | `vibecoding-discipline` + `context-engineering` + `api-design` (if API) + `database-patterns` (if schema) |
| `silent-failure-hunter` | `vibecoding-discipline` (composition > inheritance for safety) + `observability-and-instrumentation` (看是否有 silent failure 埋点) |
| `code-simplifier` | `vibecoding-discipline` + `verification-loop` |
| `test-writer` (skill, not agent) | `vibecoding-discipline` + `verification-loop` |
| `meta-writer` | `vibecoding-discipline` (single-writer iron rule) + `context-engineering` (ADR 格式) |
| `auditor` | `vibecoding-discipline` + `api-design` (if API) + `database-patterns` (if SQL) + `observability-and-instrumentation` |
| `release-manager` | `vibecoding-discipline` + `verification-loop` + `observability-and-instrumentation` (4 项 checklist) |
| `spec-miner` | `grill-me` (必 load) + `vibecoding-discipline` + `project-context` (如果项目有 CONTEXT.md) |
| `planner` | `vibecoding-discipline` + `context-engineering` |
| `mavis` (orchestrator) | `vibecoding-discipline` + `context-engineering` + `project-context` (启动时 load) |
| `coder` (when implementing from PRD/issues) | `implement` (6-step SOP: plan → TDD → typecheck → test → review → commit) + `to-issues` (if slicing a big spec) |

See individual `agents/<name>/agent.md` for the explicit loading instructions.

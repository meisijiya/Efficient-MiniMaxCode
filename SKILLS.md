# Skill Index (21)

> This index is auto-generated from the actual `SKILL.md` content. Use it as a quick reference for "which skill should I load for XX task".

## Quick Reference

| Task | Skill |
|------|-------|
| Write Java / Spring Boot code | `backend-patterns-java` |
| Write TypeScript / Node code | `backend-patterns-typescript` |
| Write Python / FastAPI / Django | `backend-patterns-python` |
| Design / review REST API | `api-design` (work in progress) |
| Design / review SQL schema | `database-patterns` |
| Write / refactor React component | `frontend-patterns` (work in progress) |
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

---

## Built-in Skills (10 — provided by Mavis)

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
| `prd-to-prototype` | PRD → interactive HTML/Tailwind prototype |
| `story-video-generator` | Image / text → video story |

---

## Custom Skills (11 — built for the Mavis team)

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
- **Triggers**: read code, understand, 读懂, 调研, 解释代码
- **Purpose**: Code understanding specialist (produces Code Maps)
- **Use case**: Onboarding to unfamiliar codebase
- **File**: `skills/code-reader/SKILL.md`

### `database-patterns`
- **Triggers**: database, db, sql, postgres, mysql, migration, 索引, 事务, orm
- **Purpose**: DB schema / migration / query optimization / ORM patterns
- **File**: `skills/database-patterns/SKILL.md`

### `performance-analyzer`
- **Triggers**: performance, 性能, 慢, profile, latency, 优化, 调优
- **Purpose**: Performance analysis specialist (measure first, then optimize)
- **File**: `skills/performance-analyzer/SKILL.md`

### `plan-workflow`
- **Triggers**: /plan, 计划, planning, 流水线, workflow
- **Purpose**: `/plan` command orchestration (spec-miner → planner → coder → architect + verifier → test-writer → meta-writer)
- **File**: `skills/plan-workflow/SKILL.md`

### `search-first`
- **Triggers**: search, 调研, 查文档, 找惯例, research
- **Purpose**: Search docs / source / conventions before coding (Karpathy principle 1)
- **File**: `skills/search-first/SKILL.md`

### `test-writer`
- **Triggers**: test, tdd, 单测, 集成测试, mock, pytest, junit, vitest
- **Purpose**: Test writing specialist (TDD-first, boundary + exception + integration)
- **File**: `skills/test-writer/SKILL.md`

### `verification-loop`
- **Triggers**: verify, test, tdd, 验证, 循环, 目标
- **Purpose**: Goal-driven validation loop (Karpathy principle 4)
- **File**: `skills/verification-loop/SKILL.md`

### `vibecoding-discipline`
- **Triggers**: vibecoding, 屎山, 耦合, 解耦, 架构, 模块化
- **Purpose**: 5-decoupling-practice enforcer (Vibe Coding video origin)
- **File**: `skills/vibecoding-discipline/SKILL.md`

---

## Skills in Progress (2)

| Skill | Status | Plan |
|-------|--------|------|
| `api-design` | empty (placeholder only) | Fill in REST status codes / pagination / auth patterns |
| `frontend-patterns` | empty (placeholder only) | Fill in React 19 / Next 15 patterns |

These directories exist but contain no `SKILL.md` yet. They are excluded from the index above.

---

## Skill ↔ Agent Loading Map

| Agent | Skills it MUST load |
|-------|---------------------|
| `coder` | `vibecoding-discipline` + `verification-loop` + `backend-patterns-{java OR python OR ts}` + `database-patterns` (if SQL) + `api-design` (if API) |
| `verifier` | `vibecoding-discipline` + `verification-loop` |
| `architect` | `vibecoding-discipline` + `api-design` (if API) + `database-patterns` (if schema) |
| `silent-failure-hunter` | `vibecoding-discipline` (composition > inheritance for safety) |
| `code-simplifier` | `vibecoding-discipline` + `verification-loop` |
| `test-writer` (skill, not agent) | `vibecoding-discipline` + `verification-loop` |
| `meta-writer` | `vibecoding-discipline` (single-writer iron rule) |
| `auditor` | `vibecoding-discipline` + `api-design` (if API) + `database-patterns` (if SQL) |
| `release-manager` | `vibecoding-discipline` + `verification-loop` |

See individual `agents/<name>/agent.md` for the explicit loading instructions.

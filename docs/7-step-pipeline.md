# 7-Step Pipeline (`/plan` workflow)

> This document details the standard 7-step pipeline that all complex Mavis Code tasks should follow. Invoked via the `/plan` command (or automatically when the user says something like "/plan add SSO login").

---

## Overview

```
Think → Plan → Build → Review → Test → Ship → Reflect
```

Each step has a **specific agent**, a **specific output**, and a **specific success criterion**.

---

## Step 1: Think — `spec-miner`

**Goal**: Turn a vague user request into a structured spec.

**Inputs**:
- Vague user message (e.g., "I want to add SSO login")

**Outputs**:
- Spec document with:
  - User-facing description (1 paragraph)
  - Acceptance criteria (testable)
  - Non-goals (what we explicitly won't do)
  - Edge cases / open questions
  - Estimated complexity (small / medium / large)

**Trigger**: "做 XX" / "加功能" with unclear scope

**Stop condition**: User confirms the spec OR spec-miner surfaces ambiguity and waits for clarification

**Common failure mode**: spec-miner jumps to implementation without surfacing ambiguity. Rule: **always produce the spec doc first**.

---

## Step 2: Plan — `planner`

**Goal**: Turn the spec into an executable implementation plan.

**Inputs**:
- Spec document from step 1

**Outputs**:
- Multi-phase implementation plan:
  - Phase 1: Data layer (entities + migration + repository)
  - Phase 2: API layer (controller + service + DTOs)
  - Phase 3: UI layer (if applicable)
  - Phase 4: Tests + observability
- Each phase is **independently mergeable** (one PR per phase)
- Each phase has its own verification (build / test / smoke)

**Trigger**: After spec-miner finishes; user confirms the spec

**Stop condition**: User confirms the plan OR planner surfaces architectural decisions and waits for user input

**Common failure mode**: planner produces a single big-bang plan instead of phased plan. Rule: **always split into 2+ phases unless the task is trivial**.

---

## Step 3: Build — `coder`

**Goal**: Implement the plan, one phase at a time.

**Inputs**:
- Implementation plan from step 2 (the current phase only)

**Outputs**:
- Source code changes (diff)
- Commit(s) — one commit per logical change
- Build verification: `mvn -DskipTests package` / `npm run build` / `pytest` (depending on stack)
- Test verification: `./mvnw test` / `npm test` / `pytest` (existing tests must pass)

**Trigger**: User confirms the plan

**Stop condition**: Build green + all existing tests pass + new tests written for the change

**Common failure mode**: coder makes one big commit. Rule: **one logical change per commit**. If you find yourself writing "and also X" in the commit message, split the commit.

---

## Step 4: Review — `architect` + `verifier` (default 2 layers)

**Goal**: Catch issues before they get into the codebase.

**Layer 1: `architect`**
- Focus: Module boundaries, interfaces, data flow, state ownership, dependency direction
- Does NOT look at: code details, error handling, performance
- Output: Architectural review report (CRITICAL / HIGH / MEDIUM findings)

**Layer 2: `verifier`**
- Focus: Code correctness, boundary cases, performance, security basics
- Uses `vibecoding-discipline` 5-practice checklist
- Output: Code review report (verdict: APPROVE / WARNING / BLOCK)

**Upgrade to 3 layers** (add `auditor`): Any of:
- Payment / money / financial
- PII / GDPR / CCPA / compliance
- New dependency / new middleware
- Auth / permission / OAuth / JWT
- Database schema major change

**Trigger**: After each phase of build (not just at the end)

**Stop condition**: Both layers pass (verifier gives APPROVE / WARNING; architect gives 0 CRITICAL findings)

**Common failure mode**: only running review at the end. Rule: **review per phase**, otherwise late defects are hard to isolate.

---

## Step 5: Test — `test-writer`

**Goal**: Ensure the change is actually verified by tests, not just "looks right".

**Inputs**:
- Coder's diff from step 3
- Verifier's review from step 4

**Outputs**:
- New unit tests (covering the change)
- Integration tests (if the change crosses module boundaries)
- E2E tests (if user-visible)
- Coverage report (target ≥ 80% on touched files)
- Test verification: all new + existing tests pass

**Trigger**: After review passes

**Stop condition**: All tests pass + coverage target met

**Common failure mode**: writing tests after the fact that just exercise happy path. Rule: **TDD-first** — write the failing test first, then the implementation.

---

## Step 6: Ship — `release-manager`

**Goal**: Get the change from "code complete" to "user available".

**7 sub-steps**:
1. **Pre-flight check**: CI green, no known P0/P1, DB migration ready, backup strategy in place
2. **Changelog**: Conventional commits → organized release notes
3. **Version + tag**: SemVer (MAJOR.MINOR.PATCH) — only if user wants a tagged release
4. **Commit + push**: Merge to main, push tag (no `--force`)
5. **Deploy**: Trigger user-defined deploy script
6. **Post-deployment verify**: Health check + key endpoints + monitoring
7. **Notify + document**: Notify team, update README, close milestones

**Trigger**: User says "上线" / "发布" / "打 tag" / completes a `release/vX.Y` branch

**Stop condition**: Post-deployment verify all green

**Common failure mode**: skipping pre-flight check. Rule: **any one check fails → BLOCK**. Don't push and pray.

---

## Step 7: Reflect — `meta-writer`

**Goal**: Capture the decision / lesson for future agents.

**11 metadata types** (single-writer iron rule):
1. **ADR** (Architecture Decision Record)
2. **DECISIONS** (project-level decision log)
3. **KNOWLEDGE** (domain knowledge)
4. **INSTINCTS** (cross-project rules)
5. **STYLE_GUIDE**
6. **CHANGELOG**
7. **MIGRATION_GUIDE**
8. **RUNBOOK**
9. **POST_MORTEM**
10. **API_CONTRACT**
11. **DATA_DICTIONARY**

**Trigger**: After a non-trivial decision is made (architecture, library choice, pattern)

**Stop condition**: Metadata file written to the right place with proper format

**Common failure mode**: skipping reflection because "we already finished". Rule: **reflection IS part of finishing**, not separate.

---

## When to Skip Steps

| Step | When to skip |
|------|--------------|
| Think | User provides a fully-specified spec (with acceptance criteria) |
| Plan | User says "just do it" — coder can implement directly |
| Build | (never skip — always the core) |
| Review | (never skip for non-trivial changes) |
| Test | (never skip — minimum smoke test) |
| Ship | Local dev / experiment / sandbox |
| Reflect | "Just experimenting" (but document if decision is reusable) |

**Default**: All 7 steps. Skip only with explicit user confirmation.

---

## Why Not Just One Agent Doing All 7?

Because:
- **Context budget**: each agent has its own context, so 7 short-context agents > 1 long-context agent
- **Specialization**: spec-miner doesn't need to know how to write code; coder doesn't need to know how to write metadata
- **Verifiable handoffs**: each step has a clear input/output, easy to debug
- **Parallelism**: in future, multiple steps can run concurrently (e.g., review while tests are being written)

The cost: 7× orchestration overhead. The benefit: each step is fast + correct + auditable.

---

## Failure Recovery

If a step fails, the pipeline doesn't crash — it **surfaces the failure** and asks the user:

| Failure | Recovery |
|---------|----------|
| spec-miner can't decide | Ask user 1-2 clarifying questions |
| planner can't design | Split the task into 2+ smaller plannings |
| coder can't implement | Maybe architect first (architecture ambiguity, not implementation difficulty) |
| architect rejects | Re-plan, not re-implement |
| verifier rejects | Apply verifier's findings, re-submit (don't re-architect) |
| test-writer can't write | Code is probably untestable (coupling / global state) — back to architect |
| release-manager fails | Probably CI/CR/merge conflict — escalate to user |

See `mavis/agent.md` for the full decision tree.

---
name: git-workflow-and-versioning
description: Git workflow conventions. Use when making any code change, committing, branching, resolving conflicts, or running gh CLI for issues/PRs. Adapted from addyosmani/agent-skills with Java/Maven + gh CLI + multi-person additions.
---

# Git Workflow and Versioning

## Overview

Git is your safety net. With AI agents generating code at high speed, **disciplined version control** is the mechanism that keeps changes manageable, reviewable, and reversible. Trunk-based + Conventional Commits + Worktrees = works for 1 person or many.

## When to Use

**Always.** Every code change flows through git. Plus: creating issues, opening PRs, triggering workflows via `gh` CLI.

## 7 Core Principles

### 1. Trunk-Based Development (Recommended)

Keep `main` always deployable. Work in short-lived feature branches that merge back within 1-3 days.

```
main ──●──●──●──●──●──●──●──●──●──  (always deployable)
        ╲      ╱  ╲    ╱
         ●──●─╱    ●──╱    ← feature branches (1-3 days, then merge)
```

- **Dev branches are costs.** Every day a branch lives, it accumulates merge risk.
- **Release branches are acceptable** when stabilizing a release while main moves.
- **Feature flags > long branches** for incomplete features.

### 2. Commit Early, Commit Often

```
Work pattern:
  Implement slice → Test → Verify → Commit → Next slice

Not this:
  Implement everything → Hope it works → Giant commit
```

If the next change breaks, revert to last known-good instantly.

### 3. Atomic Commits

Each commit does **one logical thing**:

```bash
# Good
git log --oneline
a1b2c3d feat(api): add /orders POST endpoint with validation
d4e5f6g feat(web): add order creation form component
h7i8j9k refactor(api): extract Zod schemas to shared module  # 假设 TS / Java 改 Bean Validation
m1n2o3p test(api): add order creation integration tests

# Bad
x1y2z3a feat: add order feature, fix sidebar, update deps, refactor utils
```

### 4. Conventional Commits (Descriptive)

Commit messages explain **why**, not what.

**Format**:
```
<type>(<scope>): <short description>  ← 50 chars
                                         ← blank line
<body explaining why, not what>      ← wrap at 72
                                         ← blank line
<footer>                              ← BREAKING CHANGE / refs #issue
```

**Types**:
| type | 用途 |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change, neither bug nor feature |
| `test` | Tests added/updated |
| `docs` | Documentation only |
| `chore` | Tooling, deps, config (no production change) |
| `perf` | Performance improvement |
| `style` | Code style (no logic change) |
| `build` | Build system / deps |
| `ci` | CI config |
| `revert` | Revert a previous commit |

**Scope** (optional): `feat(api): ...` / `fix(web): ...` / `docs(readme): ...`

**Examples** (Java / Spring Boot):
```bash
# Good — explains why
git commit -m "feat(order): add inventory check before order confirmation

Prevents overselling. Uses pessimistic lock on Product.stock
with @Version for optimistic retry. Throws InsufficientStockException
mapped to 409 by GlobalExceptionHandler.

Refs #123"

# Bad — describes the diff
git commit -m "update OrderService"
```

### 5. Keep Concerns Separate

```bash
# Good
git commit -m "refactor: extract validation to Bean Validator"
git commit -m "feat: add email field to User entity"

# Bad
git commit -m "refactor validation and add email field"
```

A refactor and a feature are **two different changes** — submit separately. Easier to review, revert, understand in history.

### 6. Size Your Changes

```
~100 lines   → Easy to review, easy to revert
~300 lines   → Acceptable for single logical change
~1000 lines  → Split into smaller changes (MUST)
```

> 1000 lines = "I didn't bother to plan". Reviewer can't catch issues, you can't revert cleanly, CI will be slow.

### 7. Worktrees (Parallel Work)

For **1 person + multiple agents** or **multi-person parallel work**, use `git worktree`:

```bash
# Create worktree for parallel branch
git worktree add ../project-feature-a feature/order-api
git worktree add ../project-feature-b feature/order-web

# Each worktree is its own directory + branch
ls ../
  project/              ← main branch
  project-feature-a/    ← order-api branch (worktree)
  project-feature-b/    ← order-web branch (worktree)

# Cleanup after merge
git worktree remove ../project-feature-a
```

**Benefits**:
- Multiple branches active without `git switch` (which loses uncommitted state)
- Each worktree = its own IDE window = parallel coding
- Failed experiments → just delete the worktree, nothing lost

## Pre-Commit Hygiene (Java / Spring Boot)

```bash
# 1. What's about to be committed?
git diff --staged

# 2. Secret scan (MUST before every commit)
git diff --staged | grep -iE "password|secret|api[_-]?key|token|private[_-]?key" && echo "❌ SECRET FOUND" && exit 1

# 3. Run tests
mvn test                    # Spring Boot
# OR ./gradlew test          # Gradle

# 4. Lint + format
mvn spotless:apply          # OR google-java-format
mvn checkstyle:check

# 5. Type / build check
mvn -DskipTests package

# 6. No debug / println left
git diff --staged | grep -E "System\.out|printStackTrace|TODO|FIXME"  # review each match
```

**Automate with pre-commit hook** (recommended for every project):
```bash
# .git/hooks/pre-commit (chmod +x)
#!/bin/sh
set -e
git diff --staged | grep -iE "password|secret|api[_-]?key|token" && {
  echo "❌ Secret detected in staged diff"; exit 1
}
mvn -DskipTests -q clean package
```

## gh CLI Toolbox (你的 PAT 已配)

```bash
# Issue 管理
gh issue list --limit 10
gh issue create --title "feat: add SSO login" --body "..." --label "enhancement"
gh issue close 123 --comment "fixed in #456"

# PR 管理
gh pr list --state open
gh pr create --title "feat: add order API" --body "..." --base main --head feature/order
gh pr merge 456 --squash --delete-branch
gh pr checks 456               # 看 CI 状态

# Workflow 触发
gh workflow run build.yml
gh run list --limit 5
gh run watch 12345             # 实时看 CI

# Release
gh release create v1.0.0 --generate-notes
gh release list
```

**协作约定** (1 人 → 多人时启用):
- **Issue label**：`bug` / `enhancement` / `docs` / `chore` / `question`
- **PR review**：>= 1 approval（1 人时跳过，多人时强制）
- **Branch protection**（多人时 GitHub 设置）：require PR + 1 approval + CI pass

## Multi-Person PR 描述模板

```markdown
## What
[1-2 句话讲做了什么]

## Why
[为什么做 / 解决什么问题 / 关联 issue #N]

## How
[关键实现点 / 用了什么库 / 改了什么接口]

## Testing
- [ ] Unit tests added
- [ ] Integration tests added
- [ ] Manual testing done
- [ ] Performance impact (if relevant)

## Risks
[潜在风险 / 回滚方案 / 需要 reviewer 关注]

## Screenshots
[UI 改动必填]

Refs #123
```

## Common Rationalizations (防借口)

| 借口 | 反驳 |
|------|------|
| "I'll commit when feature is done" | 1 个大 commit = 不可 review / 不可 revert / 不可 debug |
| "Message doesn't matter" | Message 是**文档**。未来你 + agent 都需要 |
| "I'll squash later" | Squash 抹掉开发过程。从一开始就 atomic |
| "Branches add overhead" | **短**分支 = 0 开销。**长**分支才是问题（1-3 天内合） |
| "I'll split later" | 大 change 难 review / 难部署 / 难 revert。**先拆再发** |
| ".gitignore not needed" | 直到 `.env` 含生产 secret 被 commit 才需要。**立刻**配 |
| "I don't need pre-commit hooks" | secret 漏 1 次 = 整个项目暴露 |

## Red Flags

- 大 uncommitted changes 累积
- Commit message = `fix` / `update` / `misc`
- Format 改动 + 行为改动混在 1 个 commit
- 没 `.gitignore` / `.env` 在 repo 里
- 提交了 `target/` / `node_modules/` / `.class` / `.jar`
- 长分支偏离 main 几周
- `git push --force` 到 main
- 没 secret scan / pre-commit hook

## Verification (每次 commit 前)

- [ ] Commit 做 1 件事
- [ ] Message 解释 why + 用 conventional format
- [ ] 测试通过
- [ ] 无 secret
- [ ] 无 format-only 混行为
- [ ] `.gitignore` 覆盖标准排除
- [ ] **多人时** PR 有 reviewer / CI pass

## Anti-patterns 速查（实战避坑）

- ❌ `git add .`（会加不该加的，先 `git add <file>`）
- ❌ `git commit -m "update"`（看 commit 历史无法 review）
- ❌ `git push --force` 到 main（毁团队工作）
- ❌ `git commit --amend` 改 public commit（改历史 = 队友 pull 报错）
- ❌ `git reset --hard` 不先 `git status`（丢 uncommitted 工作）

---

**怎么算"在工作"**：commit 历史像**清晰故事**（每条 commit 一句话讲清）、PR diff < 300 行、CI 永远绿、pre-commit 挡住 secret、worktree 让并行不冲突。

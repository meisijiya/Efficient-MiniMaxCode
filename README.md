# Efficient-MiniMaxCode

> A curated collection of **13 specialized agents** and **43 production-ready skills** for [Mavis Code](https://github.com/) — built to help a single developer ship like a full engineering team.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Mavis Agents](https://img.shields.io/badge/agents-13-blue)]() [![Skills](https://img.shields.io/badge/skills-43-green)]()

---

## What's Inside

This repository is a **portable, version-controlled backup** of a Mavis Code agent/skill configuration. Drop the contents into your `~/.mavis/` directory and the agents/skills are immediately available in your local Mavis Code session.

### 13 Agents (Mavis Code compatible)

| Category | Agent | Role |
|----------|-------|------|
| **Orchestrator** | `mavis` | Root orchestrator — 7-step pipeline + on-demand delegation + routing + decision tree |
| **Programming** | `coder` | Hands-on software engineer (Spring Boot / TS / Python priority) |
| **Architectural Review** | `architect` | Module boundaries / interfaces / data flow / state ownership / dependency direction |
| **Code Review** | `verifier` | Adversarial verification (4-layer confidence gate) |
| **Silent Failure** | `silent-failure-hunter` | Empty catches / swallowed errors / fire-and-forget |
| **Over-engineering** | `code-simplifier` | Trim 200-line code to 50 — only removes, never adds |
| **Spec Mining** | `spec-miner` | Vague requirement → structured spec (with non-goals + acceptance criteria) |
| **Planning** | `planner` | Strategic plan (architecture + product spec + executable plan) |
| **Build Error** | `build-error-resolver` | Targeted build / lint / test failure fix |
| **Metadata** | `meta-writer` | 11-type project metadata single-writer (ADR / DECISIONS / KNOWLEDGE) |
| **Audit** | `auditor` | Compliance / security / dependency audit (重大决策时启用) |
| **Release** | `release-manager` | commit / changelog / tag / deploy check / rollback |
| **Fallback** | `general` | Generic worker (routes to specialists when needed) |

### 43 Skills (Mavis Code compatible)

**Built-in (10)** — provided by Mavis:
`ai-coder` · `ai-eraser-skills` · `ai-short-drama-director` · `brainstorming` · `knowledge-digest` · `minimax-xlsx` · `office-document-specialist-suite` · `pptx-skill` · `prd-to-prototype` · `story-video-generator`

**Custom (21)** — built for the Mavis team:

**Backend / Frontend / DB / API (6)**:
`backend-patterns-java` · `backend-patterns-python` · `backend-patterns-typescript` · `database-patterns` · `frontend-patterns` · `api-design`

**Code reading / review / discipline (5)**:
`code-reader` · `performance-analyzer` · `vibecoding-discipline` (5-decoupling-practice) · `grill-me` (需求深挖 — addy + matt fusion) · `context-engineering` · `observability-and-instrumentation` · `project-context` · `git-workflow-and-versioning`

**Workflow / planning / delegation (4)**:
`plan-workflow` (`/plan` command) · `search-first` (think-before-coding) · `verification-loop` (goal-driven validation) · `to-issues` (vertical-slice issue splitter, from mattpocock/skills) · `implement` (PRD → code 6-step SOP, from mattpocock/skills)

**From [obra/superpowers](https://github.com/obra/superpowers) (14 skills, 237k stars)** — installed byte-exact, replaces `test-writer` + mavis builtin `brainstorming`:
`using-superpowers` (meta-skill, mandatory trigger) · `brainstorming` · `writing-plans` · `executing-plans` · `subagent-driven-development` · `dispatching-parallel-agents` · `test-driven-development` · `systematic-debugging` · `requesting-code-review` · `receiving-code-review` · `using-git-worktrees` · `finishing-a-development-branch` · `verification-before-completion` · `writing-skills`

See [SKILLS.md](SKILLS.md) for the full list with trigger keywords.

---

## On-Demand Delegation (NEW)

The orchestrator (`mavis`) follows **on-demand delegation**: detail work is spawned to a sub-agent via `mavis team plan` so the main session stays focused on decisions, not commands. A team plan has independent verification (`verifier`) and a final gate (`verify-as-task`).

**When to delegate** (any of):
- Detail is more than 1-2 tool calls
- Multi-module / multi-file work
- Need to read primary evidence (file system / daemon state / repo diff)
- Need mechanical copy / compare / byte-exact verification

**Decision shorthand**: "Will I run more than 3 tool calls in detail? → spawn a worker."

**Built-in guard rails**:
- `max_consecutive_failures: 2` — abort after 2 consecutive task failures
- `verifier` is the default verifier; `auditor` only on重大决策 (money / PII / compliance)
- Sub-session reports back via `mavis communication send` — no token-burning ack-ping-pong

---

## How to Use

### Option A — One-line install (recommended)

**Windows (PowerShell)**:
```powershell
git clone https://github.com/meisijiya/Efficient-MiniMaxCode.git
cd Efficient-MiniMaxCode
.\install.ps1
.\verify.ps1
```

**macOS / Linux (bash)**:
```bash
git clone https://github.com/meisijiya/Efficient-MiniMaxCode.git
cd Efficient-MiniMaxCode
chmod +x install.sh verify.sh uninstall.sh
./install.sh
./verify.sh
```

The installer only copies **user-controlled files** (`agent.md` and `SKILL.md`) — daemon-generated files are skipped. See [docs/INSTALLATION.md](docs/INSTALLATION.md) for the full file map.

### Option B — Cherry-pick

Don't need all 13 agents? Copy only the ones you want:

```bash
# Just the architectural review agent
mkdir -p ~/.mavis/agents/architect
cp agents/architect/agent.md ~/.mavis/agents/architect/

# Just the testing skill
mkdir -p ~/.mavis/skills/test-writer
cp skills/test-writer/SKILL.md ~/.mavis/skills/test-writer/
```

### Option C — Use as a reference

Read `agents/<name>/agent.md` to understand the role, then write your own prompt inspired by it.

### Updating

```bash
cd Efficient-MiniMaxCode
git pull
./install.sh        # or .\install.ps1
./verify.sh         # confirms install is up to date
```

### Uninstalling

```bash
./uninstall.sh      # moves files to ~/.mavis/.efficient-backup-<timestamp>/
# restore from backup if needed
```

---

## Design Philosophy

This collection is built on **three core principles** drawn from [Karpathy's LLM coding observations](https://x.com/karpathy) and the [ohMeisijiyaCode](https://github.com/meisijiya/ohMeisijiyaCode) harness engineering tradition:

1. **Architecture before implementation** — A senior engineer defines boundaries, AI fills in modules. "Complexity grows quadratically without architectural discipline."
2. **5-decoupling practice** (Vibe Coding video) — Interface separation / Single responsibility / Composition over inheritance / Incremental delivery / Pure functions first.
3. **2-3 layer review by default** — `architect + verifier` for most tasks, add `auditor` for money / PII / compliance scenarios. Don't blindly do 4 layers.
4. **On-demand delegation** — The orchestrator spawns detail work to sub-agents and reads deliverables (not full audit trails). Main session stays focused on decisions.

See [docs/DESIGN.md](docs/DESIGN.md) for the full design rationale.

---

## Repository Structure

```
Efficient-MiniMaxCode/
├── README.md                    # This file
├── LICENSE                      # MIT
├── .gitignore
├── AGENTS.md                    # Agent index (13 entries with triggers)
├── SKILLS.md                    # Skill index (31 entries with triggers)
├── install.ps1 / install.sh     # One-command installer (Windows / Unix)
├── uninstall.ps1 / uninstall.sh # One-command uninstaller (with backup)
├── verify.ps1 / verify.sh       # Verify installation
├── docs/
│   ├── INSTALLATION.md          # ⭐ Where every file goes & how Mavis reads it
│   ├── DESIGN.md                # Design rationale
│   └── 7-step-pipeline.md       # /plan workflow details
├── agents/                      # 13 agents — only agent.md per agent
│   ├── architect/agent.md
│   ├── auditor/agent.md
│   ├── build-error-resolver/agent.md
│   ├── code-simplifier/agent.md
│   ├── coder/agent.md
│   ├── general/agent.md
│   ├── mavis/agent.md
│   ├── meta-writer/agent.md
│   ├── planner/agent.md
│   ├── release-manager/agent.md
│   ├── silent-failure-hunter/agent.md
│   ├── spec-miner/agent.md
│   └── verifier/agent.md
└── skills/                      # 31 skills — only SKILL.md per skill
    ├── api-design/SKILL.md
    ├── backend-patterns-java/SKILL.md
    ├── backend-patterns-python/SKILL.md
    ├── backend-patterns-typescript/SKILL.md
    ├── code-reader/SKILL.md
    ├── context-engineering/SKILL.md
    ├── database-patterns/SKILL.md
    ├── frontend-patterns/SKILL.md
    ├── git-workflow-and-versioning/SKILL.md
    ├── grill-me/SKILL.md
    ├── implement/SKILL.md
    ├── observability-and-instrumentation/SKILL.md
    ├── performance-analyzer/SKILL.md
    ├── plan-workflow/SKILL.md
    ├── project-context/SKILL.md
    ├── search-first/SKILL.md
    ├── test-writer/SKILL.md
    ├── to-issues/SKILL.md
    ├── verification-loop/SKILL.md
    ├── vibecoding-discipline/SKILL.md
    └── ... (11 more built-in)
```

**Only `agent.md` and `SKILL.md` are tracked.** Daemon-generated files (`config.yaml`, `PERSONA.md`, `.builtin-prompt-layout-v2`, `_meta.json`) are NOT in this repo — they're machine-specific and would cause merge conflicts. The installer skips them. See [docs/INSTALLATION.md](docs/INSTALLATION.md) for the full rationale.

---

## Known Mavis Quirks (worked around)

- **`mavis agent update --system-prompt` silent drop** — Any size update may silently revert `agent.md` to a 39-byte stub. **Never use it.** Always use Edit / Write tools to modify `agent.md` directly. The daemon reads the file on next agent instantiation.
- **`mavis restart` requires the desktop app** — The daemon is owned by MiniMax Code.exe; CLI `mavis restart` is refused. To refresh skill metadata cache (e.g., after editing a `SKILL.md` frontmatter), close and reopen MiniMax Code.exe.
- **daemon 8000-byte soft cap** — `agent.md` files > 8000 bytes may trigger silent drop on daemon restart. Currently 2 agents exceed (`mavis` 10090 / `auditor` 8397) and 1 is close (`verifier` 7893). These are not actively dropping (daemon cache still includes full content), but future daemon upgrades are a risk.

---

## Roadmap

- [x] Complete `api-design` skill (REST status codes / pagination / auth patterns) — **done 2026-06-23**
- [x] Complete `frontend-patterns` skill (React 19 / Next 15) — **done 2026-06-23**
- [x] Add 4 ESSENTIAL skill patterns from addy/matt fusion (`grill-me` / `context-engineering` / `observability-and-instrumentation` / `project-context`) — **done 2026-06-23**
- [x] Add `git-workflow-and-versioning` (full version, multi-person ready) — **done 2026-06-23**
- [x] Add on-demand delegation core rule to mavis orchestrator — **done 2026-06-23**
- [x] Add `to-issues` + `implement` from mattpocock/skills — **done 2026-06-23**
- [x] Fix P0 architect drift (live `~/.mavis/agents/architect/agent.md` 39B stub → 8668B repo content) — **done 2026-06-23**
- [x] Adopt **obra/superpowers** 14-skill framework (237k stars) — **done 2026-06-24** (replaces `test-writer` + mavis builtin `brainstorming`; adds 12 more; `using-superpowers` meta-skill fixes "skill 不经常触发" problem)
- [x] Fix P1: deploy planner + 3 missing skills + 7 frontmatter fixes — **done 2026-06-23** (daemon cache refresh pending MiniMax Code.exe restart)
- [ ] (DEFERRED) `silent drop` 8000B threshold: **unconfirmed risk**, no current truncation observed. Don't preemptively split agents — wait for actual evidence. If daemon ever drops user overlay, address then.
- [ ] Multi-language README (English, 日本語)

---

## Contributing

1. Fork this repository
2. Create a branch: `git checkout -b feature/add-my-skill`
3. Add your agent/skill under the right directory
4. Update `AGENTS.md` / `SKILLS.md` index
5. Submit a PR with a clear rationale

**Quality bar**:
- Every `agent.md` must include: role boundary (what you do / don't do), trigger scenario, 4-principle checklist, validation closure
- Every `SKILL.md` must include: trigger keywords (for Mavis to auto-load), core knowledge, common pitfalls
- Don't add a new agent if an existing one already covers the role — extend the existing one instead
- Don't add a new skill if it overlaps with an existing one — extend the existing one instead

---

## Acknowledgements

- [Karpathy](https://x.com/karpathy) — LLM coding 4-principle constitution
- [ohMeisijiyaCode](https://github.com/meisijiya/ohMeisijiyaCode) — 7-step pipeline + 4-layer review + 11-type metadata single-writer
- [affaan-m/ECC](https://github.com/affaan-m/ECC) — Agent harness OS design
- [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) — 4-principle origin
- [Vibe Coding video (BV1v9ER68EJE)](https://www.bilibili.com) — 5-decoupling practice origin
- [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) — `git-workflow-and-versioning` + `context-engineering` + `observability-and-instrumentation` + `interview-me`
- [mattpocock/skills](https://github.com/mattpocock/skills) — `to-issues` + `implement` + `grill-me` (融合到 spec-miner)
- [obra/superpowers](https://github.com/obra/superpowers) (237k stars) — 14-skill complete dev methodology, byte-exact adopted

---

## License

[MIT](LICENSE) — Copyright (c) 2026 meisijiya
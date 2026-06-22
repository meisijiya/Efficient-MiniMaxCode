# Efficient-MiniMaxCode

> A curated collection of **13 specialized agents** and **21 production-ready skills** for [Mavis Code](https://github.com/) — built to help a single developer ship like a full engineering team.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Mavis Agents](https://img.shields.io/badge/agents-13-blue)]() [![Skills](https://img.shields.io/badge/skills-21-green)]()

---

## What's Inside

This repository is a **portable, version-controlled backup** of a Mavis Code agent/skill configuration. Drop the contents into your `~/.mavis/` directory and the agents/skills are immediately available in your local Mavis Code session.

### 13 Agents (Mavis Code compatible)

| Category | Agent | Role |
|----------|-------|------|
| **Orchestrator** | `mavis` | Root orchestrator — 7-step pipeline + routing + decision tree |
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

### 21 Skills (Mavis Code compatible)

**Built-in (10)** — provided by Mavis:
`ai-coder` · `ai-eraser-skills` · `ai-short-drama-director` · `brainstorming` · `knowledge-digest` · `minimax-xlsx` · `office-document-specialist-suite` · `pptx-skill` · `prd-to-prototype` · `story-video-generator`

**Custom (11)** — built for the Mavis team:
- **Backend patterns (3)**: `backend-patterns-java` · `backend-patterns-python` · `backend-patterns-typescript`
- **Frontend / DB / API (3)**: `database-patterns` · `frontend-patterns` (v1) · `api-design` (v1)
- **Code reading / review (4)**: `code-reader` · `test-writer` · `performance-analyzer` · `vibecoding-discipline` (5-decoupling-practice)
- **Workflow (2)**: `plan-workflow` (`/plan` command) · `search-first` (think-before-coding) · `verification-loop` (goal-driven validation)

See [SKILLS.md](SKILLS.md) for the full list with trigger keywords.

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

See [docs/DESIGN.md](docs/DESIGN.md) for the full design rationale.

---

## Repository Structure

```
Efficient-MiniMaxCode/
├── README.md                    # This file
├── LICENSE                      # MIT
├── .gitignore
├── AGENTS.md                    # Agent index (13 entries with triggers)
├── SKILLS.md                    # Skill index (21 entries with triggers)
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
└── skills/                      # 23 skills — only SKILL.md per skill
    ├── api-design/SKILL.md
    ├── backend-patterns-java/SKILL.md
    ├── backend-patterns-python/SKILL.md
    ├── backend-patterns-typescript/SKILL.md
    ├── code-reader/SKILL.md
    ├── database-patterns/SKILL.md
    ├── frontend-patterns/SKILL.md
    ├── performance-analyzer/SKILL.md
    ├── plan-workflow/SKILL.md
    ├── search-first/SKILL.md
    ├── test-writer/SKILL.md
    ├── verification-loop/SKILL.md
    ├── vibecoding-discipline/SKILL.md
    └── ... (10 more built-in)
```

**Only `agent.md` and `SKILL.md` are tracked.** Daemon-generated files (`config.yaml`, `PERSONA.md`, `.builtin-prompt-layout-v2`, `_meta.json`) are NOT in this repo — they're machine-specific and would cause merge conflicts. The installer skips them. See [docs/INSTALLATION.md](docs/INSTALLATION.md) for the full rationale.

---

## Roadmap

- [x] Complete `api-design` skill (REST status codes / pagination / auth patterns) — **done 2026-06-23**
- [x] Complete `frontend-patterns` skill (React 19 / Next 15) — **done 2026-06-23**
- [ ] Add `i18n` / `l10n` skill (when Mavis usage expands)
- [ ] Multi-language README (English, 日本語)
- [ ] Add CI to validate `agent.md` doesn't exceed Mavis daemon's 8000-byte `mavis agent new` limit (use `mavis agent update` workaround)

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

---

## License

[MIT](LICENSE) — Copyright (c) 2026 meisijiya

---

## Acknowledgements

- [Karpathy](https://x.com/karpathy) — LLM coding 4-principle constitution
- [ohMeisijiyaCode](https://github.com/meisijiya/ohMeisijiyaCode) — 7-step pipeline + 4-layer review + 11-type metadata single-writer
- [affaan-m/ECC](https://github.com/affaan-m/ECC) — Agent harness OS design
- [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) — 4-principle origin
- [Vibe Coding video (BV1v9ER68EJE)](https://www.bilibili.com) — 5-decoupling practice origin

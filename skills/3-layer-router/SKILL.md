---
name: 3-layer-router
description: NOT APPLICABLE in MiniMax Code runtime — kept as cross-platform reference. Per-agent model tiering (cheap for scout, mid for coder, top for architect/verifier) is for platforms that support per-agent model selection (Claude Code / Cursor / opencode with haiku/sonnet/opus). MiniMax Code uses uniform m3 model across all agents, no tier routing.
---

# 3-Layer Router

**Status: NOT APPLICABLE in MiniMax Code runtime (2026-06-25).**

This skill was on the "5-gap backfill" list (per DESIGN.md §9) but is explicitly N/A in MiniMax Code. Kept as **cross-platform reference** for porting the Mavis team to Claude Code / Cursor / opencode.

## Why N/A here

Per `mavis` MEMORY: **"Mavis 模型选型偏好:统一用 MiniMax-m3"**.

MiniMax Code uses uniform `m3` model across all 16 agents (orchestrator + specialists + fallback). No tier routing. Cost optimization via model tiering does NOT apply.

**Consequence**: there is no agent-specific model tiering in this runtime. "Use haiku for scout, sonnet for coder" advice belongs to non-MiniMax-Code environments.

## Cross-platform patterns (reference only)

For platforms that support per-agent model selection:

| Tier | Model example | Used by | Why |
|------|---------------|---------|-----|
| **Cheap** | haiku (or local 7B) | `scout` (read-only), `code-reader` skill | No judgment; pure file ops |
| **Mid** | sonnet (or m3) | `coder`, `general`, `test-writer` | Code quality + tool use |
| **Top** | opus (or o1) | `architect`, `verifier`, `meta-writer` | Architectural judgment |
| **Variable** | per-task | `mavis` orchestrator | Routes work, mostly cheap; sometimes top for major decisions |

## Decision matrix

| Question | Answer |
|----------|--------|
| MiniMax Code runtime? | Skip this skill — uniform m3 saves context |
| Porting to Claude Code / Cursor? | Implement this skill — significant cost savings (3-5x) |
| Mixed environment (some agents in MiniMax, some in Claude Code)? | Implement per-environment; don't mix tiers within a single plan |

## Why we keep this skill file

Even though N/A here, kept because:
1. DESIGN.md §9 lists it as a "5-gap backfill" — closing the gap structurally (file exists, can be loaded)
2. Future cross-platform port — saves re-deriving the patterns
3. Documentation — explicit record of the "why N/A" decision so future contributors don't re-evaluate

## Related

- `mavis` MEMORY entry: "Mavis 模型选型偏好:统一用 MiniMax-m3 (2026-06-24)"
- DESIGN.md §9 — Future Work list including "Backfill 5 skill gaps"
- [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) — origin of "match model to task complexity" advice
- `delegation-sop` — model-agnostic delegation; tier-routing would be orthogonal

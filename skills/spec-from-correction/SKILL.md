---
name: spec-from-correction
description: Rule-of-three for spec/skill authoring — when the user corrects the same kind of mistake 3 times, formalize it as a spec or skill instead of letting the 4th, 5th, Nth repeat. Use when you notice recurring corrections across sessions. Trigger keywords: rule of three, 重复纠正, 反复修改, 同类问题, 沉淀规则, formalize correction, instinct library, INSTINCTS.
---

# Spec From Correction

Rule-of-three for spec/skill authoring: **when the same kind of mistake gets corrected 3 times, formalize it.** Stop the bleeding by writing it down.

## Why this skill exists

Without a rule, agent behavior drifts. The same correction happens in session N, then session N+10, then session N+50. Each time costs context + tokens + user patience. **The correction IS the spec draft** — capture it before it gets lost.

## The rule (rule-of-three)

```
1st correction: fix the immediate issue, take note
2nd correction: fix the immediate issue, start drafting rule
3rd correction: STOP. Write the rule now (spec or skill).
4th+ correction: rule should already exist. If not, you failed.
```

**Trigger**: notice you've seen the **same shape** of correction across 3+ sessions / PRs / agents.

## What to formalize as spec vs skill

| Pattern observed | Formalize as | Why |
|------------------|--------------|-----|
| User repeatedly says "X should always Y" | **spec** (DECISIONS / KNOWLEDGE) | It's a project rule, not a method |
| Agent repeatedly makes the same kind of mistake | **skill** (method file) | It's a how-to, not a what |
| Same architectural choice gets re-litigated | **ADR** (decision record) | It's a why, with rationale |
| Same instinct fires repeatedly in different contexts | **INSTINCTS** entry | It's a reflex, often informal |

## How to capture (template)

```markdown
## Rule: <one-line summary>

### Trigger
<the pattern that fires this rule — concrete observable>

### Why
<the cost of NOT following this rule>

### Action
<the corrective behavior — concrete actionable>

### Negative example
<what it looks like when you skip the rule>

### Positive example
<what it looks like when you follow it>

### Source
<which 3+ sessions / PRs the rule was extracted from>
```

## Where to file it

- **Project rule** → `docs/KNOWLEDGE/<rule-name>.md` (single-writer: meta-writer)
- **Cross-project reflex** → `~/.mavis/memory/instincts/<name>.md` (user memory)
- **Agent method** → `skills/<name>/SKILL.md` (single-writer: meta-writer or skill-creator)
- **Architectural decision** → `docs/OPTIMIZATION-vN.M-ADR.md` (meta-writer)

## Anti-patterns

- ❌ **Capture after 1st correction** — premature; you don't know if it's a pattern yet
- ❌ **Capture after 2nd correction** — still possibly coincidence; wait
- ❌ **Capture only when "there's time"** — by the time there's time, you've forgotten the 3rd correction
- ❌ **Write a generic rule like "be careful"** — must be concrete + actionable + trigger-specific
- ❌ **Skip filing** — "I'll remember" = you won't. Write it down.

## Field example (2026-06-24)

**Pattern**: user repeatedly corrected agents to not break "agent sync between runtime and repo" by silently mutating the registry.

**3rd trigger**: 2026-06-24 19:34-21:55 silent-drop debugging where 4 agents had to be re-registered.

**Rule extracted**: "Don't pre-emptively split agent.md" (mavis MEMORY entry 2026-06-24).

**Action**: spec-miner / meta-writer MUST check existing memory before any agent.md refactor; if rule already exists, do not re-litigate.

## Related

- `meta-writer` — single-writer for spec / KNOWLEDGE / ADR / INSTINCTS files
- `mvp-vs-long-term` — when to formalize (MVP = don't, long-term = do)
- `spec-vs-harness` — Spec (drawing) vs Harness (test) — which form the rule takes
- `self-hygiene` — long-context Mavis sessions trigger this rule frequently
